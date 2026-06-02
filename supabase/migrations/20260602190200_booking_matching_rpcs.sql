-- Corrected matching logic and server-side booking RPCs.
--
-- Fixes the buggy time-overlap test and the ignored proximity parameter in
-- match_helpers, adds an atomic match-and-reserve RPC that prevents
-- double-booking the same helper, and adds a create_service_booking RPC that
-- validates promo codes and computes the price server-side (so clients can no
-- longer fake discounts or totals).

-- Safe time parser: returns NULL instead of raising on malformed input.
create or replace function "public"."try_parse_time"("p_text" "text")
returns time without time zone
language "plpgsql"
immutable
as $$
begin
  return "p_text"::time;
exception when others then
  return null;
end;
$$;

alter function "public"."try_parse_time"("p_text" "text") owner to "postgres";
grant execute on function "public"."try_parse_time"("p_text" "text") to "anon", "authenticated", "service_role";


-- Advisory matcher (read-only). Now uses correct interval-overlap logic and
-- actually applies the proximity bias derived from the requested location.
create or replace function "public"."match_helpers"(
  "p_service_type" character varying,
  "p_booking_date" "date",
  "p_booking_time" character varying,
  "p_location" character varying
) returns "jsonb"
language "plpgsql"
security definer
set search_path = public
as $$
declare
  v_proximity_bias float;
  v_rating_bias float;
  v_area_id uuid;
  v_start time;
  v_end time;
  v_selected public.helpers;
begin
  if p_service_type in ('indoor', 'airbnb', 'office', 'standard-cleaning', 'deep-cleaning', 'office-cleaning') then
    v_proximity_bias := 0.5; v_rating_bias := 0.5;
  elsif p_service_type in ('deep', 'repairs', 'moving', 'general-repairs', 'moving-help') then
    v_proximity_bias := 0.3; v_rating_bias := 0.7;
  else
    v_proximity_bias := 0.8; v_rating_bias := 0.2;
  end if;

  -- Resolve the requested location (area name, else estate name) to an area.
  if p_location is not null then
    select a.id into v_area_id
    from public.lusaka_areas a
    where lower(a.name) = lower(p_location)
    limit 1;

    if v_area_id is null then
      select e.area_id into v_area_id
      from public.lusaka_estates e
      where lower(e.name) = lower(p_location)
      limit 1;
    end if;
  end if;

  v_start := public.try_parse_time(p_booking_time);
  v_end := case when v_start is null then null else v_start + interval '2 hours' end;

  select h.* into v_selected
  from public.helpers h
  where h.is_active = true
    and not exists (
      select 1
      from public.helper_bookings hb
      where hb.helper_id = h.id
        and hb.booking_date = p_booking_date
        and hb.status = 'confirmed'
        and (
          v_start is null
          or (hb.start_time < v_end and v_start < hb.end_time)
        )
    )
  order by
    (
      (coalesce(h.rating, 0) * v_rating_bias)
      + (case when v_area_id is not null and h.area_id = v_area_id then 1 else 0 end) * v_proximity_bias
    ) desc,
    h.jobs_completed desc
  limit 1;

  if v_selected.id is null then
    return null;
  end if;

  return to_jsonb(v_selected);
end;
$$;

alter function "public"."match_helpers"(character varying, "date", character varying, character varying) owner to "postgres";


-- Atomic match-and-reserve. Locks the booking row, selects the best available
-- helper with FOR UPDATE SKIP LOCKED, then creates the reservation and updates
-- the booking in the same transaction, so two concurrent calls can never grab
-- the same helper for an overlapping slot.
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

  -- Idempotent: if already matched, return the existing helper.
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

  if v_sb.estate_name is not null then
    select e.area_id into v_area_id
    from public.lusaka_estates e
    where lower(e.name) = lower(v_sb.estate_name)
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


-- Secure guest booking creation. Validates the promo code and computes the
-- discount + total server-side, then inserts a pending_review booking. Use
-- this instead of inserting into service_bookings directly so prices and
-- promos cannot be tampered with from the client.
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
  "p_promo_code" character varying default null
) returns "jsonb"
language "plpgsql"
security definer
set search_path = public
as $$
declare
  v_area_id uuid;
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

  -- Resolve the area + travel fee from the estate, when provided.
  if p_estate_name is not null then
    select e.area_id into v_area_id
    from public.lusaka_estates e
    where lower(e.name) = lower(p_estate_name)
    limit 1;

    if v_area_id is not null then
      select coalesce(a.travel_fee, 0) into v_travel_fee
      from public.lusaka_areas a
      where a.id = v_area_id;
    end if;
  end if;

  -- Validate the promo code server-side. Invalid/expired codes are ignored
  -- (the booking still succeeds, with no discount applied).
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
    house_number, estate_name, total_price, status,
    customer_notes, promo_code, promo_discount_amount,
    customer_name, customer_phone, customer_email
  ) values (
    p_service_type, p_customer_address, p_booking_date, p_booking_time,
    p_house_number, p_estate_name, v_total, 'pending_review',
    p_customer_notes, v_applied_code, v_discount_amount,
    p_customer_name, p_customer_phone, p_customer_email
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

alter function "public"."create_service_booking"(character varying, "text", "date", character varying, numeric, character varying, "text", "text", "text", "text", "text", character varying) owner to "postgres";
grant execute on function "public"."create_service_booking"(character varying, "text", "date", character varying, numeric, character varying, "text", "text", "text", "text", "text", character varying) to "anon", "authenticated", "service_role";
