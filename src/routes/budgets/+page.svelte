<!-- src/routes/budgets/+page.svelte -->
<script>
  import { get } from 'svelte/store';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';
  import { workspaceId, showToast } from '$lib/stores';
  import { budgetService } from '$lib/services/budget.service';
  import { categoryService } from '$lib/services/category.service';
  import { formatCurrencyShort, formatCurrency, formatMonthYear, getCurrentMonthYear, getMonthOptions, getYearOptions } from '$lib/utils/format';
  import Modal from '../../components/ui/Modal.svelte';
  import CopyBudgetForm from '../../components/forms/CopyBudgetForm.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';

  const now = getCurrentMonthYear();
  let month = now.month;
  let year = now.year;

  const months = getMonthOptions();
  const years = getYearOptions();

  let budgetItems = [];
  let categories = [];
  let loading = false;
  let showCopyModal = false;
  let showAddModal = false;
  let editingBudget = null;

  // Add/edit form
  let formCategoryId = '';
  let formAmount = '';
  let formLoading = false;

  $: totalBudget = budgetItems.reduce((s, b) => s + b.budget_amount, 0);
  $: totalUsed   = budgetItems.reduce((s, b) => s + b.used_amount, 0);
  $: totalLeft   = totalBudget - totalUsed;
  $: overCount   = budgetItems.filter(b => b.used_amount > b.budget_amount).length;

  onWorkspaceReady(async (wsId) => {
    categories = await categoryService.getByType(wsId, 'expense');
    await loadData();
  });

  async function loadData(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading = true;
    try {
      budgetItems = await budgetService.getByMonth(wsId, year, month);
    } finally {
      loading = false;
    }
  }

  function openAdd() {
    editingBudget = null;
    formCategoryId = '';
    formAmount = '';
    showAddModal = true;
  }

  function openEdit(item) {
    editingBudget = item;
    formCategoryId = item.category_id;
    formAmount = item.budget_amount.toLocaleString('id-ID');
    showAddModal = true;
  }

  async function saveBudget() {
    if (!formCategoryId || !formAmount) {
      showToast('Lengkapi semua field', 'error');
      return;
    }
    const amount = parseFloat(String(formAmount).replace(/\./g, '').replace(',', '.'));
    formLoading = true;
    try {
      const wsId = get(workspaceId);
      if (!wsId) { showToast('Workspace tidak valid', 'error'); return; }
      await budgetService.upsert(wsId, formCategoryId, year, month, amount);
      showToast('Anggaran berhasil disimpan');
      showAddModal = false;
      await loadData();
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      formLoading = false;
    }
  }

  async function deleteBudget(id) {
    if (!confirm('Hapus anggaran ini?')) return;
    try {
      await budgetService.delete(id);
      showToast('Anggaran dihapus');
      await loadData();
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  function formatAmountInput(e) {
    let val = e.target.value.replace(/\D/g, '');
    formAmount = val ? parseInt(val, 10).toLocaleString('id-ID') : '';
    e.target.value = formAmount;
  }
</script>

<svelte:head><title>Anggaran — Dompet</title></svelte:head>

<Topbar title="Anggaran">
  <a href="/settings" class="btn btn-ghost btn-sm">
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6Z" />
    </svg>
    <span class="btn-label">Kategori</span></a>
  <button class="btn btn-ghost btn-sm" on:click={() => showCopyModal = true}>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 0 0 2.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 0 0-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25ZM6.75 12h.008v.008H6.75V12Zm0 3h.008v.008H6.75V15Zm0 3h.008v.008H6.75V18Z" />
    </svg>

    <span class="btn-label">📋Salin Anggaran</span></button>
  <button class="btn btn-primary" on:click={openAdd}>Tambah</button>
</Topbar>

<div class="page-content">
  <!-- Month picker -->
  <div style="display:flex;gap:8px;margin-bottom:20px;align-items:center;flex-wrap:wrap;">
    <select class="form-select" style="width:auto;" bind:value={month} on:change={loadData}>
      {#each months as m}<option value={m.value}>{m.label}</option>{/each}
    </select>
    <select class="form-select" style="width:auto;" bind:value={year} on:change={loadData}>
      {#each years as y}<option value={y}>{y}</option>{/each}
    </select>
    <span style="font-size:13px;color:var(--text-3);margin-left:4px;">{formatMonthYear(year, month)}</span>
  </div>

  <!-- Stats -->
  <div class="stats-grid" style="margin-bottom:20px;">
    <div class="stat-card">
      <div class="stat-label">Total Anggaran</div>
      <div class="stat-value primary">{formatCurrencyShort(totalBudget)}</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Terpakai</div>
      <div class="stat-value expense">{formatCurrencyShort(totalUsed)}</div>
      {#if totalBudget > 0}
        <div class="stat-sub">{Math.round(totalUsed/totalBudget*100)}%</div>
      {/if}
    </div>
    <div class="stat-card">
      <div class="stat-label">Sisa</div>
      <div class="stat-value" style="color:{totalLeft < 0 ? 'var(--expense)' : 'var(--income)'}">
        {formatCurrencyShort(Math.abs(totalLeft))}
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Melebihi Batas</div>
      <div class="stat-value" style="color:{overCount > 0 ? 'var(--expense)' : 'var(--text-3)'}">
        {overCount} kategori
      </div>
    </div>
  </div>

  <!-- Budget list -->
  <div class="card">
    <div class="card-header">
      <span class="card-title">Detail per <span class="btn-label">Kategori</span></span>
      <span style="font-size:12px;color:var(--text-3);">{budgetItems.length} kategori</span>
    </div>

    {#if loading}
      <div class="empty-state"><div class="spinner"></div></div>
    {:else if budgetItems.length === 0}
      <div class="empty-state">
        <div class="empty-icon">📊</div>
        <div class="empty-title">Belum ada anggaran</div>
        <div class="empty-sub"><span class="btn-label">Tambah</span> anggaran atau salin dari bulan sebelumnya</div>
        <div style="display:flex;gap:8px;margin-top:16px;">
          <button class="btn btn-ghost btn-sm" on:click={() => showCopyModal = true}>📋 Salin dari bulan lain</button>
          <button class="btn btn-primary btn-sm" on:click={openAdd}>+ <span class="btn-label">Tambah</span></button>
        </div>
      </div>
    {:else}
      <div class="card-body" style="padding:0;">
        {#each budgetItems as item}
          {@const pct = Math.min(item.usage_percentage, 100)}
          {@const over = item.used_amount > item.budget_amount}
          <div class="budget-row" on:click={() => openEdit(item)} role="button" tabindex="0">
            <div class="budget-row-icon" style="background:{item.category_color + '20'}">
              💡
            </div>
            <div style="flex:1;min-width:0;">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">
                <span style="font-size:13.5px;font-weight:600;">{item.category_name}</span>
                <div style="display:flex;align-items:center;gap:8px;">
                  <span style="font-size:12px;color:var(--text-3);">
                    <strong style="color:{over?'var(--expense)':'var(--text-2)'}">{formatCurrencyShort(item.used_amount)}</strong>
                    / {formatCurrencyShort(item.budget_amount)}
                  </span>
                  <button
                    class="btn btn-ghost btn-sm"
                    style="padding:3px 7px;color:var(--expense);"
                    on:click|stopPropagation={() => deleteBudget(item.id)}
                    aria-label="Hapus"
                  >✕</button>
                </div>
              </div>
              <div class="progress-track">
                <div class="progress-fill" style="width:{pct}%;background:{over ? 'var(--expense)' : (item.category_color || 'var(--primary)')}"></div>
              </div>
              <div style="display:flex;justify-content:space-between;margin-top:4px;">
                <span style="font-size:11px;color:var(--text-3);">
                  Sisa: {formatCurrencyShort(item.remaining_amount)}
                </span>
                <span style="font-size:11px;color:{over?'var(--expense)':'var(--text-3)'};font-weight:{over?600:400}">
                  {over ? '⚠ Melebihi anggaran!' : Math.round(item.usage_percentage) + '%'}
                </span>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Add/Edit Modal -->
<Modal
  title={editingBudget ? 'Edit Anggaran' : 'Tambah Anggaran'}
  open={showAddModal}
  size="sm"
  on:close={() => showAddModal = false}
>
  <div style="display:flex;flex-direction:column;gap:14px;">
    <div class="form-group">
      <label class="form-label"><span class="btn-label">Kategori</span> <span class="required">*</span></label>
      <select class="form-select" bind:value={formCategoryId} disabled={!!editingBudget}>
        <option value="">-- Pilih <span class="btn-label">Kategori</span> --</option>
        {#each categories as c}
          <option value={c.id}>{c.name}</option>
        {/each}
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Jumlah Anggaran <span class="required">*</span></label>
      <div class="amount-wrap">
        <span class="amount-prefix">Rp</span>
        <input type="text" class="form-input amount" value={formAmount} on:input={formatAmountInput} inputmode="numeric" placeholder="0" />
      </div>
    </div>
    <button class="btn btn-primary btn-block" on:click={saveBudget} disabled={formLoading}>
      {formLoading ? 'Menyimpan...' : 'Simpan Anggaran'}
    </button>
  </div>
</Modal>

<!-- Copy Modal -->
<Modal title="Salin Anggaran" open={showCopyModal} size="sm" on:close={() => showCopyModal = false}>
  <CopyBudgetForm
    currentMonth={month}
    currentYear={year}
    on:copied={({ detail }) => {
      month = detail.toMonth;
      year = detail.toYear;
      showCopyModal = false;
      loadData();
    }}
  />
</Modal>

<style>
  .budget-row {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    padding: 14px 16px;
    border-bottom: 1px solid var(--border);
    cursor: pointer;
    transition: background .1s;
  }
  .budget-row:last-child { border-bottom: none; }
  .budget-row:hover { background: #FAFBFC; }
  .budget-row-icon {
    width: 36px; height: 36px;
    border-radius: 9px;
    display: flex; align-items: center; justify-content: center;
    font-size: 16px;
    flex-shrink: 0;
  }
</style>
<!-- NOTE: Category management modal is handled via Settings page -->
<!-- The budgets page already supports adding/editing per-category budgets inline -->
