<!-- src/routes/dashboard/+page.svelte -->
<script>
  import { get } from 'svelte/store';
  import { workspaceId, showToast } from '$lib/stores';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';
  import { walletService } from '$lib/services/wallet.service';
  import { transactionService } from '$lib/services/transaction.service';
  import { budgetService } from '$lib/services/budget.service';
  import { formatCurrencyShort, formatCurrency, formatDateShort, getCurrentMonthYear } from '$lib/utils/format';
  import Modal from '../../components/ui/Modal.svelte';
  import TransactionForm from '../../components/forms/TransactionForm.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';

  const { month, year } = getCurrentMonthYear();

  let totalBalance = 0;
  let summary      = { total_income: 0, total_expense: 0, net: 0 };
  let totalBudget  = 0;
  let recentTxns   = [];
  let budgetItems  = [];
  let loading      = true;
  let showTxnModal = false;

  // Load data saat workspaceId siap (handles race condition dengan auth restore)
  onWorkspaceReady(async (wsId) => { await loadData(wsId); });

  async function loadData(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading = true;
    try {
      const [bal, sum, budg, txns, budgetUsage] = await Promise.all([
        walletService.getTotalBalance(wsId),
        transactionService.getMonthlySummary(wsId, year, month),
        budgetService.getTotalBudget(wsId, year, month),
        transactionService.getAll(wsId, { limit: 8 }),
        budgetService.getByMonth(wsId, year, month),
      ]);
      totalBalance = bal;
      summary      = sum;
      totalBudget  = budg;
      recentTxns   = txns;
      budgetItems  = budgetUsage.slice(0, 5);
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      loading = false;
    }
  }

  $: remainingBudget = totalBudget - summary.total_expense;
  $: budgetPct       = totalBudget > 0 ? (summary.total_expense / totalBudget * 100) : 0;

  function txnIcon(txn) {
    const icons = {
      'Makanan & Minuman': '🍜', 'Transportasi': '🚗', 'Belanja': '🛒',
      'Tagihan & Utilitas': '⚡', 'Kesehatan': '💊', 'Hiburan': '🎬',
      'Gaji': '💼', 'Freelance': '💻', 'Investasi': '📈', 'Hadiah': '🎁',
    };
    return icons[txn.category?.name]
      || (txn.type === 'income' ? '💰' : txn.type === 'transfer' ? '🔄' : '💸');
  }
</script>

<svelte:head><title>Dashboard — Dompet</title></svelte:head>

<Topbar title="Dashboard">
  <button class="btn btn-primary" on:click={() => showTxnModal = true}>
    <svg style="width:14px;height:14px;" viewBox="0 0 24 24" fill="none"
      stroke="currentColor" stroke-width="2.5">
      <line x1="12" y1="5" x2="12" y2="19"/>
      <line x1="5" y1="12" x2="19" y2="12"/>
    </svg>
    <span class="btn-label">Transaksi Baru</span>
  </button>
</Topbar>

<div class="page-content">
  {#if loading}
    <div class="empty-state"><div class="spinner"></div></div>
  {:else}

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-label">Total Saldo</div>
        <div class="stat-value primary">{formatCurrencyShort(totalBalance)}</div>
        <div class="stat-sub">Semua dompet aktif</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Pemasukan Bulan Ini</div>
        <div class="stat-value income">{formatCurrencyShort(summary.total_income)}</div>
        <div class="stat-sub">Bulan ini</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Pengeluaran Bulan Ini</div>
        <div class="stat-value expense">{formatCurrencyShort(summary.total_expense)}</div>
        <div class="stat-sub">{totalBudget > 0 ? Math.round(budgetPct) + '% dari anggaran' : 'Bulan ini'}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Sisa Anggaran</div>
        <div class="stat-value" style="color:{remainingBudget < 0 ? 'var(--expense)' : 'var(--warning)'}">
          {formatCurrencyShort(Math.abs(remainingBudget))}{remainingBudget < 0 ? ' ⚠' : ''}
        </div>
        <div class="stat-sub">dari {formatCurrencyShort(totalBudget)}</div>
      </div>
    </div>

    <div class="grid-2">
      <!-- Recent Transactions -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">Transaksi Terbaru</span>
          <a href="/transactions" class="btn btn-ghost btn-sm">Lihat Semua</a>
        </div>
        <div class="txn-list">
          {#if recentTxns.length === 0}
            <div class="empty-state">
              <div class="empty-icon">📭</div>
              <div class="empty-title">Belum ada transaksi</div>
              <div class="empty-sub">Tambahkan transaksi pertama Anda</div>
            </div>
          {:else}
            {#each recentTxns as txn}
              <a href="/transactions" class="txn-item">
                <div class="txn-icon"
                  style="background:{txn.category?.color ? txn.category.color + '20' : '#F1F5F9'}">
                  {txnIcon(txn)}
                </div>
                <div class="txn-info">
                  <div class="txn-name">{txn.note || txn.category?.name || 'Transaksi'}</div>
                  <div class="txn-meta">
                    {txn.category?.name || ''}
                    {txn.wallet?.name ? '· ' + txn.wallet.name : ''}
                    · {formatDateShort(txn.date)}
                  </div>
                </div>
                <div class="txn-amount {txn.type}">
                  {txn.type === 'income' ? '+' : txn.type === 'expense' ? '−' : '⇄'}
                  {formatCurrencyShort(txn.amount)}
                </div>
              </a>
            {/each}
          {/if}
        </div>
      </div>

      <!-- Budget Summary -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">Anggaran Bulan Ini</span>
          <a href="/budgets" class="btn btn-ghost btn-sm">Kelola</a>
        </div>
        <div class="card-body">
          {#if budgetItems.length === 0}
            <div class="empty-state" style="padding:24px;">
              <div class="empty-icon">📊</div>
              <div class="empty-title">Belum ada anggaran</div>
              <div class="empty-sub">Buat anggaran untuk mulai tracking</div>
            </div>
          {:else}
            {#each budgetItems as item}
              {@const pct  = Math.min(item.usage_percentage, 100)}
              {@const over = item.used_amount > item.budget_amount}
              <div style="margin-bottom:14px;">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:5px;">
                  <div style="display:flex;align-items:center;gap:7px;font-size:13px;font-weight:600;">
                    <div style="width:8px;height:8px;border-radius:50%;background:{item.category_color||'#94A3B8'}"></div>
                    {item.category_name}
                  </div>
                  <div style="font-size:12px;color:var(--text-3);">
                    <strong style="color:{over?'var(--expense)':'var(--text-2)'}">
                      {formatCurrencyShort(item.used_amount)}
                    </strong>
                    / {formatCurrencyShort(item.budget_amount)}
                  </div>
                </div>
                <div class="progress-track">
                  <div class="progress-fill"
                    style="width:{pct}%;background:{over?'var(--expense)':(item.category_color||'var(--primary)')}">
                  </div>
                </div>
                <div style="font-size:11px;color:{over?'var(--expense)':'var(--text-3)'};
                  font-weight:{over?600:400};margin-top:3px;text-align:right;">
                  {over ? '⚠ Melebihi anggaran!' : Math.round(item.usage_percentage) + '%'}
                </div>
              </div>
            {/each}
          {/if}
        </div>
      </div>
    </div>
  {/if}
</div>

<Modal title="Transaksi Baru" open={showTxnModal} on:close={() => showTxnModal = false}>
  <TransactionForm on:saved={() => { showTxnModal = false; loadData(); }} />
</Modal>
