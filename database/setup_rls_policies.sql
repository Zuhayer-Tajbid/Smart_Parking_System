-- Smart Parking System — full privilege + RLS setup for booking
-- ---------------------------------------------------------------------------
-- Run this in Supabase -> SQL Editor once. It is safe to run repeatedly.
--
-- Why reservations were "not registering":
--   1. Base table privileges (GRANT) were missing for some roles. A missing
--      GRANT throws code 42501 "permission denied for table ...".
--   2. Even with the GRANT in place, if Row Level Security (RLS) is enabled but
--      there is no INSERT/UPDATE policy, PostgREST silently drops the write and
--      returns an empty result (no error). The app then looks like it "worked"
--      but no row is ever written to `bookings`.
--
-- This script fixes both: it grants the base privileges AND creates the RLS
-- policies that let a logged-in user read/write their own bookings and flip a
-- parking slot between 'available' <-> 'occupied'.
-- ---------------------------------------------------------------------------

-- 1. Base privileges ---------------------------------------------------------
--    Logged-in users (role `authenticated`):
--      - read / create / update their own bookings
--      - read all slots and update a slot's status
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;
GRANT SELECT, UPDATE ON public.parking_slots TO authenticated;

-- Safety net: if any table uses a SERIAL identity column, allow the role to
-- advance the sequence on INSERT. No-op when no sequences exist.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 2. Row Level Security ------------------------------------------------------
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_slots ENABLE ROW LEVEL SECURITY;

-- 3. Policies: bookings ------------------------------------------------------
-- A user can see only their own bookings.
DROP POLICY IF EXISTS "bookings_select_own" ON public.bookings;
CREATE POLICY "bookings_select_own" ON public.bookings
  FOR SELECT
  USING (auth.uid() = user_id);

-- A user can create a booking only for themselves.
DROP POLICY IF EXISTS "bookings_insert_own" ON public.bookings;
CREATE POLICY "bookings_insert_own" ON public.bookings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- A user can update only their own bookings (e.g. cancel).
DROP POLICY IF EXISTS "bookings_update_own" ON public.bookings;
CREATE POLICY "bookings_update_own" ON public.bookings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. Policies: parking_slots --------------------------------------------------
-- Everyone who is logged in can read the slot list.
DROP POLICY IF EXISTS "parking_slots_select" ON public.parking_slots;
CREATE POLICY "parking_slots_select" ON public.parking_slots
  FOR SELECT
  USING (true);

-- Logged-in users can update a slot (mark it available/occupied on book/cancel).
DROP POLICY IF EXISTS "parking_slots_update" ON public.parking_slots;
CREATE POLICY "parking_slots_update" ON public.parking_slots
  FOR UPDATE
  USING (true)
  WITH CHECK (true);
