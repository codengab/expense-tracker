// src/lib/services/auth.service.js
import { supabase } from '$lib/supabase';

export const authService = {
  async getUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },

  async getSession() {
    const { data: { session } } = await supabase.auth.getSession();
    return session;
  },

  // Ambil profil user (display name, avatar color)
  async getProfile() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', user.id)
      .single();
    return data;
  },

  // Simpan/update display name & warna avatar
  async upsertProfile(displayName, avatarColor = null) {
    const { data, error } = await supabase.rpc('upsert_user_profile', {
      p_display_name: displayName,
      p_avatar_color: avatarColor
    });
    if (error) throw error;
    return data;
  },

  // Ganti password langsung (saat sudah login)
  async changePassword(newPassword) {
    const { data, error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) throw error;
    return data;
  },

  // Kirim link reset password ke email (berlaku 1 jam)
  async sendPasswordReset(email) {
    const redirectTo = typeof window !== 'undefined'
      ? `${window.location.origin}/auth/reset-password`
      : undefined;
    const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
    if (error) throw error;
  },

  // Kirim ulang email konfirmasi (berlaku 24 jam)
  async resendConfirmation(email) {
    const redirectTo = typeof window !== 'undefined'
      ? `${window.location.origin}/auth/login`
      : undefined;
    const { error } = await supabase.auth.resend({
      type: 'signup',
      email,
      options: { emailRedirectTo: redirectTo }
    });
    if (error) throw error;
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  }
};
