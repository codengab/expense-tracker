-- ============================================================
-- DOMPET APP - Supabase Schema
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- WORKSPACES
-- ============================================================
CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- WORKSPACE MEMBERS
-- ============================================================
CREATE TYPE workspace_role AS ENUM ('admin', 'member', 'viewer');

CREATE TABLE workspace_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  role workspace_role NOT NULL DEFAULT 'member',
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  joined_at TIMESTAMPTZ,
  UNIQUE(workspace_id, email)
);

-- ============================================================
-- WALLETS
-- ============================================================
CREATE TYPE wallet_type AS ENUM ('cash', 'bank', 'e-wallet', 'investment', 'other');

CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type wallet_type NOT NULL DEFAULT 'cash',
  initial_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
  color TEXT DEFAULT '#0EA5E9',
  icon TEXT DEFAULT 'wallet',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CATEGORIES
-- ============================================================
CREATE TYPE category_type AS ENUM ('income', 'expense');

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type category_type NOT NULL,
  icon TEXT DEFAULT 'tag',
  color TEXT DEFAULT '#64748B',
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default categories (global, workspace_id = NULL for system defaults)
INSERT INTO categories (name, type, icon, color, is_default, workspace_id) VALUES
  -- Expense
  ('Makanan & Minuman', 'expense', 'utensils', '#F97316', TRUE, NULL),
  ('Transportasi', 'expense', 'car', '#8B5CF6', TRUE, NULL),
  ('Belanja', 'expense', 'shopping-bag', '#EC4899', TRUE, NULL),
  ('Tagihan & Utilitas', 'expense', 'zap', '#F59E0B', TRUE, NULL),
  ('Kesehatan', 'expense', 'heart', '#EF4444', TRUE, NULL),
  ('Hiburan', 'expense', 'tv', '#06B6D4', TRUE, NULL),
  ('Pendidikan', 'expense', 'book', '#3B82F6', TRUE, NULL),
  ('Investasi', 'expense', 'trending-up', '#10B981', TRUE, NULL),
  ('Lainnya', 'expense', 'more-horizontal', '#94A3B8', TRUE, NULL),
  -- Income
  ('Gaji', 'income', 'briefcase', '#16A34A', TRUE, NULL),
  ('Freelance', 'income', 'laptop', '#0EA5E9', TRUE, NULL),
  ('Bisnis', 'income', 'store', '#7C3AED', TRUE, NULL),
  ('Investasi', 'income', 'trending-up', '#10B981', TRUE, NULL),
  ('Hadiah', 'income', 'gift', '#F59E0B', TRUE, NULL),
  ('Lainnya', 'income', 'more-horizontal', '#94A3B8', TRUE, NULL);

-- ============================================================
-- TRANSACTIONS
-- ============================================================
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  to_wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL, -- for transfers
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  type transaction_type NOT NULL,
  amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  note TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BUDGETS
-- ============================================================
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INT NOT NULL CHECK (year >= 2000),
  amount NUMERIC(15,2) NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(workspace_id, category_id, month, year)
);

-- ============================================================
-- VIEWS
-- ============================================================

-- Wallet current balance view
CREATE OR REPLACE VIEW wallet_balances AS
SELECT
  w.id,
  w.workspace_id,
  w.name,
  w.type,
  w.color,
  w.icon,
  w.is_active,
  w.initial_balance,
  w.initial_balance
    + COALESCE(SUM(CASE
        WHEN t.type = 'income' THEN t.amount
        WHEN t.type = 'transfer' AND t.to_wallet_id = w.id THEN t.amount
        WHEN t.type IN ('expense', 'transfer') AND t.wallet_id = w.id THEN -t.amount
        ELSE 0
      END), 0) AS current_balance
FROM wallets w
LEFT JOIN transactions t ON (t.wallet_id = w.id OR t.to_wallet_id = w.id)
GROUP BY w.id;

-- Monthly summary view
CREATE OR REPLACE VIEW monthly_summary AS
SELECT
  workspace_id,
  EXTRACT(YEAR FROM date)::INT AS year,
  EXTRACT(MONTH FROM date)::INT AS month,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS total_income,
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS total_expense,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) -
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS net
FROM transactions
GROUP BY workspace_id, year, month;

-- Budget usage view
CREATE OR REPLACE VIEW budget_usage AS
SELECT
  b.id,
  b.workspace_id,
  b.category_id,
  c.name AS category_name,
  c.icon AS category_icon,
  c.color AS category_color,
  b.month,
  b.year,
  b.amount AS budget_amount,
  COALESCE(SUM(t.amount), 0) AS used_amount,
  b.amount - COALESCE(SUM(t.amount), 0) AS remaining_amount,
  CASE
    WHEN b.amount > 0 THEN ROUND((COALESCE(SUM(t.amount), 0) / b.amount * 100)::NUMERIC, 1)
    ELSE 0
  END AS usage_percentage
FROM budgets b
JOIN categories c ON c.id = b.category_id
LEFT JOIN transactions t ON
  t.category_id = b.category_id AND
  t.workspace_id = b.workspace_id AND
  t.type = 'expense' AND
  EXTRACT(MONTH FROM t.date) = b.month AND
  EXTRACT(YEAR FROM t.date) = b.year
GROUP BY b.id, b.workspace_id, b.category_id, c.name, c.icon, c.color, b.month, b.year, b.amount;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Helper function: check if user is member of workspace
CREATE OR REPLACE FUNCTION is_workspace_member(ws_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = ws_id
    AND user_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper function: check if user is admin of workspace
CREATE OR REPLACE FUNCTION is_workspace_admin(ws_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = ws_id
    AND user_id = auth.uid()
    AND role = 'admin'
  );
$$ LANGUAGE SQL SECURITY DEFINER;

-- Workspace policies
CREATE POLICY "workspace_select" ON workspaces FOR SELECT USING (is_workspace_member(id));
CREATE POLICY "workspace_insert" ON workspaces FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "workspace_update" ON workspaces FOR UPDATE USING (is_workspace_admin(id));
CREATE POLICY "workspace_delete" ON workspaces FOR DELETE USING (auth.uid() = owner_id);

-- Workspace members policies
CREATE POLICY "members_select" ON workspace_members FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "members_insert" ON workspace_members FOR INSERT WITH CHECK (is_workspace_admin(workspace_id));
CREATE POLICY "members_update" ON workspace_members FOR UPDATE USING (is_workspace_admin(workspace_id));
CREATE POLICY "members_delete" ON workspace_members FOR DELETE USING (is_workspace_admin(workspace_id));

-- Wallets policies
CREATE POLICY "wallets_select" ON wallets FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "wallets_insert" ON wallets FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "wallets_update" ON wallets FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "wallets_delete" ON wallets FOR DELETE USING (is_workspace_admin(workspace_id));

-- Categories policies (global defaults readable by all authenticated)
CREATE POLICY "categories_select" ON categories FOR SELECT USING (
  workspace_id IS NULL OR is_workspace_member(workspace_id)
);
CREATE POLICY "categories_insert" ON categories FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "categories_update" ON categories FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "categories_delete" ON categories FOR DELETE USING (is_workspace_admin(workspace_id));

-- Transactions policies
CREATE POLICY "transactions_select" ON transactions FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "transactions_insert" ON transactions FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "transactions_update" ON transactions FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "transactions_delete" ON transactions FOR DELETE USING (is_workspace_member(workspace_id));

-- Budgets policies
CREATE POLICY "budgets_select" ON budgets FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "budgets_insert" ON budgets FOR INSERT WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "budgets_update" ON budgets FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "budgets_delete" ON budgets FOR DELETE USING (is_workspace_admin(workspace_id));

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Copy budget between months
CREATE OR REPLACE FUNCTION copy_budget(
  p_workspace_id UUID,
  p_from_month INT,
  p_from_year INT,
  p_to_month INT,
  p_to_year INT,
  p_mode TEXT DEFAULT 'replace' -- 'replace' or 'merge'
)
RETURNS INT AS $$
DECLARE
  v_count INT := 0;
BEGIN
  IF p_mode = 'replace' THEN
    -- Delete existing budgets for target month
    DELETE FROM budgets
    WHERE workspace_id = p_workspace_id
      AND month = p_to_month
      AND year = p_to_year;

    -- Insert from source month
    INSERT INTO budgets (workspace_id, category_id, month, year, amount)
    SELECT p_workspace_id, category_id, p_to_month, p_to_year, amount
    FROM budgets
    WHERE workspace_id = p_workspace_id
      AND month = p_from_month
      AND year = p_from_year;

    GET DIAGNOSTICS v_count = ROW_COUNT;

  ELSIF p_mode = 'merge' THEN
    -- Only insert categories that don't exist in target month
    INSERT INTO budgets (workspace_id, category_id, month, year, amount)
    SELECT p_workspace_id, category_id, p_to_month, p_to_year, amount
    FROM budgets src
    WHERE workspace_id = p_workspace_id
      AND month = p_from_month
      AND year = p_from_year
      AND NOT EXISTS (
        SELECT 1 FROM budgets dest
        WHERE dest.workspace_id = p_workspace_id
          AND dest.category_id = src.category_id
          AND dest.month = p_to_month
          AND dest.year = p_to_year
      );

    GET DIAGNOSTICS v_count = ROW_COUNT;
  END IF;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_workspaces_updated_at BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_wallets_updated_at BEFORE UPDATE ON wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_budgets_updated_at BEFORE UPDATE ON budgets FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_transactions_workspace_date ON transactions(workspace_id, date DESC);
CREATE INDEX idx_transactions_workspace_category ON transactions(workspace_id, category_id);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_budgets_workspace_month ON budgets(workspace_id, year, month);
CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);


-- ============================================================
-- FIX: create_workspace function (SECURITY DEFINER)
-- Solves chicken-and-egg RLS problem saat membuat workspace baru.
-- Owner tidak bisa insert ke workspace_members karena belum
-- terdaftar sebagai admin — fungsi ini bypass RLS secara aman.
-- ============================================================
CREATE OR REPLACE FUNCTION create_workspace(p_name TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_user_email TEXT;
  v_workspace_id UUID;
  v_result JSON;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT email INTO v_user_email
  FROM auth.users
  WHERE id = v_user_id;

  -- Insert workspace
  INSERT INTO workspaces (name, owner_id)
  VALUES (p_name, v_user_id)
  RETURNING id INTO v_workspace_id;

  -- Insert owner as admin member (bypasses RLS via SECURITY DEFINER)
  INSERT INTO workspace_members (workspace_id, user_id, email, role, joined_at)
  VALUES (v_workspace_id, v_user_id, v_user_email, 'admin', NOW());

  -- Return workspace data as JSON
  SELECT row_to_json(w) INTO v_result
  FROM workspaces w
  WHERE w.id = v_workspace_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
