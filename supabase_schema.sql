-- =============================================================================
-- Stardust Finance — Supabase Schema (Production Migration)
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- =============================================================================

-- =============================================================================
-- SECTION 0 — PREREQUISITES
-- We clear existing rows from anonymous usage before adding the NOT NULL
-- constraint to avoid ERROR: 23502 (column contains null values).
TRUNCATE public.expenses;
TRUNCATE public.incomes;
-- =============================================================================

-- ─── SECTION 1: Alter existing tables to add user_id ─────────────────────────

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS user_id UUID
    NOT NULL
    REFERENCES auth.users (id) ON DELETE CASCADE;

ALTER TABLE public.incomes
  ADD COLUMN IF NOT EXISTS user_id UUID
    NOT NULL
    REFERENCES auth.users (id) ON DELETE CASCADE;

-- ─── SECTION 2: Drop old permissive policies and replace with strict ones ─────

-- expenses — drop old policies
DROP POLICY IF EXISTS "Public: select expenses"  ON public.expenses;
DROP POLICY IF EXISTS "Public: insert expenses"  ON public.expenses;
DROP POLICY IF EXISTS "Public: update expenses"  ON public.expenses;
DROP POLICY IF EXISTS "Public: delete expenses"  ON public.expenses;

-- expenses — strict owner-only policies
CREATE POLICY "Users: select own expenses"
  ON public.expenses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users: insert own expenses"
  ON public.expenses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: update own expenses"
  ON public.expenses FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: delete own expenses"
  ON public.expenses FOR DELETE
  USING (auth.uid() = user_id);

-- incomes — drop old policies
DROP POLICY IF EXISTS "Public: select incomes"  ON public.incomes;
DROP POLICY IF EXISTS "Public: insert incomes"  ON public.incomes;
DROP POLICY IF EXISTS "Public: update incomes"  ON public.incomes;
DROP POLICY IF EXISTS "Public: delete incomes"  ON public.incomes;

-- incomes — strict owner-only policies
CREATE POLICY "Users: select own incomes"
  ON public.incomes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users: insert own incomes"
  ON public.incomes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: update own incomes"
  ON public.incomes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: delete own incomes"
  ON public.incomes FOR DELETE
  USING (auth.uid() = user_id);

-- ─── SECTION 3: Create open_positions table ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.open_positions (
  id           TEXT          PRIMARY KEY,
  user_id      UUID          NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  asset_id     TEXT          NOT NULL,
  asset_symbol TEXT          NOT NULL,
  asset_name   TEXT          NOT NULL,
  entry_price  NUMERIC       NOT NULL,
  quantity     NUMERIC       NOT NULL,
  is_long      BOOLEAN       NOT NULL,
  stop_loss    NUMERIC,
  take_profit  NUMERIC,
  opened_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_open_positions_user_id
  ON public.open_positions (user_id);

ALTER TABLE public.open_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users: select own positions"
  ON public.open_positions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users: insert own positions"
  ON public.open_positions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: update own positions"
  ON public.open_positions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: delete own positions"
  ON public.open_positions FOR DELETE
  USING (auth.uid() = user_id);

-- ─── SECTION 4: Create trade_history table ────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trade_history (
  id           TEXT          PRIMARY KEY,
  user_id      UUID          NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  asset_id     TEXT          NOT NULL,
  asset_symbol TEXT          NOT NULL,
  asset_name   TEXT          NOT NULL,
  entry_price  NUMERIC       NOT NULL,
  exit_price   NUMERIC       NOT NULL,
  quantity     NUMERIC       NOT NULL,
  is_long      BOOLEAN       NOT NULL,
  realized_pnl NUMERIC       NOT NULL,
  opened_at    TIMESTAMPTZ   NOT NULL,
  closed_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trade_history_user_id
  ON public.trade_history (user_id);

CREATE INDEX IF NOT EXISTS idx_trade_history_closed_at
  ON public.trade_history (user_id, closed_at DESC);

ALTER TABLE public.trade_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users: select own trade history"
  ON public.trade_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users: insert own trade history"
  ON public.trade_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users: delete own trade history"
  ON public.trade_history FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================================================
-- Quick smoke-test (run after creation to verify the tables exist)
-- =============================================================================
-- SELECT * FROM public.expenses       LIMIT 5;
-- SELECT * FROM public.incomes        LIMIT 5;
-- SELECT * FROM public.open_positions LIMIT 5;
-- SELECT * FROM public.trade_history  LIMIT 5;
