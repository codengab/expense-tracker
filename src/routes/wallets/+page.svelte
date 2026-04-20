<!-- src/routes/wallets/+page.svelte -->
<script>
  import { get } from 'svelte/store';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';
  import { workspaceId, showToast } from '$lib/stores';
  import { walletService } from '$lib/services/wallet.service';
  import { formatCurrency, formatCurrencyShort } from '$lib/utils/format';
  import Modal from '../../components/ui/Modal.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';

  onWorkspaceReady(async (wsId) => { await loadWallets(wsId); });

  let wallets = [];
  let totalBalance = 0;
  let loading = false;
  let showModal = false;
  let editingWallet = null;
  let showDeleteConfirm = false;
  let deletingId = null;

  // Form
  let formName = '';
  let formType = 'cash';
  let formInitialBalance = '';
  let formColor = '#0EA5E9';
  let formLoading = false;

  const walletTypes = [
    { value: 'cash',       label: 'Tunai',    icon: '💵' },
    { value: 'bank',       label: 'Bank',     icon: '🏦' },
    { value: 'e-wallet',   label: 'E-Wallet', icon: '📱' },
    { value: 'investment', label: 'Investasi',icon: '📈' },
    { value: 'other',      label: 'Lainnya',  icon: '💳' }
  ];

  const colors = ['#0EA5E9','#16A34A','#F59E0B','#DC2626','#8B5CF6','#EC4899','#06B6D4','#F97316','#64748B'];


  async function loadWallets(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading = true;
    try {
      wallets = await walletService.getAll(wsId);
      totalBalance = wallets.filter(w => w.is_active).reduce((s, w) => s + (w.current_balance || 0), 0);
    } finally { loading = false; }
  }

  function openAdd() {
    editingWallet = null;
    formName = ''; formType = 'cash'; formInitialBalance = ''; formColor = '#0EA5E9';
    showModal = true;
  }

  function openEdit(w) {
    editingWallet = w;
    formName = w.name; formType = w.type;
    // Tampilkan saldo awal saat ini agar bisa diubah
    formInitialBalance = w.initial_balance.toLocaleString('id-ID');
    formColor = w.color || '#0EA5E9';
    showModal = true;
  }

  async function saveWallet() {
    if (!formName.trim()) { showToast('Nama dompet wajib diisi', 'error'); return; }
    const balance = parseFloat(String(formInitialBalance).replace(/\./g,'').replace(',','.')) || 0;
    formLoading = true;
    try {
      if (editingWallet) {
        // Update termasuk initial_balance — saldo akan terhitung ulang dari view
        await walletService.update(editingWallet.id, {
          name: formName.trim(),
          type: formType,
          color: formColor,
          initial_balance: balance   // ← ubah saldo awal
        });
        showToast('Dompet berhasil diperbarui');
      } else {
        await walletService.create($workspaceId, {
          name: formName.trim(), type: formType,
          initial_balance: balance, color: formColor
        });
        showToast('Dompet berhasil ditambahkan');
      }
      showModal = false;
      await loadWallets();
    } catch (e) { showToast(e.message, 'error'); }
    finally { formLoading = false; }
  }

  async function toggleActive(w) {
    try {
      await walletService.toggleActive(w.id, !w.is_active);
      showToast(`Dompet ${!w.is_active ? 'diaktifkan' : 'dinonaktifkan'}`);
      await loadWallets();
    } catch (e) { showToast(e.message, 'error'); }
  }

  async function confirmDelete() {
    try {
      await walletService.delete(deletingId);
      showToast('Dompet dihapus');
      showDeleteConfirm = false; deletingId = null;
      await loadWallets();
    } catch (e) { showToast(e.message, 'error'); }
  }

  function walletTypeIcon(type) {
    return walletTypes.find(t => t.value === type)?.icon || '💳';
  }

  function fmtInput(e) {
    let v = e.target.value.replace(/\D/g,'');
    let fmt = v ? parseInt(v,10).toLocaleString('id-ID') : '';
    formInitialBalance = fmt;
    e.target.value = fmt;
  }
</script>

<svelte:head><title>Dompet — Dompet App</title></svelte:head>

<Topbar title="Dompet">
  <button class="btn btn-primary" on:click={openAdd}><span class="btn-label">+ Tambah Dompet</span></button>
</Topbar>

<div class="page-content">
  <!-- Total banner -->
  <div class="total-banner">
    <div>
      <div class="total-label">Total Saldo</div>
      <div class="total-value">{formatCurrencyShort(totalBalance)}</div>
      <div class="total-sub">{wallets.filter(w=>w.is_active).length} dompet aktif</div>
    </div>
  </div>

  {#if loading}
    <div class="empty-state"><div class="spinner"></div></div>
  {:else}

    <!-- Wallet cards -->
    <div class="wallet-grid">
      {#each wallets.filter(w=>w.is_active) as w}
        <div class="wallet-card" style="background:{w.color||'#0EA5E9'}"
          on:click={() => openEdit(w)} role="button" tabindex="0">
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
            <span style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;opacity:.7;">
              {walletTypes.find(t=>t.value===w.type)?.label||w.type}
            </span>
            <span style="font-size:20px;">{walletTypeIcon(w.type)}</span>
          </div>
          <div style="font-size:15px;font-weight:700;margin-bottom:12px;">{w.name}</div>
          <div style="font-size:22px;font-weight:700;letter-spacing:-.02em;">{formatCurrencyShort(w.current_balance||0)}</div>
          <div style="font-size:11px;color:rgba(255,255,255,.6);margin-top:4px;">Saldo awal: {formatCurrencyShort(w.initial_balance)}</div>
        </div>
      {/each}
      <div class="wallet-add-card" on:click={openAdd} role="button" tabindex="0">
        <div style="font-size:28px;margin-bottom:6px;color:var(--text-3);">+</div>
        <div style="font-size:13px;font-weight:600;color:var(--text-3);">Tambah Dompet</div>
      </div>
    </div>

    <!-- All wallets table -->
    <div class="card" style="margin-top:20px;">
      <div class="card-header"><span class="card-title">Semua Dompet</span></div>
      <div class="txn-list">
        {#each wallets as w}
          <div class="txn-item">
            <div class="txn-icon" style="background:{(w.color||'#0EA5E9')+'20'};font-size:18px;">{walletTypeIcon(w.type)}</div>
            <div class="txn-info">
              <div class="txn-name">{w.name}</div>
              <div class="txn-meta">
                {walletTypes.find(t=>t.value===w.type)?.label} ·
                Saldo awal {formatCurrencyShort(w.initial_balance)} ·
                {w.is_active ? 'Aktif' : 'Non-aktif'}
              </div>
            </div>
            <div style="display:flex;align-items:center;gap:8px;flex-shrink:0;">
              <div style="text-align:right;">
                <div style="font-size:15px;font-weight:700;color:{w.is_active?'var(--income)':'var(--text-3)'}">
                  {formatCurrencyShort(w.current_balance||0)}
                </div>
                <div class="badge {w.is_active?'badge-green':'badge-gray'}" style="margin-top:2px;">
                  {w.is_active?'aktif':'non-aktif'}
                </div>
              </div>
              <div style="display:flex;flex-direction:column;gap:4px;">
                <button class="btn btn-ghost btn-sm" on:click|stopPropagation={() => openEdit(w)}>Edit</button>
                <button class="btn btn-ghost btn-sm" on:click|stopPropagation={() => toggleActive(w)}>
                  {w.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                </button>
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>

<!-- Add/Edit Modal -->
<Modal title={editingWallet ? 'Edit Dompet' : 'Tambah Dompet'} open={showModal} size="sm" on:close={() => showModal = false}>
  <div style="display:flex;flex-direction:column;gap:16px;">

    <div class="form-group">
      <label class="form-label">Nama Dompet *</label>
      <input type="text" class="form-input" placeholder="cth. BCA Tabungan" bind:value={formName} />
    </div>

    <div class="form-group">
      <label class="form-label">Tipe *</label>
      <div class="type-grid">
        {#each walletTypes as t}
          <button class="type-opt" class:type-opt--active={formType===t.value} on:click={() => formType=t.value}>
            <span style="font-size:20px;">{t.icon}</span>
            <span style="font-size:11.5px;">{t.label}</span>
          </button>
        {/each}
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">
        Saldo Awal
        {#if editingWallet}
          <span style="font-size:11px;color:var(--primary);font-weight:500;">
            (mengubah ini akan menyesuaikan saldo keseluruhan)
          </span>
        {/if}
      </label>
      <div class="amount-wrap">
        <span class="amount-prefix">Rp</span>
        <input type="text" class="form-input amount"
          value={formInitialBalance}
          on:input={fmtInput}
          inputmode="numeric" placeholder="0" />
      </div>
      {#if editingWallet}
        <div style="font-size:12px;color:var(--text-3);margin-top:4px;">
          Saldo saat ini: <strong>{formatCurrency(editingWallet.current_balance||0)}</strong>
          (saldo awal + semua transaksi)
        </div>
      {/if}
    </div>

    <div class="form-group">
      <label class="form-label">Warna</label>
      <div style="display:flex;gap:8px;flex-wrap:wrap;">
        {#each colors as c}
          <button class="color-swatch"
            style="background:{c};outline:{formColor===c?'3px solid '+c+'80':'none'};outline-offset:2px;"
            on:click={() => formColor=c} aria-label={c}></button>
        {/each}
      </div>
    </div>

    <button class="btn btn-primary btn-block" on:click={saveWallet} disabled={formLoading}>
      {formLoading ? 'Menyimpan...' : (editingWallet ? 'Perbarui Dompet' : 'Tambah Dompet')}
    </button>

    {#if editingWallet}
      <button class="btn btn-danger btn-sm" style="align-self:center;"
        on:click={() => { showModal=false; deletingId=editingWallet.id; showDeleteConfirm=true; }}>
        Hapus Dompet
      </button>
    {/if}
  </div>
</Modal>

<!-- Delete Confirm -->
<Modal title="Hapus Dompet" open={showDeleteConfirm} size="sm" on:close={() => showDeleteConfirm = false}>
  <p style="font-size:14px;color:var(--text-2);margin-bottom:6px;">Yakin ingin menghapus dompet ini?</p>
  <p style="font-size:12.5px;color:var(--expense);margin-bottom:20px;">⚠ Dompet tidak bisa dihapus jika masih memiliki transaksi.</p>
  <div style="display:flex;gap:8px;">
    <button class="btn btn-ghost" style="flex:1;" on:click={() => showDeleteConfirm=false}>Batal</button>
    <button class="btn btn-danger" style="flex:1;" on:click={confirmDelete}>Hapus</button>
  </div>
</Modal>

<style>
  .total-banner { background:linear-gradient(135deg,#0EA5E9,#0284C7);color:white;border-radius:16px;padding:24px;margin-bottom:20px; }
  .total-label { font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;opacity:.7;margin-bottom:4px; }
  .total-value { font-size:28px;font-weight:700;letter-spacing:-.03em; }
  .total-sub { font-size:12px;color:rgba(255,255,255,.6);margin-top:4px; }

  .wallet-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;margin-bottom:8px; }
  .wallet-card { border-radius:14px;padding:18px;color:white;cursor:pointer;transition:transform .15s,box-shadow .15s; }
  .wallet-card:hover { transform:translateY(-2px);box-shadow:0 8px 24px rgba(0,0,0,.15); }

  .wallet-add-card { border-radius:14px;padding:18px;border:2px dashed var(--border);display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;min-height:130px;transition:all .15s; }
  .wallet-add-card:hover { border-color:var(--primary);background:#F0F9FF; }

  .type-grid { display:grid;grid-template-columns:repeat(5,1fr);gap:6px; }
  .type-opt { display:flex;flex-direction:column;align-items:center;gap:4px;padding:8px 4px;border:1.5px solid var(--border);border-radius:8px;background:transparent;cursor:pointer;font-family:inherit;transition:all .15s; }
  .type-opt:hover { background:var(--bg); }
  .type-opt--active { border-color:var(--primary);background:#EFF6FF; }

  .color-swatch { width:28px;height:28px;border-radius:50%;border:none;cursor:pointer;transition:transform .15s; }
  .color-swatch:hover { transform:scale(1.2); }
</style>
