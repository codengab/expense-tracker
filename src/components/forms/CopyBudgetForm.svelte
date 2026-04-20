<!-- src/components/forms/CopyBudgetForm.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  import { get } from 'svelte/store';
  import { workspaceId, showToast } from '$lib/stores';
  import { budgetService } from '$lib/services/budget.service';
  import { getMonthOptions, getYearOptions, formatMonthYear } from '$lib/utils/format';

  export let currentMonth;
  export let currentYear;

  const dispatch = createEventDispatcher();
  const months = getMonthOptions();
  const years = getYearOptions();

  let fromMonth = currentMonth;
  let fromYear  = currentYear;
  let toMonth   = currentMonth === 12 ? 1 : currentMonth + 1;
  let toYear    = currentMonth === 12 ? currentYear + 1 : currentYear;
  let mode    = 'replace';
  let loading = false;

  async function handleCopy() {
    if (fromMonth === toMonth && fromYear === toYear) {
      showToast('Bulan sumber dan tujuan tidak boleh sama', 'error');
      return;
    }

    // Gunakan get() — aman di dalam modal/komponen nested
    const wsId = get(workspaceId);
    if (!wsId) { showToast('Workspace tidak valid', 'error'); return; }

    loading = true;
    try {
      const count = await budgetService.copyBudget(
        wsId, fromMonth, fromYear, toMonth, toYear, mode
      );
      showToast(`Berhasil menyalin ${count} anggaran ke ${formatMonthYear(toYear, toMonth)}`);
      dispatch('copied', { toMonth, toYear });
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      loading = false;
    }
  }
</script>

<div class="copy-form">
  <p class="copy-desc">Salin anggaran dari satu bulan ke bulan lainnya.</p>

  <div class="row">
    <div class="field">
      <label class="label">Dari Bulan</label>
      <select class="input" bind:value={fromMonth}>
        {#each months as m}
          <option value={m.value}>{m.label}</option>
        {/each}
      </select>
    </div>
    <div class="field">
      <label class="label">Tahun</label>
      <select class="input" bind:value={fromYear}>
        {#each years as y}
          <option value={y}>{y}</option>
        {/each}
      </select>
    </div>
  </div>

  <div class="arrow">↓</div>

  <div class="row">
    <div class="field">
      <label class="label">Ke Bulan</label>
      <select class="input" bind:value={toMonth}>
        {#each months as m}
          <option value={m.value}>{m.label}</option>
        {/each}
      </select>
    </div>
    <div class="field">
      <label class="label">Tahun</label>
      <select class="input" bind:value={toYear}>
        {#each years as y}
          <option value={y}>{y}</option>
        {/each}
      </select>
    </div>
  </div>

  <div class="mode-section">
    <label class="label">Mode Salin</label>
    <div class="mode-options">
      <label class="mode-option" class:mode-option--selected={mode === 'replace'}>
        <input type="radio" bind:group={mode} value="replace" />
        <div>
          <strong>Timpa</strong>
          <span>Hapus anggaran bulan tujuan, ganti dengan sumber</span>
        </div>
      </label>
      <label class="mode-option" class:mode-option--selected={mode === 'merge'}>
        <input type="radio" bind:group={mode} value="merge" />
        <div>
          <strong>Gabung</strong>
          <span>Hanya tambahkan kategori yang belum ada di tujuan</span>
        </div>
      </label>
    </div>
  </div>

  <button class="btn-copy" on:click={handleCopy} disabled={loading}>
    {loading ? 'Menyalin...' : '🗒️ Salin Anggaran'}
  </button>
</div>

<style>
  .copy-form { display: flex; flex-direction: column; gap: 1rem; }
  .copy-desc { font-size: 0.875rem; color: #64748B; }
  .row { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
  .field { display: flex; flex-direction: column; gap: 0.375rem; }
  .label { font-size: 0.8125rem; font-weight: 500; color: #374151; }
  .input {
    padding: 0.625rem 0.75rem; border: 1px solid #E2E8F0;
    border-radius: 0.625rem; font-size: 0.875rem; color: #0F172A;
    background: white; outline: none;
  }
  .input:focus { border-color: #0EA5E9; }
  .arrow { text-align: center; font-size: 1.5rem; color: #94A3B8; margin: -0.25rem 0; }
  .mode-section { display: flex; flex-direction: column; gap: 0.5rem; }
  .mode-options { display: flex; flex-direction: column; gap: 0.5rem; }
  .mode-option {
    display: flex; align-items: flex-start; gap: 0.625rem;
    padding: 0.75rem; border: 2px solid #E2E8F0;
    border-radius: 0.625rem; cursor: pointer; transition: border-color 0.15s;
  }
  .mode-option input { margin-top: 0.1875rem; accent-color: #0EA5E9; }
  .mode-option--selected { border-color: #0EA5E9; background: #F0F9FF; }
  .mode-option strong { display: block; font-size: 0.875rem; color: #0F172A; }
  .mode-option span { font-size: 0.8125rem; color: #64748B; }
  .btn-copy {
    padding: 0.75rem; background: #0EA5E9; color: white; border: none;
    border-radius: 0.75rem; font-size: 0.9375rem; font-weight: 600;
    cursor: pointer; transition: background 0.15s;
  }
  .btn-copy:hover { background: #0284C7; }
  .btn-copy:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
