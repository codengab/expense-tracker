<!-- src/routes/auth/onboarding/+page.svelte -->
<script>
  import { goto } from '$app/navigation';
  import { workspaceService } from '$lib/services/workspace.service';
  import { workspaces, activeWorkspace, showToast } from '$lib/stores';

  let name = '';
  let loading = false;
  let error = '';

  const suggestions = ['Keluarga', 'Rumah Tangga', 'Keuangan Pribadi', 'Bisnis'];

  async function handleCreate() {
    if (!name.trim()) { error = 'Nama workspace wajib diisi'; return; }
    loading = true; error = '';

    try {
      const ws = await workspaceService.create(name.trim());
      workspaces.set([{ ...ws, role: 'admin' }]);
      activeWorkspace.set({ ...ws, role: 'admin' });
      showToast(`Workspace "${ws.name}" berhasil dibuat!`);
      goto('/dashboard');
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head><title>Buat Workspace — Dompet</title></svelte:head>

<div class="onboarding-page">
  <div class="onboarding-card">
    <div style="font-size:48px;margin-bottom:16px;">🏠</div>
    <h1 style="font-size:22px;font-weight:700;margin-bottom:8px;">Buat Workspace Pertama</h1>
    <p style="font-size:14px;color:var(--text-3);margin-bottom:28px;max-width:320px;text-align:center;line-height:1.6;">
      Workspace adalah ruang kerja untuk mengelola keuangan Anda dan anggota keluarga.
    </p>

    <div class="form-group" style="width:100%;max-width:360px;">
      <label class="form-label">Nama Workspace</label>
      <input
        type="text"
        class="form-input"
        placeholder="cth. Keluarga Budi"
        bind:value={name}
        on:keydown={e => e.key === 'Enter' && handleCreate()}
      />
    </div>

    <div class="suggestions">
      {#each suggestions as s}
        <button class="suggestion-pill" on:click={() => name = s}>{s}</button>
      {/each}
    </div>

    {#if error}
      <div class="auth-error" style="max-width:360px;width:100%;">{error}</div>
    {/if}

    <button
      class="btn btn-primary"
      style="margin-top:8px;padding:12px 40px;font-size:15px;"
      on:click={handleCreate}
      disabled={loading}
    >
      {loading ? 'Membuat...' : 'Mulai Sekarang →'}
    </button>
  </div>
</div>

<style>
  .onboarding-page {
    min-height: 100vh;
    background: var(--bg);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
  }
  .onboarding-card {
    background: white;
    border: 1px solid var(--border);
    border-radius: 24px;
    padding: 48px 40px;
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
    max-width: 480px;
    box-shadow: 0 8px 32px rgba(0,0,0,.08);
  }
  .suggestions {
    display: flex; flex-wrap: wrap; gap: 8px;
    justify-content: center;
    margin: 12px 0 16px;
    max-width: 360px;
  }
  .suggestion-pill {
    padding: 5px 14px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 99px;
    font-size: 13px;
    font-weight: 500;
    color: var(--text-2);
    cursor: pointer;
    font-family: inherit;
    transition: all .15s;
  }
  .suggestion-pill:hover { background: var(--primary-light); border-color: var(--primary); color: var(--primary); }
</style>
