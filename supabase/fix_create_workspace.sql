-- ============================================================
-- JALANKAN INI DI SUPABASE SQL EDITOR
-- Fix: workspace creation gagal karena RLS chicken-and-egg
-- ============================================================

CREATE OR REPLACE FUNCTION create_workspace(p_name TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_user_email TEXT;
  v_workspace_id UUID;
  v_result JSON;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT email INTO v_user_email
  FROM auth.users
  WHERE id = v_user_id;

  INSERT INTO workspaces (name, owner_id)
  VALUES (p_name, v_user_id)
  RETURNING id INTO v_workspace_id;

  INSERT INTO workspace_members (workspace_id, user_id, email, role, joined_at)
  VALUES (v_workspace_id, v_user_id, v_user_email, 'admin', NOW());

  SELECT row_to_json(w) INTO v_result
  FROM workspaces w
  WHERE w.id = v_workspace_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
