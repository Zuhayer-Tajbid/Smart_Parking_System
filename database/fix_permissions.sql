-- Smart Parking System — fix missing table privileges
-- ---------------------------------------------------------------------------
-- Symptom (Flutter web console):
--   PostgrestException | message=permission denied for table parking_slots
--   code=42501 | hint=GRANT SELECT ON public.parking_slots TO authenticated;
--
-- Cause:
--   RLS policies control *which rows* a role may see/change, but the role must
--   ALSO hold the base table privilege (GRANT) for the statement to be allowed.
--   The `authenticated` role was missing the base grants on these tables.
--
-- This script is safe to run more than once (GRANT is idempotent).
-- It does NOT disable RLS, does NOT use service_role, and does NOT weaken
-- security — it only restores the standard privileges the app expects.
-- ---------------------------------------------------------------------------

-- 1. Let logged-in users read the list of parking slots (fixes the current error).
GRANT SELECT ON public.parking_slots TO authenticated;

-- 2. Part 3 booking: read/insert their own bookings, and update status on cancel.
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;

-- 3. Part 3 booking: flip a slot between 'available' <-> 'occupied'.
GRANT UPDATE ON public.parking_slots TO authenticated;
