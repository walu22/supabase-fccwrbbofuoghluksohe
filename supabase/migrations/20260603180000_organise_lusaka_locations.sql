-- Properly organise Lusaka locations (areas + estates).
--
-- Problems addressed:
--  * lusaka_areas has RLS enabled but NO read policy, so anon/guest clients
--    (the booking funnel / location picker) get zero areas back.
--  * Weak integrity: estates could exist with no area; travel_fee nullable;
--    no way to curate which areas show or their order.
--  * No clean, single-call way to fetch areas with their estates.

-- 1. Areas: integrity + curation columns -----------------------------------
update "public"."lusaka_areas" set "travel_fee" = 0 where "travel_fee" is null;

alter table "public"."lusaka_areas"
  alter column "travel_fee" set default 0,
  alter column "travel_fee" set not null;

alter table "public"."lusaka_areas"
  add column if not exists "is_active" boolean not null default true,
  add column if not exists "sort_order" integer not null default 0;

-- 2. Estates: every estate must belong to an area --------------------------
-- (No orphan rows exist today; guard anyway so the migration is safe.)
delete from "public"."lusaka_estates" where "area_id" is null;

alter table "public"."lusaka_estates"
  alter column "area_id" set not null;

create index if not exists "idx_lusaka_estates_area" on "public"."lusaka_estates" ("area_id");

-- 3. RLS: let everyone read active areas; admins manage both tables ---------
drop policy if exists "Public can read active areas" on "public"."lusaka_areas";
create policy "Public can read active areas"
  on "public"."lusaka_areas"
  for select
  using ("is_active" = true);

drop policy if exists "Admins manage areas" on "public"."lusaka_areas";
create policy "Admins manage areas"
  on "public"."lusaka_areas"
  for all
  using ("public"."is_admin"())
  with check ("public"."is_admin"());

drop policy if exists "Admins manage estates" on "public"."lusaka_estates";
create policy "Admins manage estates"
  on "public"."lusaka_estates"
  for all
  using ("public"."is_admin"())
  with check ("public"."is_admin"());

-- 4. Single-call read interface for the frontend ---------------------------
-- Returns active areas (ordered) each with their active estates nested, so the
-- location picker can load everything in one request.
create or replace function "public"."get_service_areas"()
returns "jsonb"
language "sql"
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ar.id,
        'name', ar.name,
        'travel_fee', ar.travel_fee,
        'estates', coalesce((
          select jsonb_agg(
            jsonb_build_object('id', e.id, 'name', e.name)
            order by e.name
          )
          from public.lusaka_estates e
          where e.area_id = ar.id and e.is_active = true
        ), '[]'::jsonb)
      )
      order by ar.sort_order, ar.name
    ),
    '[]'::jsonb
  )
  from public.lusaka_areas ar
  where ar.is_active = true;
$$;

alter function "public"."get_service_areas"() owner to "postgres";
grant execute on function "public"."get_service_areas"() to "anon", "authenticated", "service_role";
