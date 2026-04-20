// src/lib/services/category.service.js
import { supabase } from '$lib/supabase';

export const categoryService = {
  async getAll(workspaceId) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .or(`workspace_id.eq.${workspaceId},workspace_id.is.null`)
      .order('name');
    if (error) throw error;
    return data;
  },

  async getByType(workspaceId, type) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .or(`workspace_id.eq.${workspaceId},workspace_id.is.null`)
      .eq('type', type)
      .order('name');
    if (error) throw error;
    return data;
  },

  async create(workspaceId, payload) {
    const { data, error } = await supabase
      .from('categories')
      .insert({ ...payload, workspace_id: workspaceId })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, payload) {
    const { data, error } = await supabase
      .from('categories')
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async delete(id) {
    const { error } = await supabase.from('categories').delete().eq('id', id);
    if (error) throw error;
  }
};
