-- Harden row level security for the booking flow.
--
-- The original policies on "service_bookings" used USING (true) for SELECT and
-- UPDATE, which exposed every customer's address/notes to anyone (anon
-- included) and allowed anyone to modify any booking. This migration locks
-- reads/updates/deletes to administrators and limits the public guest flow to
-- inserting non-privileged rows only.

-- Central admin check. Treats the known admin emails or any profile whose role
-- is 'admin' as an administrator. SECURITY DEFINER so it can read profiles
-- regardless of the caller's own RLS.
create or replace function "public"."is_admin"()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    coalesce(
      (auth.jwt() ->> 'email') in ('walukamubita@gmail.com', 'admin@tumahelper.com'),
      false
    )
    or exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    );
$$;

alter function "public"."is_admin"() owner to "postgres";
grant execute on function "public"."is_admin"() to "anon", "authenticated", "service_role";

-- service_bookings: replace the permissive policies.
drop policy if exists "Allow admin read" on "public"."service_bookings";
drop policy if exists "Allow admin update" on "public"."service_bookings";
drop policy if exists "Allow anonymous insertion" on "public"."service_bookings";

create policy "Admins can read service bookings"
  on "public"."service_bookings"
  for select
  using ("public"."is_admin"());

create policy "Admins can update service bookings"
  on "public"."service_bookings"
  for update
  using ("public"."is_admin"())
  with check ("public"."is_admin"());

create policy "Admins can delete service bookings"
  on "public"."service_bookings"
  for delete
  using ("public"."is_admin"());

-- Guests may still create a booking, but cannot pre-assign a helper or set a
-- privileged status. Helper assignment and status transitions happen
-- server-side (see match_and_reserve_helper / admin updates).
create policy "Anyone can create a service booking"
  on "public"."service_bookings"
  for insert
  with check (
    "status" = 'pending_review'
    and "matched_helper_id" is null
    and coalesce("is_notified", false) = false
    and coalesce("promo_discount_amount", 0) >= 0
  );

-- bookings: drop the blanket public-insert policy so that only the scoped
-- "Users can create bookings." policy (customer_id = auth.uid()) applies.
drop policy if exists "Enable insert for everyone" on "public"."bookings";
