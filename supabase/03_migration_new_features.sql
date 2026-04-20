-- ============================================================
-- MIGRATION: New Features
-- 1. Savings Goals (Tabungan Rencana)
-- 2. Allow editing initial_balance on wallets
-- ============================================================

-- ============================================================
-- SAVINGS GOALS
-- ============================================================
CREATE TYPE savings_category AS ENUM (
  'liburan', 'umroh', 'pendidikan', 'pernikahan',
  'rumah', 'kendaraan', 'darurat', 'investasi', 'lainnya'
);

CREATE TABLE savings_goals (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id     UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  category         savings_category NOT NULL DEFAULT 'lainnya',
  target_amount    NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount   NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  target_date      DATE,
  icon             TEXT DEFAULT '🎯',
  color            TEXT DEFAULT '#0EA5E9',
  is_completed     BOOLEAN DEFAULT FALSE,
  notes            TEXT,
  created_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Savings contributions log
CREATE TABLE savings_contributions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id         UUID NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  workspace_id    UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  amount          NUMERIC(15,2) NOT NULL CHECK (amount != 0), -- negative = tarik
  note            TEXT,
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "savings_goals_select" ON savings_goals FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "savings_goals_insert" ON savings_goals FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "savings_goals_update" ON savings_goals FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "savings_goals_delete" ON savings_goals FOR DELETE USING (is_workspace_admin(workspace_id));

CREATE POLICY "savings_contributions_select" ON savings_contributions FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "savings_contributions_insert" ON savings_contributions FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "savings_contributions_delete" ON savings_contributions FOR DELETE USING (is_workspace_member(workspace_id));

-- Indexes
CREATE INDEX idx_savings_goals_workspace ON savings_goals(workspace_id);
CREATE INDEX idx_savings_contributions_goal ON savings_contributions(goal_id);
CREATE INDEX idx_savings_contributions_workspace ON savings_contributions(workspace_id, date DESC);

-- Trigger updated_at
CREATE TRIGGER trg_savings_goals_updated_at
  BEFORE UPDATE ON savings_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- FUNCTION: contribute to savings goal (atomic update)
-- ============================================================
CREATE OR REPLACE FUNCTION contribute_to_savings(
  p_goal_id      UUID,
  p_amount       NUMERIC,
  p_note         TEXT DEFAULT NULL,
  p_date         DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
  v_workspace_id UUID;
  v_new_amount   NUMERIC;
  v_result       JSON;
BEGIN
  -- Get workspace_id and validate
  SELECT workspace_id INTO v_workspace_id
  FROM savings_goals WHERE id = p_goal_id;

  IF v_workspace_id IS NULL THEN
    RAISE EXCEPTION 'Goal tidak ditemukan';
  END IF;

  -- Insert contribution log
  INSERT INTO savings_contributions (goal_id, workspace_id, amount, note, date, created_by)
  VALUES (p_goal_id, v_workspace_id, p_amount, p_note, p_date, auth.uid());

  -- Update current_amount atomically
  UPDATE savings_goals
  SET
    current_amount = GREATEST(0, current_amount + p_amount),
    is_completed   = CASE WHEN (current_amount + p_amount) >= target_amount THEN TRUE ELSE is_completed END,
    updated_at     = NOW()
  WHERE id = p_goal_id
  RETURNING current_amount INTO v_new_amount;

  -- Return updated goal
  SELECT row_to_json(g) INTO v_result
  FROM savings_goals g WHERE g.id = p_goal_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FIX: Allow editing initial_balance on wallets
-- Add policy update that covers initial_balance column
-- (existing policy already covers UPDATE, no change needed in RLS)
-- The walletService.update() will be fixed to include initial_balance
-- ============================================================

-- View: savings goals with progress
CREATE OR REPLACE VIEW savings_goals_progress AS
SELECT
  g.*,
  CASE
    WHEN g.target_amount > 0
    THEN ROUND((g.current_amount / g.target_amount * 100)::NUMERIC, 1)
    ELSE 0
  END AS progress_pct,
  CASE
    WHEN g.target_date IS NOT NULL AND g.target_date > CURRENT_DATE
    THEN (g.target_date - CURRENT_DATE)
    ELSE 0
  END AS days_remaining,
  CASE
    WHEN g.target_date IS NOT NULL AND g.target_date > CURRENT_DATE AND g.target_amount > g.current_amount
    THEN CEIL((g.target_amount - g.current_amount) / NULLIF((g.target_date - CURRENT_DATE), 0) * 30)
    ELSE 0
  END AS monthly_needed
FROM savings_goals g;
