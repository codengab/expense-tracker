// src/lib/services/budget.service.js
import { supabase } from '$lib/supabase';

export const budgetService = {
  async getByMonth(workspaceId, year, month) {
    const { data, error } = await supabase
      .from('budget_usage')
      .select('*')
      .eq('workspace_id', workspaceId)
      .eq('year', year)
      .eq('month', month)
      .order('category_name');
    if (error) throw error;
    return data;
  },

  async upsert(workspaceId, categoryId, year, month, amount) {
    const { data, error } = await supabase
      .from('budgets')
      .upsert({
        workspace_id: workspaceId,
        category_id: categoryId,
        year,
        month,
        amount
      }, { onConflict: 'workspace_id,category_id,month,year' })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async delete(id) {
    const { error } = await supabase.from('budgets').delete().eq('id', id);
    if (error) throw error;
  },

  async copyBudget(workspaceId, fromMonth, fromYear, toMonth, toYear, mode = 'replace') {
    const { data, error } = await supabase.rpc('copy_budget', {
      p_workspace_id: workspaceId,
      p_from_month: fromMonth,
      p_from_year: fromYear,
      p_to_month: toMonth,
      p_to_year: toYear,
      p_mode: mode
    });
    if (error) throw error;
    return data; // number of rows copied
  },

  async getTotalBudget(workspaceId, year, month) {
    const { data, error } = await supabase
      .from('budgets')
      .select('amount')
      .eq('workspace_id', workspaceId)
      .eq('year', year)
      .eq('month', month);
    if (error) throw error;
    return data.reduce((sum, b) => sum + b.amount, 0);
  }
};
