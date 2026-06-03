-- Remove the per-area "Standalone house (no estate)" sentinel estates.
--
-- These existed once per area only as a placeholder for "not in a named estate".
-- Now that bookings capture area_id directly (and the clients offer an explicit
-- "no estate" choice — null estate_id in the funnel, a "custom" option on the
-- live site), the sentinel rows are redundant and previously caused ambiguous
-- name-based area resolution. service_bookings/helper_bookings hold no rows that
-- reference them, so deletion is safe.
delete from "public"."lusaka_estates"
where lower(trim("name")) = 'standalone house (no estate)';
