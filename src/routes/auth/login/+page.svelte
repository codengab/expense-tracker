<!-- src/routes/auth/login/+page.svelte -->
<script>
  import { auth } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { workspaceService } from '$lib/services/workspace.service';
  import { workspaces, loadStoredWorkspace } from '$lib/stores';

  let email = '';
  let password = '';
  let loading = false;
  let error = '';
  let mode = 'login'; // 'login' | 'register'

  async function handleSubmit() {
    if (!email || !password) { error = 'Email dan password wajib diisi'; return; }
    loading = true;
    error = '';

    try {
      if (mode === 'login') {
        await auth.signIn(email, password);
      } else {
        alert("Hubungi admin untuk menambahkan user")
        // await auth.signUp(email, password);
      }

      // Load workspaces after login
      try {
        const list = await workspaceService.getUserWorkspaces();
        workspaces.set(list);
        loadStoredWorkspace(list);

        // New user with no workspace → redirect to onboarding
        if (list.length === 0) {
          goto('/auth/onboarding');
          return;
        }
      } catch {}

      goto('/dashboard');
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Masuk — Dompet App</title>
</svelte:head>

<div class="auth-page">
  <div class="auth-card">
    <!-- Logo -->
    <div class="auth-logo">
      <div class="auth-logo-icon">💰</div>
      <span class="auth-logo-text">Dompet</span>
    </div>

    <h1 class="auth-title">
      {mode === 'login' ? 'Masuk ke Akun' : 'Buat Akun Baru'}
    </h1>
    <p class="auth-sub">
      {mode === 'login'
        ? 'Kelola keuangan pribadi & keluarga dengan mudah.'
        : 'Mulai perjalanan finansial Anda bersama Dompet.'}
    </p>

    <form on:submit|preventDefault={handleSubmit} class="auth-form">
      <div class="form-group">
        <label class="form-label">Email</label>
        <input
          type="email"
          class="form-input"
          placeholder="nama@email.com"
          bind:value={email}
          required
          autocomplete="email"
        />
      </div>

      <div class="form-group">
        <label class="form-label">
          Password
          <!-- {#if mode === 'login'}
            <a href="/auth/forgot" class="forgot-link">Lupa password?</a>
          {/if} -->
        </label>
        <input
          type="password"
          class="form-input"
          placeholder="••••••••"
          bind:value={password}
          required
          autocomplete={mode === 'login' ? 'current-password' : 'new-password'}
        />
      </div>

      {#if error}
        <div class="auth-error">{error}</div>
      {/if}

      <button type="submit" class="btn btn-primary btn-block" disabled={loading}>
        {#if loading}
          <div class="spinner" style="width:16px;height:16px;border-width:2px;border-top-color:white;"></div>
        {/if}
        {loading ? 'Memproses...' : (mode === 'login' ? 'Masuk' : 'Daftar')}
      </button>
    </form>

    <!-- <div class="auth-switch">
      {mode === 'login' ? 'Belum punya akun?' : 'Sudah punya akun?'}
      <button
        class="auth-switch-btn"
        on:click={() => { mode = mode === 'login' ? 'register' : 'login'; error = ''; }}
      >
        {mode === 'login' ? 'Daftar sekarang' : 'Masuk'}
      </button>
    </div> -->
  </div>
</div>

<style>
  .auth-page {
    min-height: 100vh;
    background: var(--bg);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
  }

  .auth-card {
    background: white;
    border: 1px solid var(--border);
    border-radius: 20px;
    padding: 40px;
    width: 100%;
    max-width: 420px;
    box-shadow: 0 8px 32px rgba(0,0,0,.08);
  }

  .auth-logo {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 28px;
  }
  .auth-logo-icon {
    width: 36px; height: 36px;
    background: linear-gradient(135deg, #0EA5E9, #38BDF8);
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-size: 18px;
  }
  .auth-logo-text { font-size: 20px; font-weight: 700; letter-spacing: -.03em; }

  .auth-title { font-size: 22px; font-weight: 700; margin-bottom: 6px; }
  .auth-sub { font-size: 14px; color: var(--text-3); margin-bottom: 28px; }

  .auth-form { display: flex; flex-direction: column; gap: 16px; }

  .form-label {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .forgot-link { font-size: 12px; color: var(--primary); text-decoration: none; font-weight: 500; }
  .forgot-link:hover { text-decoration: underline; }

  .auth-error {
    padding: 10px 12px;
    background: #FEF2F2;
    border: 1px solid #FECACA;
    border-radius: 8px;
    font-size: 13px;
    color: var(--expense);
  }

  .auth-switch {
    text-align: center;
    margin-top: 20px;
    font-size: 13.5px;
    color: var(--text-3);
  }
  .auth-switch-btn {
    background: none; border: none;
    color: var(--primary);
    font-weight: 600;
    font-size: 13.5px;
    cursor: pointer;
    margin-left: 4px;
    font-family: inherit;
  }
  .auth-switch-btn:hover { text-decoration: underline; }
</style>
