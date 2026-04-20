// src/lib/services/transaction.service.js
import { supabase } from '$lib/supabase';

export const transactionService = {
  async getAll(workspaceId, filters = {}) {
    let query = supabase
      .from('transactions')
      // .select(`
      //   *,
      //   wallet:wallets(id, name, color, icon, type),
      //   to_wallet:wallets!to_wallet_id(id, name, color, icon),
      //   category:categories(id, name, icon, color, type)
      // `)
      .select(`
        *,
        wallet:wallets!transactions_wallet_id_fkey(id, name, color, icon, type),
        to_wallet:wallets!transactions_to_wallet_id_fkey(id, name, color, icon),
        category:categories(id, name, icon, color, type)
      `)
      .eq('workspace_id', workspaceId)
      .order('date', { ascending: false })
      .order('created_at', { ascending: false });

    if (filters.startDate) query = query.gte('date', filters.startDate);
    if (filters.endDate) query = query.lte('date', filters.endDate);
    if (filters.categoryId) query = query.eq('category_id', filters.categoryId);
    if (filters.walletId) query = query.eq('wallet_id', filters.walletId);
    if (filters.type) query = query.eq('type', filters.type);
    if (filters.limit) query = query.limit(filters.limit);

    const { data, error } = await query;
    if (error) throw error;
    return data;
  },

  async getById(id) {
    const { data, error } = await supabase
      .from('transactions')
      // .select(`
      //   *,
      //   wallet:wallets(id, name, color, icon, type),
      //   to_wallet:wallets!to_wallet_id(id, name, color, icon),
      //   category:categories(id, name, icon, color, type)
      // `)
      .select(`
        *,
        wallet:wallets!transactions_wallet_id_fkey(id, name, color, icon, type),
        to_wallet:wallets!transactions_to_wallet_id_fkey(id, name, color, icon),
        category:categories(id, name, icon, color, type)
      `)
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async create(workspaceId, payload) {
    const user = await supabase.auth.getUser();
    const { data, error } = await supabase
      .from('transactions')
      .insert({
        ...payload,
        workspace_id: workspaceId,
        created_by: user.data.user?.id
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, payload) {
    const { data, error } = await supabase
      .from('transactions')
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async delete(id) {
    const { error } = await supabase.from('transactions').delete().eq('id', id);
    if (error) throw error;
  },

  async getMonthlySummary(workspaceId, year, month) {
    const { data, error } = await supabase
      .from('monthly_summary')
      .select('*')
      .eq('workspace_id', workspaceId)
      .eq('year', year)
      .eq('month', month)
      .single();
    if (error && error.code !== 'PGRST116') throw error;
    return data || { total_income: 0, total_expense: 0, net: 0 };
  },

  async getExpenseByCategory(workspaceId, year, month) {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = new Date(year, month, 0).toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('transactions')
      .select(`
        amount,
        category:categories(id, name, icon, color)
      `)
      .eq('workspace_id', workspaceId)
      .eq('type', 'expense')
      .gte('date', startDate)
      .lte('date', endDate);

    if (error) throw error;

    // Group by category
    const grouped = {};
    for (const t of data) {
      const catId = t.category?.id || 'uncategorized';
      if (!grouped[catId]) {
        grouped[catId] = {
          category: t.category || { name: 'Lainnya', icon: 'tag', color: '#94A3B8' },
          total: 0
        };
      }
      grouped[catId].total += t.amount;
    }

    return Object.values(grouped).sort((a, b) => b.total - a.total);
  }
};
