<!-- src/routes/transactions/+page.svelte -->
<script>
  import { workspaceId } from '$lib/stores';
  import { transactionService } from '$lib/services/transaction.service';
  import { categoryService } from '$lib/services/category.service';
  import { walletService } from '$lib/services/wallet.service';
  import {
    formatCurrencyShort, formatCurrency, formatDate,
    groupByDate, getCurrentMonthYear, toDateInput
  } from '$lib/utils/format';
  import Modal from '../../components/ui/Modal.svelte';
  import TransactionForm from '../../components/forms/TransactionForm.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';
  import { showToast } from '$lib/stores';

  const { month, year } = getCurrentMonthYear();

  // Filters
  let filterType = '';
  let filterCategoryId = '';
  let filterWalletId = '';
  let filterMonth = `${year}-${String(month).padStart(2, '0')}`;

  let transactions = [];
  let categories = [];
  let wallets = [];
  let loading = false;
  let totalIncome = 0;
  let totalExpense = 0;

  let showTxnModal = false;
  let editingTxn = null;
  let showDeleteConfirm = false;
  let deletingId = null;

  import { get } from 'svelte/store';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';

  $: grouped = groupByDate(transactions);

  onWorkspaceReady(async (wsId) => {
    const [cats, wals] = await Promise.all([
      categoryService.getAll(wsId),
      walletService.getAll(wsId)
    ]);
    categories = cats;
    wallets = wals;
    await loadAll(wsId);
  });

  async function loadAll(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading = true;
    try {
      const [y, m] = filterMonth.split('-').map(Number);
      const startDate = `${y}-${String(m).padStart(2,'0')}-01`;
      const endDate = new Date(y, m, 0).toISOString().split('T')[0];

      const data = await transactionService.getAll(wsId, {
        startDate,
        endDate,
        type: filterType || undefined,
        categoryId: filterCategoryId || undefined,
        walletId: filterWalletId || undefined
      });

      transactions = data;
      totalIncome = data.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
      totalExpense = data.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    } finally {
      loading = false;
    }
  }

  function openEdit(txn) {
    editingTxn = txn;
    showTxnModal = true;
  }

  function openDelete(id) {
    deletingId = id;
    showDeleteConfirm = true;
  }

  async function confirmDelete() {
    try {
      await transactionService.delete(deletingId);
      showToast('Transaksi berhasil dihapus');
      showDeleteConfirm = false;
      deletingId = null;
      await loadAll();
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  function txnIcon(txn) {
    const icons = {
      'Makanan & Minuman': '🍜', 'Transportasi': '🚗', 'Belanja': '🛒',
      'Tagihan & Utilitas': '⚡', 'Kesehatan': '💊', 'Hiburan': '🎬',
      'Gaji': '💼', 'Freelance': '💻', 'Investasi': '📈', 'Hadiah': '🎁'
    };
    return icons[txn.category?.name] || (txn.type === 'income' ? '💰' : txn.type === 'transfer' ? '🔄' : '💸');
  }
</script>

<svelte:head><title>Transaksi — Dompet</title></svelte:head>

<Topbar title="Transaksi">
  <button class="btn btn-primary" on:click={() => { editingTxn = null; showTxnModal = true; }}>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
    </svg>

    <span class="btn-label">+ Transaksi Baru</span>
  </button>
</Topbar>

<div class="page-content">
  <!-- Filters -->
  <div class="filters">
    <input type="month" class="form-input filter-item" bind:value={filterMonth} on:change={loadAll} />
    <select class="form-select filter-item" bind:value={filterType} on:change={loadAll}>
      <option value="">Semua Tipe</option>
      <option value="income">Pemasukan</option>
      <option value="expense">Pengeluaran</option>
      <option value="transfer">Transfer</option>
    </select>
    <select class="form-select filter-item" bind:value={filterCategoryId} on:change={loadAll}>
      <option value="">Semua Kategori</option>
      {#each categories as c}
        <option value={c.id}>{c.name}</option>
      {/each}
    </select>
    <select class="form-select filter-item" bind:value={filterWalletId} on:change={loadAll}>
      <option value="">Semua Dompet</option>
      {#each wallets as w}
        <option value={w.id}>{w.name}</option>
      {/each}
    </select>
  </div>

  <!-- Summary bar -->
  {#if !loading}
    <div class="summary-bar">
      <span class="summary-count">{transactions.length} transaksi</span>
      <div style="display:flex;gap:16px;">
        <span class="summary-income">+ {formatCurrencyShort(totalIncome)}</span>
        <span class="summary-expense">− {formatCurrencyShort(totalExpense)}</span>
        <span class="summary-net" style="color:{totalIncome - totalExpense >= 0 ? 'var(--income)' : 'var(--expense)'}">
          Net: {formatCurrencyShort(totalIncome - totalExpense)}
        </span>
      </div>
    </div>
  {/if}

  <!-- List -->
  <div class="card">
    {#if loading}
      <div class="empty-state"><div class="spinner"></div></div>
    {:else if grouped.length === 0}
      <div class="empty-state">
        <div class="empty-icon">📭</div>
        <div class="empty-title">Tidak ada transaksi</div>
        <div class="empty-sub">Coba ubah filter atau tambah transaksi baru</div>
      </div>
    {:else}
      <div class="txn-list">
        {#each grouped as group}
          <div class="txn-date-group">{formatDate(group.date)}</div>
          {#each group.items as txn}
            <div class="txn-item" role="button" tabindex="0" on:click={() => openEdit(txn)}>
              <div class="txn-icon" style="background:{txn.category?.color ? txn.category.color + '20' : '#F1F5F9'}">
                {txnIcon(txn)}
              </div>
              <div class="txn-info">
                <div class="txn-name">{txn.note || txn.category?.name || 'Transaksi'}</div>
                <div class="txn-meta">
                  {txn.category?.name || (txn.type === 'transfer' ? 'Transfer' : '')}
                  {txn.wallet?.name ? '· ' + txn.wallet.name : ''}
                  {txn.to_wallet?.name ? '→ ' + txn.to_wallet.name : ''}
                </div>
              </div>
              <div style="display:flex;align-items:center;gap:8px;">
                <div class="txn-amount {txn.type}">
                  {txn.type === 'income' ? '+' : txn.type === 'expense' ? '−' : '⇄'}
                  {formatCurrencyShort(txn.amount)}
                </div>
                <button
                  class="btn btn-ghost btn-sm"
                  style="padding:4px 6px;color:var(--expense);"
                  on:click|stopPropagation={() => openDelete(txn.id)}
                  aria-label="Hapus"
                >✕</button>
              </div>
            </div>
          {/each}
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Transaction Modal -->
<Modal
  title={editingTxn ? 'Edit Transaksi' : 'Transaksi Baru'}
  open={showTxnModal}
  on:close={() => showTxnModal = false}
>
  <TransactionForm
    transaction={editingTxn}
    on:saved={() => { showTxnModal = false; loadAll(); }}
  />
</Modal>

<!-- Delete Confirm -->
<Modal title="Hapus Transaksi" open={showDeleteConfirm} size="sm" on:close={() => showDeleteConfirm = false}>
  <p style="font-size:14px;color:var(--text-2);margin-bottom:20px;">
    Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.
  </p>
  <div style="display:flex;gap:8px;">
    <button class="btn btn-ghost" style="flex:1;" on:click={() => showDeleteConfirm = false}>Batal</button>
    <button class="btn btn-danger" style="flex:1;" on:click={confirmDelete}>Ya, Hapus</button>
  </div>
</Modal>

<style>
  .filters {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-bottom: 12px;
  }
  .filter-item { width: auto; font-size: 13px; flex: 1; min-width: 120px; max-width: 200px; }

  .summary-bar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 0;
    margin-bottom: 12px;
    font-size: 13px;
    flex-wrap: wrap;
    gap: 8px;
  }
  .summary-count { color: var(--text-3); font-weight: 500; }
  .summary-income { color: var(--income); font-weight: 700; }
  .summary-expense { color: var(--expense); font-weight: 700; }
  .summary-net { font-weight: 700; }
</style>
