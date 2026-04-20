// src/lib/services/wallet.service.js
import { supabase } from '$lib/supabase';

export const walletService = {
  async getAll(workspaceId) {
    const { data, error } = await supabase
      .from('wallet_balances')
      .select('*')
      .eq('workspace_id', workspaceId)
      .order('name');
    if (error) throw error;
    return data;
  },

  async getById(id) {
    const { data, error } = await supabase
      .from('wallet_balances')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async create(workspaceId, payload) {
    const { data, error } = await supabase
      .from('wallets')
      .insert({ ...payload, workspace_id: workspaceId })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  // Update termasuk initial_balance (ubah saldo awal)
  async update(id, payload) {
    const { data, error } = await supabase
      .from('wallets')
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async toggleActive(id, isActive) {
    return this.update(id, { is_active: isActive });
  },

  async delete(id) {
    const { error } = await supabase.from('wallets').delete().eq('id', id);
    if (error) throw error;
  },

  async getTotalBalance(workspaceId) {
    const { data, error } = await supabase
      .from('wallet_balances')
      .select('current_balance')
      .eq('workspace_id', workspaceId)
      .eq('is_active', true);
    if (error) throw error;
    return data.reduce((sum, w) => sum + (w.current_balance || 0), 0);
  }
};
