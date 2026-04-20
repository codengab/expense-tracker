<!-- src/routes/onboarding/+page.svelte -->
<script>
  import { goto } from '$app/navigation';
  import { workspaceService } from '$lib/services/workspace.service';
  import { workspaces, activeWorkspace, showToast } from '$lib/stores';

  let name    = '';
  let loading = false;
  let error   = '';

  const suggestions = ['Keluarga', 'Rumah Tangga', 'Keuangan Pribadi', 'Bisnis'];

  async function handleCreate() {
    if (!name.trim()) { error = 'Nama workspace wajib diisi'; return; }
    loading = true;
    error   = '';
    try {
      const ws = await workspaceService.create(name.trim());
      const wsObj = typeof ws === 'string' ? JSON.parse(ws) : ws;
      // Append ke daftar workspace yang sudah ada (bukan replace)
      workspaces.update(list => [...list, { ...wsObj, role: 'admin' }]);
      activeWorkspace.set({ ...wsObj, role: 'admin' });
      showToast(`Workspace "${wsObj.name}" berhasil dibuat!`);
      goto('/dashboard');
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head><title>Buat Workspace — Dompet</title></svelte:head>

<div class="ob-page">
  <div class="ob-card">
    <div class="ob-back">
      <a href="/dashboard" class="back-link">← Kembali ke Dashboard</a>
    </div>
    <div style="font-size:44px;margin-bottom:12px;">🏠</div>
    <h1 class="ob-title">Buat Workspace Baru</h1>
    <p class="ob-desc">
      Setiap workspace punya dompet, transaksi, anggaran, dan anggota sendiri.
    </p>

    <div class="form-group" style="width:100%;max-width:340px;">
      <label class="form-label">Nama Workspace *</label>
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
      <div class="err-box">{error}</div>
    {/if}

    <button class="btn btn-primary ob-btn" on:click={handleCreate} disabled={loading}>
      {loading ? 'Membuat...' : 'Buat Workspace →'}
    </button>
  </div>
</div>

<style>
  .ob-page {
    min-height: 100vh; background: var(--bg);
    display: flex; align-items: center; justify-content: center; padding: 24px;
  }
  .ob-card {
    background: white; border: 1px solid var(--border); border-radius: 20px;
    padding: 40px 36px; display: flex; flex-direction: column; align-items: center;
    width: 100%; max-width: 460px; box-shadow: 0 8px 32px rgba(0,0,0,.07); position: relative;
  }
  .ob-back { position: absolute; top: 16px; left: 20px; }
  .back-link { font-size: 12.5px; color: var(--text-3); text-decoration: none; font-weight: 500; }
  .back-link:hover { color: var(--primary); }
  .ob-title { font-size: 20px; font-weight: 700; margin-bottom: 8px; }
  .ob-desc {
    font-size: 13.5px; color: var(--text-3); text-align: center;
    line-height: 1.6; margin-bottom: 24px; max-width: 300px;
  }
  .suggestions {
    display: flex; flex-wrap: wrap; gap: 7px;
    justify-content: center; margin: 10px 0 16px; max-width: 340px;
  }
  .suggestion-pill {
    padding: 4px 12px; background: var(--bg); border: 1px solid var(--border);
    border-radius: 99px; font-size: 12.5px; font-weight: 500; color: var(--text-2);
    cursor: pointer; font-family: inherit; transition: all .15s;
  }
  .suggestion-pill:hover { background: #EFF6FF; border-color: var(--primary); color: var(--primary); }
  .err-box {
    width: 100%; max-width: 340px; padding: 9px 12px;
    background: #FEF2F2; border: 1px solid #FECACA;
    border-radius: 8px; font-size: 13px; color: var(--expense); margin-bottom: 8px;
  }
  .ob-btn { padding: 11px 36px; font-size: 14.5px; margin-top: 4px; }
</style>
