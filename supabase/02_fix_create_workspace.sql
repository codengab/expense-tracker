-- ============================================================
-- JALANKAN INI DI SUPABASE SQL EDITOR
-- Fix: syntax error pada SELECT INTO di PL/pgSQL
-- ============================================================

CREATE OR REPLACE FUNCTION create_workspace(p_name TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id    UUID;
  v_user_email TEXT;
  v_workspace_id UUID;
  v_result     JSON;
BEGIN
  -- Ambil user id dari session
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Ambil email dari auth.users (syntax yang benar untuk PL/pgSQL)
  v_user_email := (
    SELECT email FROM auth.users WHERE id = v_user_id
  );

  -- Buat workspace
  INSERT INTO workspaces (name, owner_id)
  VALUES (p_name, v_user_id)
  RETURNING id INTO v_workspace_id;

  -- Tambah owner sebagai admin (bypass RLS via SECURITY DEFINER)
  INSERT INTO workspace_members (workspace_id, user_id, email, role, joined_at)
  VALUES (v_workspace_id, v_user_id, v_user_email, 'admin', NOW());

  -- Return workspace sebagai JSON
  v_result := (
    SELECT row_to_json(w) FROM workspaces w WHERE w.id = v_workspace_id
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;