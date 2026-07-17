-- Finish the RLS hardening pass for the remaining tables.
--
-- 1. promo_codes: the "Allow anonymous read" policy let anyone enumerate every
--    active discount code. Replace public enumeration with a targeted
--    validate_promo_code() RPC (checks one code at a time) and admin management.
-- 2. referrals / vouchers: replace the WITH CHECK (true) public-insert policies
--    with owner-scoped inserts.
--
-- worker_applications is intentionally left with public insert: anonymous job
-- applications are a legitimate part of that flow.

-- promo_codes ----------------------------------------------------------------
drop policy if exists "Allow anonymous read of promo_codes" on "public"."promo_codes";

-- Admins retain full management of promo codes through the API.
drop policy if exists "Admins can manage promo codes" on "public"."promo_codes";
create policy "Admins can manage promo codes"
  on "public"."promo_codes"
  for all
  using ("public"."is_admin"())
  with check ("public"."is_admin"());

-- Validate a single promo code without exposing the full list. Returns
-- {valid:true, code, discount_percentage} for a live code, else {valid:false}.
create or replace function "public"."validate_promo_code"("p_code" "text")
returns "jsonb"
language "sql"
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'valid', true,
        'code', pc.code,
        'discount_percentage', pc.discount_percentage
      )
      from public.promo_codes pc
      where upper(pc.code) = upper(trim(p_code))
        and pc.is_active = true
        and (pc.valid_until is null or pc.valid_until > now())
      limit 1
    ),
    jsonb_build_object('valid', false)
  );
$$;

alter function "public"."validate_promo_code"("p_code" "text") owner to "postgres";
grant execute on function "public"."validate_promo_code"("p_code" "text") to "anon", "authenticated", "service_role";

-- referrals ------------------------------------------------------------------
drop policy if exists "Enable insert for everyone" on "public"."referrals";
create policy "Users can create their own referral"
  on "public"."referrals"
  for insert
  to "authenticated"
  with check ("referrer_id" = "auth"."uid"());

-- vouchers -------------------------------------------------------------------
drop policy if exists "Enable insert for everyone" on "public"."vouchers";
create policy "Users can create their own voucher"
  on "public"."vouchers"
  for insert
  to "authenticated"
  with check ("purchaser_id" = "auth"."uid"());
