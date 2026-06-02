-- Schema integrity improvements for the booking flow.
--
-- Adds missing customer contact details to guest bookings, links helper
-- reservations back to their originating booking, enables proximity-aware
-- matching, constrains free-form status columns, and adds supporting indexes.

-- Capture customer contact for guest service bookings (previously there was no
-- way to reach the customer to confirm a booking).
alter table "public"."service_bookings"
  add column if not exists "customer_name" "text",
  add column if not exists "customer_phone" "text",
  add column if not exists "customer_email" "text";

-- Link a helper reservation back to the service booking that created it.
alter table "public"."helper_bookings"
  add column if not exists "service_booking_id" "uuid";

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'helper_bookings_service_booking_id_fkey'
  ) then
    alter table "public"."helper_bookings"
      add constraint "helper_bookings_service_booking_id_fkey"
      foreign key ("service_booking_id")
      references "public"."service_bookings"("id")
      on delete set null;
  end if;
end$$;

-- Optional home service area for helpers, enabling proximity-aware matching.
alter table "public"."helpers"
  add column if not exists "area_id" "uuid";

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'helpers_area_id_fkey'
  ) then
    alter table "public"."helpers"
      add constraint "helpers_area_id_fkey"
      foreign key ("area_id")
      references "public"."lusaka_areas"("id")
      on delete set null;
  end if;
end$$;

-- Constrain free-form status columns. Added NOT VALID so any pre-existing rows
-- are left untouched; new/updated rows must use the allowed values.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'service_bookings_status_check') then
    alter table "public"."service_bookings"
      add constraint "service_bookings_status_check"
      check ("status" in ('pending_review', 'confirmed', 'in-progress', 'completed', 'cancelled'))
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'helper_bookings_status_check') then
    alter table "public"."helper_bookings"
      add constraint "helper_bookings_status_check"
      check ("status" in ('confirmed', 'cancelled', 'completed'))
      not valid;
  end if;
end$$;

-- Indexes supporting the matching query and admin dashboards.
create index if not exists "idx_helpers_is_active" on "public"."helpers" ("is_active");
create index if not exists "idx_helper_bookings_helper_date" on "public"."helper_bookings" ("helper_id", "booking_date");
create index if not exists "idx_helper_bookings_service_booking" on "public"."helper_bookings" ("service_booking_id");
create index if not exists "idx_service_bookings_status" on "public"."service_bookings" ("status");
create index if not exists "idx_service_bookings_date" on "public"."service_bookings" ("booking_date");
create index if not exists "idx_service_bookings_matched_helper" on "public"."service_bookings" ("matched_helper_id");
create index if not exists "idx_bookings_customer" on "public"."bookings" ("customer_id");
create index if not exists "idx_bookings_provider" on "public"."bookings" ("provider_id");
create index if not exists "idx_bookings_helper" on "public"."bookings" ("helper_id");
create index if not exists "idx_bookings_status" on "public"."bookings" ("status");
