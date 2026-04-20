// src/lib/services/savings.service.js
import { supabase } from '$lib/supabase';

export const savingsService = {
  async getAll(workspaceId) {
    const { data, error } = await supabase
      .from('savings_goals_progress')
      .select('*')
      .eq('workspace_id', workspaceId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getById(id) {
    const { data, error } = await supabase
      .from('savings_goals_progress')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async create(workspaceId, payload) {
    const { data: { user } } = await supabase.auth.getUser();
    const { data, error } = await supabase
      .from('savings_goals')
      .insert({ ...payload, workspace_id: workspaceId, created_by: user?.id })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, payload) {
    const { data, error } = await supabase
      .from('savings_goals')
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async delete(id) {
    const { error } = await supabase.from('savings_goals').delete().eq('id', id);
    if (error) throw error;
  },

  // Setor atau tarik dana dari tabungan rencana
  async contribute(goalId, amount, note = null, date = null) {
    const { data, error } = await supabase.rpc('contribute_to_savings', {
      p_goal_id: goalId,
      p_amount:  amount,
      p_note:    note,
      p_date:    date || new Date().toISOString().split('T')[0]
    });
    if (error) throw error;
    return data;
  },

  async getContributions(goalId) {
    const { data, error } = await supabase
      .from('savings_contributions')
      .select('*')
      .eq('goal_id', goalId)
      .order('date', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getTotalSaved(workspaceId) {
    const { data, error } = await supabase
      .from('savings_goals')
      .select('current_amount')
      .eq('workspace_id', workspaceId)
      .eq('is_completed', false);
    if (error) throw error;
    return data.reduce((s, g) => s + (g.current_amount || 0), 0);
  }
};
