-- =============================================================================
-- Stardust App — Supabase Schema
-- Run these commands in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- =============================================================================

-- ─── expenses table ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.expenses (
  id          TEXT          PRIMARY KEY,
  amount      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  category    TEXT          NOT NULL,
  is_want     BOOLEAN       NOT NULL DEFAULT false,
  timestamp   TIMESTAMPTZ   NOT NULL DEFAULT now(),
  is_synced   BOOLEAN       NOT NULL DEFAULT false
);

-- Index for fast date-range queries used by the Logistics Bay charts
CREATE INDEX IF NOT EXISTS idx_expenses_timestamp
  ON public.expenses (timestamp DESC);

-- ─── incomes table ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.incomes (
  id          TEXT          PRIMARY KEY,
  amount      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  category    TEXT          NOT NULL,
  timestamp   TIMESTAMPTZ   NOT NULL DEFAULT now(),
  is_synced   BOOLEAN       NOT NULL DEFAULT false
);

-- Index for fast date-range queries
CREATE INDEX IF NOT EXISTS idx_incomes_timestamp
  ON public.incomes (timestamp DESC);

-- =============================================================================
-- Row Level Security (RLS)
-- =============================================================================

-- Enable RLS on both tables
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incomes  ENABLE ROW LEVEL SECURITY;

-- ─── Public test policies (allow all operations for development) ──────────────
-- CAUTION: These are permissive policies for testing only.
-- Before going to production, replace with user-scoped policies
-- (e.g., `auth.uid() = user_id`) and remove the public INSERT/DELETE policies.

-- expenses: allow all authenticated AND anonymous clients to read/write
CREATE POLICY "Public: select expenses"
  ON public.expenses FOR SELECT
  USING (true);

CREATE POLICY "Public: insert expenses"
  ON public.expenses FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Public: update expenses"
  ON public.expenses FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public: delete expenses"
  ON public.expenses FOR DELETE
  USING (true);

-- incomes: same permissive policies
CREATE POLICY "Public: select incomes"
  ON public.incomes FOR SELECT
  USING (true);

CREATE POLICY "Public: insert incomes"
  ON public.incomes FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Public: update incomes"
  ON public.incomes FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public: delete incomes"
  ON public.incomes FOR DELETE
  USING (true);

-- =============================================================================
-- Quick smoke-test (run after creation to verify the tables exist)
-- =============================================================================
-- SELECT * FROM public.expenses LIMIT 5;
-- SELECT * FROM public.incomes  LIMIT 5;
