-- ============================================================
-- FIX ALL RLS v2
-- Urutan benar: drop policies → drop functions → recreate all
-- JANGAN pakai CASCADE (bisa hapus tabel)
-- ============================================================

-- ── Step 1: Drop semua policies yang depend pada functions ──

DROP POLICY IF EXISTS "workspace_select"  ON workspaces;
DROP POLICY IF EXISTS "workspace_insert"  ON workspaces;
DROP POLICY IF EXISTS "workspace_update"  ON workspaces;
DROP POLICY IF EXISTS "workspace_delete"  ON workspaces;

DROP POLICY IF EXISTS "members_select"    ON workspace_members;
DROP POLICY IF EXISTS "members_insert"    ON workspace_members;
DROP POLICY IF EXISTS "members_update"    ON workspace_members;
DROP POLICY IF EXISTS "members_delete"    ON workspace_members;

DROP POLICY IF EXISTS "wallets_select"    ON wallets;
DROP POLICY IF EXISTS "wallets_insert"    ON wallets;
DROP POLICY IF EXISTS "wallets_update"    ON wallets;
DROP POLICY IF EXISTS "wallets_delete"    ON wallets;

DROP POLICY IF EXISTS "categories_select" ON categories;
DROP POLICY IF EXISTS "categories_insert" ON categories;
DROP POLICY IF EXISTS "categories_update" ON categories;
DROP POLICY IF EXISTS "categories_delete" ON categories;

DROP POLICY IF EXISTS "transactions_select" ON transactions;
DROP POLICY IF EXISTS "transactions_insert" ON transactions;
DROP POLICY IF EXISTS "transactions_update" ON transactions;
DROP POLICY IF EXISTS "transactions_delete" ON transactions;

DROP POLICY IF EXISTS "budgets_select"    ON budgets;
DROP POLICY IF EXISTS "budgets_insert"    ON budgets;
DROP POLICY IF EXISTS "budgets_update"    ON budgets;
DROP POLICY IF EXISTS "budgets_delete"    ON budgets;

-- savings (dari migration_new_features.sql, skip jika belum ada)
DROP POLICY IF EXISTS "savings_goals_select"            ON savings_goals;
DROP POLICY IF EXISTS "savings_goals_insert"            ON savings_goals;
DROP POLICY IF EXISTS "savings_goals_update"            ON savings_goals;
DROP POLICY IF EXISTS "savings_goals_delete"            ON savings_goals;
DROP POLICY IF EXISTS "savings_contributions_select"    ON savings_contributions;
DROP POLICY IF EXISTS "savings_contributions_insert"    ON savings_contributions;
DROP POLICY IF EXISTS "savings_contributions_delete"    ON savings_contributions;

-- ── Step 2: Sekarang aman drop functions ──

DROP FUNCTION IF EXISTS is_workspace_member(UUID);
DROP FUNCTION IF EXISTS is_workspace_admin(UUID);

-- ── Step 3: Recreate functions sebagai SECURITY DEFINER ──
-- SECURITY DEFINER = fungsi berjalan dengan hak postgres,
-- bukan hak user → tidak kena RLS saat query workspace_members

CREATE OR REPLACE FUNCTION is_workspace_member(ws_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = ws_id
      AND user_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_workspace_admin(ws_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = ws_id
      AND user_id = auth.uid()
      AND role = 'admin'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── Step 4: Recreate semua policies ──

-- workspaces
CREATE POLICY "workspace_select" ON workspaces
  FOR SELECT USING (is_workspace_member(id));
CREATE POLICY "workspace_insert" ON workspaces
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "workspace_update" ON workspaces
  FOR UPDATE USING (is_workspace_admin(id));
CREATE POLICY "workspace_delete" ON workspaces
  FOR DELETE USING (auth.uid() = owner_id);

-- workspace_members
CREATE POLICY "members_select" ON workspace_members
  FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "members_insert" ON workspace_members
  FOR INSERT TO authenticated WITH CHECK (is_workspace_admin(workspace_id));
CREATE POLICY "members_update" ON workspace_members
  FOR UPDATE USING (is_workspace_admin(workspace_id));
CREATE POLICY "members_delete" ON workspace_members
  FOR DELETE USING (is_workspace_admin(workspace_id));

-- wallets
CREATE POLICY "wallets_select" ON wallets
  FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "wallets_insert" ON wallets
  FOR INSERT TO authenticated WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "wallets_update" ON wallets
  FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "wallets_delete" ON wallets
  FOR DELETE USING (is_workspace_admin(workspace_id));

-- categories
CREATE POLICY "categories_select" ON categories
  FOR SELECT USING (workspace_id IS NULL OR is_workspace_member(workspace_id));
CREATE POLICY "categories_insert" ON categories
  FOR INSERT TO authenticated WITH CHECK (workspace_id IS NOT NULL AND is_workspace_member(workspace_id));
CREATE POLICY "categories_update" ON categories
  FOR UPDATE USING (workspace_id IS NOT NULL AND is_workspace_member(workspace_id));
CREATE POLICY "categories_delete" ON categories
  FOR DELETE USING (workspace_id IS NOT NULL AND is_workspace_admin(workspace_id));

-- transactions
CREATE POLICY "transactions_select" ON transactions
  FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "transactions_insert" ON transactions
  FOR INSERT TO authenticated WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "transactions_update" ON transactions
  FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "transactions_delete" ON transactions
  FOR DELETE USING (is_workspace_member(workspace_id));

-- budgets
CREATE POLICY "budgets_select" ON budgets
  FOR SELECT USING (is_workspace_member(workspace_id));
CREATE POLICY "budgets_insert" ON budgets
  FOR INSERT TO authenticated WITH CHECK (is_workspace_member(workspace_id));
CREATE POLICY "budgets_update" ON budgets
  FOR UPDATE USING (is_workspace_member(workspace_id));
CREATE POLICY "budgets_delete" ON budgets
  FOR DELETE USING (is_workspace_admin(workspace_id));

-- savings_goals (skip jika tabel belum ada)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'savings_goals') THEN
    EXECUTE 'CREATE POLICY "savings_goals_select" ON savings_goals FOR SELECT USING (is_workspace_member(workspace_id))';
    EXECUTE 'CREATE POLICY "savings_goals_insert" ON savings_goals FOR INSERT TO authenticated WITH CHECK (is_workspace_member(workspace_id))';
    EXECUTE 'CREATE POLICY "savings_goals_update" ON savings_goals FOR UPDATE USING (is_workspace_member(workspace_id))';
    EXECUTE 'CREATE POLICY "savings_goals_delete" ON savings_goals FOR DELETE USING (is_workspace_admin(workspace_id))';
  END IF;
END $$;

-- savings_contributions (skip jika tabel belum ada)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'savings_contributions') THEN
    EXECUTE 'CREATE POLICY "savings_contributions_select" ON savings_contributions FOR SELECT USING (is_workspace_member(workspace_id))';
    EXECUTE 'CREATE POLICY "savings_contributions_insert" ON savings_contributions FOR INSERT TO authenticated WITH CHECK (is_workspace_member(workspace_id))';
    EXECUTE 'CREATE POLICY "savings_contributions_delete" ON savings_contributions FOR DELETE USING (is_workspace_member(workspace_id))';
  END IF;
END $$;

-- ── Step 5: Recreate create_workspace function ──

CREATE OR REPLACE FUNCTION create_workspace(p_name TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id      UUID;
  v_user_email   TEXT;
  v_workspace_id UUID;
  v_result       JSON;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_user_email := (SELECT email FROM auth.users WHERE id = v_user_id);

  INSERT INTO workspaces (name, owner_id)
  VALUES (p_name, v_user_id)
  RETURNING id INTO v_workspace_id;

  INSERT INTO workspace_members (workspace_id, user_id, email, role, joined_at)
  VALUES (v_workspace_id, v_user_id, v_user_email, 'admin', NOW());

  v_result := (SELECT row_to_json(w) FROM workspaces w WHERE w.id = v_workspace_id);
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Step 6: user_profiles table (display name) ──

CREATE TABLE IF NOT EXISTS user_profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_color TEXT DEFAULT '#0EA5E9',
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select" ON user_profiles;
DROP POLICY IF EXISTS "profiles_insert" ON user_profiles;
DROP POLICY IF EXISTS "profiles_update" ON user_profiles;

CREATE POLICY "profiles_select" ON user_profiles
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON user_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE OR REPLACE FUNCTION upsert_user_profile(
  p_display_name TEXT,
  p_avatar_color TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE v_result JSON;
BEGIN
  INSERT INTO user_profiles (id, display_name, avatar_color, updated_at)
  VALUES (auth.uid(), p_display_name, COALESCE(p_avatar_color, '#0EA5E9'), NOW())
  ON CONFLICT (id) DO UPDATE
    SET display_name = EXCLUDED.display_name,
        avatar_color = COALESCE(EXCLUDED.avatar_color, user_profiles.avatar_color),
        updated_at   = NOW();

  SELECT row_to_json(p) INTO v_result FROM user_profiles p WHERE p.id = auth.uid();
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;