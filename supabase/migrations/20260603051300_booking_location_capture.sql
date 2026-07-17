-- Capture the selected location on the booking instead of re-deriving it from
-- a free-form estate name.
--
-- Problem: service_bookings only stored estate_name (text). The price and the
-- matcher re-derived the area via `lower(name) = ... LIMIT 1` against
-- lusaka_estates, whose name has no unique constraint. The sentinel estate
-- "Standalone house (no estate)" exists once per area (6 areas, travel fees
-- 0..30), so a standalone-house customer got an arbitrary travel fee and was
-- matched against the wrong area.
--
-- Fix: persist area_id (and estate_id) on the booking, resolve travel fee +
-- proximity from area_id directly, fall back to a deterministic estate-name
-- lookup only when no id is supplied. Keep the sentinel estate rows (the UI
-- lists them) but add a per-area uniqueness index for integrity.

-- 1. Persist the location selection ------------------------------------------
alter table "public"."service_bookings"
  add column if not exists "area_id" "uuid",
  add column if not exists "estate_id" "uuid";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'service_bookings_area_id_fkey') then
    alter table "public"."service_bookings"
      add constraint "service_bookings_area_id_fkey"
      foreign key ("area_id") references "public"."lusaka_areas"("id") on delete set null;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'service_bookings_estate_id_fkey') then
    alter table "public"."service_bookings"
      add constraint "service_bookings_estate_id_fkey"
      foreign key ("estate_id") references "public"."lusaka_estates"("id") on delete set null;
  end if;
end$$;

create index if not exists "idx_service_bookings_area" on "public"."service_bookings" ("area_id");

-- 2. Estate name must be unique within an area (the sentinel lives in many
--    areas, which is fine; duplicates within one area are not).
create unique index if not exists "idx_lusaka_estates_name_per_area"
  on "public"."lusaka_estates" (lower("name"), "area_id");

-- 3. create_service_booking: accept and prefer area_id / estate_id -----------
drop function if exists "public"."create_service_booking"(
  character varying, "text", "date", character varying, numeric, character varying,
  "text", "text", "text", "text", "text", character varying
);

create or replace function "public"."create_service_booking"(
  "p_service_type" character varying,
  "p_customer_address" "text",
  "p_booking_date" "date",
  "p_booking_time" character varying,
  "p_base_price" numeric default 0,
  "p_house_number" character varying default null,
  "p_estate_name" "text" default null,
  "p_customer_name" "text" default null,
  "p_customer_phone" "text" default null,
  "p_customer_email" "text" default null,
  "p_customer_notes" "text" default null,
  "p_promo_code" character varying default null,
  "p_area_id" "uuid" default null,
  "p_estate_id" "uuid" default null
) returns "jsonb"
language "plpgsql"
security definer
set search_path = public
as $$
declare
  v_area_id uuid;
  v_estate_name text;
  v_travel_fee numeric := 0;
  v_discount_pct integer := 0;
  v_discount_amount numeric := 0;
  v_applied_code varchar := null;
  v_total numeric;
  v_row public.service_bookings;
begin
  if p_base_price is null or p_base_price < 0 then
    raise exception 'Base price must be zero or greater';
  end if;

  -- Resolve the area, preferring explicit ids over the free-form estate name.
  if p_area_id is not null then
    v_area_id := p_area_id;
  elsif p_estate_id is not null then
    select e.area_id into v_area_id from public.lusaka_estates e where e.id = p_estate_id;
  elsif p_estate_name is not null then
    select e.area_id into v_area_id
    from public.lusaka_estates e
    where lower(e.name) = lower(p_estate_name)
    order by e.created_at, e.id  -- deterministic tie-break
    limit 1;
  end if;

  if v_area_id is not null then
    select coalesce(a.travel_fee, 0) into v_travel_fee
    from public.lusaka_areas a
    where a.id = v_area_id;
  end if;

  -- Prefer an explicit estate name; otherwise derive it from estate_id.
  if p_estate_name is not null then
    v_estate_name := p_estate_name;
  elsif p_estate_id is not null then
    select e.name into v_estate_name from public.lusaka_estates e where e.id = p_estate_id;
  end if;

  -- Validate the promo code server-side; invalid/expired codes are ignored.
  if p_promo_code is not null and length(trim(p_promo_code)) > 0 then
    select pc.discount_percentage into v_discount_pct
    from public.promo_codes pc
    where upper(pc.code) = upper(trim(p_promo_code))
      and pc.is_active = true
      and (pc.valid_until is null or pc.valid_until > now())
    limit 1;

    if v_discount_pct is null then
      v_discount_pct := 0;
    else
      v_applied_code := upper(trim(p_promo_code));
    end if;
  end if;

  v_discount_amount := round(p_base_price * v_discount_pct / 100.0, 2);
  v_total := round(p_base_price + coalesce(v_travel_fee, 0) - v_discount_amount, 2);
  if v_total < 0 then
    v_total := 0;
  end if;

  insert into public.service_bookings (
    service_type, customer_address, booking_date, booking_time,
    house_number, estate_name, area_id, estate_id, total_price, status,
    customer_notes, promo_code, promo_discount_amount,
    customer_name, customer_phone, customer_email
  ) values (
    p_service_type, p_customer_address, p_booking_date, p_booking_time,
    p_house_number, v_estate_name, v_area_id, p_estate_id, v_total, 'pending_review',
    p_customer_notes, v_applied_code, v_discount_amount,
    p_customer_name, p_customer_phone, p_customer_email
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

alter function "public"."create_service_booking"(character varying, "text", "date", character varying, numeric, character varying, "text", "text", "text", "text", "text", character varying, "uuid", "uuid") owner to "postgres";
grant execute on function "public"."create_service_booking"(character varying, "text", "date", character varying, numeric, character varying, "text", "text", "text", "text", "text", character varying, "uuid", "uuid") to "anon", "authenticated", "service_role";

-- 4. match_and_reserve_helper: use the stored area_id ------------------------
create or replace function "public"."match_and_reserve_helper"("p_service_booking_id" "uuid")
returns "jsonb"
language "plpgsql"
security definer
set search_path = public
as $$
declare
  v_sb public.service_bookings;
  v_proximity_bias float;
  v_rating_bias float;
  v_area_id uuid;
  v_start time;
  v_end time;
  v_selected public.helpers;
begin
  select * into v_sb from public.service_bookings where id = p_service_booking_id for update;
  if not found then
    raise exception 'Service booking % not found', p_service_booking_id;
  end if;

  if v_sb.matched_helper_id is not null then
    select * into v_selected from public.helpers where id = v_sb.matched_helper_id;
    return to_jsonb(v_selected);
  end if;

  if v_sb.service_type in ('indoor', 'airbnb', 'office', 'standard-cleaning', 'deep-cleaning', 'office-cleaning') then
    v_proximity_bias := 0.5; v_rating_bias := 0.5;
  elsif v_sb.service_type in ('deep', 'repairs', 'moving', 'general-repairs', 'moving-help') then
    v_proximity_bias := 0.3; v_rating_bias := 0.7;
  else
    v_proximity_bias := 0.8; v_rating_bias := 0.2;
  end if;

  -- Prefer the area stored on the booking; fall back to estate id, then to a
  -- deterministic estate-name lookup.
  v_area_id := v_sb.area_id;
  if v_area_id is null and v_sb.estate_id is not null then
    select e.area_id into v_area_id from public.lusaka_estates e where e.id = v_sb.estate_id;
  end if;
  if v_area_id is null and v_sb.estate_name is not null then
    select e.area_id into v_area_id
    from public.lusaka_estates e
    where lower(e.name) = lower(v_sb.estate_name)
    order by e.created_at, e.id
    limit 1;
  end if;

  v_start := public.try_parse_time(v_sb.booking_time);
  if v_start is null then
    raise exception 'Booking time "%" is not a valid time value', v_sb.booking_time;
  end if;
  v_end := v_start + interval '2 hours';

  select h.* into v_selected
  from public.helpers h
  where h.is_active = true
    and not exists (
      select 1
      from public.helper_bookings hb
      where hb.helper_id = h.id
        and hb.booking_date = v_sb.booking_date
        and hb.status = 'confirmed'
        and hb.start_time < v_end
        and v_start < hb.end_time
    )
  order by
    (
      (coalesce(h.rating, 0) * v_rating_bias)
      + (case when v_area_id is not null and h.area_id = v_area_id then 1 else 0 end) * v_proximity_bias
    ) desc,
    h.jobs_completed desc
  limit 1
  for update of h skip locked;

  if v_selected.id is null then
    return null;
  end if;

  insert into public.helper_bookings (helper_id, booking_date, start_time, end_time, status, service_booking_id)
  values (v_selected.id, v_sb.booking_date, v_start, v_end, 'confirmed', v_sb.id);

  update public.service_bookings
  set matched_helper_id = v_selected.id,
      status = 'confirmed'
  where id = v_sb.id;

  return to_jsonb(v_selected);
end;
$$;

alter function "public"."match_and_reserve_helper"("uuid") owner to "postgres";
grant execute on function "public"."match_and_reserve_helper"("uuid") to "authenticated", "service_role";
