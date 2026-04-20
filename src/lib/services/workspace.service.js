// src/lib/services/workspace.service.js
import { supabase } from '$lib/supabase';

export const workspaceService = {
  async getUserWorkspaces() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('workspace_members')
      .select(`
        role,
        workspace:workspaces(*)
      `)
      .eq('user_id', user.id);
    if (error) throw error;
    return data.map(m => ({ ...m.workspace, role: m.role }));
  },

  async create(name) {
    // Gunakan RPC function SECURITY DEFINER untuk menghindari
    // masalah RLS chicken-and-egg saat insert workspace_members.
    // Owner belum terdaftar sebagai admin saat insert pertama.
    const { data, error } = await supabase.rpc('create_workspace', {
      p_name: name
    });
    if (error) throw error;
    return data; // returns workspace object as JSON
  },

  async getMembers(workspaceId) {
    const { data, error } = await supabase
      .from('workspace_members')
      .select('*')
      .eq('workspace_id', workspaceId)
      .order('joined_at');
    if (error) throw error;
    return data;
  },

  async inviteMember(workspaceId, email, role = 'member') {
    const { data, error } = await supabase
      .from('workspace_members')
      .insert({ workspace_id: workspaceId, email, role })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async updateMemberRole(memberId, role) {
    const { data, error } = await supabase
      .from('workspace_members')
      .update({ role })
      .eq('id', memberId)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async removeMember(memberId) {
    const { error } = await supabase.from('workspace_members').delete().eq('id', memberId);
    if (error) throw error;
  }
};
