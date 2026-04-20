<!-- src/routes/savings/+page.svelte -->
<script>
  import { get } from 'svelte/store';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';
  import { workspaceId, showToast } from '$lib/stores';
  import { savingsService } from '$lib/services/savings.service';
  import { formatCurrency, formatCurrencyShort, formatDate, toDateInput } from '$lib/utils/format';
  import Modal from '../../components/ui/Modal.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';

  onWorkspaceReady(async (wsId) => { await loadGoals(wsId); });

  let goals = [];
  let loading = false;
  let showFormModal = false;
  let showContribModal = false;
  let showHistoryModal = false;
  let showDeleteConfirm = false;
  let editingGoal = null;
  let activeGoal = null;
  let contributions = [];
  let deletingId = null;

  // Form state
  let formName = '';
  let formCategory = 'lainnya';
  let formTarget = '';
  let formCurrent = '';
  let formDate = '';
  let formColor = '#0EA5E9';
  let formIcon = '🎯';
  let formNotes = '';
  let formLoading = false;

  // Contribution form
  let contribAmount = '';
  let contribNote = '';
  let contribDate = toDateInput();
  let contribType = 'setor'; // setor | tarik
  let contribLoading = false;

  const categories = [
    { value: 'liburan',    label: 'Liburan',         icon: '✈️',  color: '#06B6D4' },
    { value: 'umroh',      label: 'Umroh / Haji',    icon: '🕌',  color: '#16A34A' },
    { value: 'pendidikan', label: 'Pendidikan Anak', icon: '🎓',  color: '#3B82F6' },
    { value: 'pernikahan', label: 'Pernikahan',       icon: '💍',  color: '#EC4899' },
    { value: 'rumah',      label: 'Rumah / Properti', icon: '🏠',  color: '#F97316' },
    { value: 'kendaraan',  label: 'Kendaraan',        icon: '🚗',  color: '#8B5CF6' },
    { value: 'darurat',    label: 'Dana Darurat',     icon: '🛡️',  color: '#EF4444' },
    { value: 'investasi',  label: 'Investasi',        icon: '📈',  color: '#10B981' },
    { value: 'lainnya',    label: 'Lainnya',          icon: '🎯',  color: '#94A3B8' },
  ];

  $: activeGoals    = goals.filter(g => !g.is_completed);
  $: completedGoals = goals.filter(g => g.is_completed);
  $: totalTarget    = activeGoals.reduce((s, g) => s + g.target_amount, 0);
  $: totalSaved     = activeGoals.reduce((s, g) => s + g.current_amount, 0);



  async function loadGoals(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading = true;
    try { goals = await savingsService.getAll(wsId); }
    finally { loading = false; }
  }

  function getCatMeta(cat) {
    return categories.find(c => c.value === cat) || categories.at(-1);
  }

  function openAdd() {
    editingGoal = null;
    const defCat = categories[0];
    formName = ''; formCategory = 'liburan'; formTarget = '';
    formCurrent = '0'; formDate = ''; formColor = defCat.color;
    formIcon = defCat.icon; formNotes = '';
    showFormModal = true;
  }

  function openEdit(g) {
    editingGoal = g;
    formName = g.name; formCategory = g.category;
    formTarget = g.target_amount.toLocaleString('id-ID');
    formCurrent = g.current_amount.toLocaleString('id-ID');
    formDate = g.target_date || ''; formColor = g.color;
    formIcon = g.icon; formNotes = g.notes || '';
    showFormModal = true;
  }

  async function saveGoal() {
    if (!formName.trim() || !formTarget) {
      showToast('Nama dan target wajib diisi', 'error'); return;
    }
    const target  = parseFloat(String(formTarget).replace(/\./g, '').replace(',', '.'));
    const current = parseFloat(String(formCurrent).replace(/\./g, '').replace(',', '.')) || 0;
    formLoading = true;
    try {
      const payload = {
        name: formName.trim(), category: formCategory,
        target_amount: target, current_amount: current,
        target_date: formDate || null, color: formColor,
        icon: formIcon, notes: formNotes || null
      };
      if (editingGoal) {
        await savingsService.update(editingGoal.id, payload);
        showToast('Tabungan rencana diperbarui');
      } else {
        await savingsService.create($workspaceId, payload);
        showToast('Tabungan rencana dibuat!');
      }
      showFormModal = false;
      await loadGoals();
    } catch (e) { showToast(e.message, 'error'); }
    finally { formLoading = false; }
  }

  function openContrib(g) {
    activeGoal = g; contribAmount = ''; contribNote = '';
    contribDate = toDateInput(); contribType = 'setor';
    showContribModal = true;
  }

  async function saveContrib() {
    if (!contribAmount) { showToast('Jumlah wajib diisi', 'error'); return; }
    const raw = parseFloat(String(contribAmount).replace(/\./g, '').replace(',', '.'));
    const amount = contribType === 'tarik' ? -raw : raw;
    contribLoading = true;
    try {
      await savingsService.contribute(activeGoal.id, amount, contribNote || null, contribDate);
      showToast(contribType === 'setor' ? `+${formatCurrencyShort(raw)} ditabung!` : `${formatCurrencyShort(raw)} ditarik`);
      showContribModal = false;
      await loadGoals();
    } catch (e) { showToast(e.message, 'error'); }
    finally { contribLoading = false; }
  }

  async function openHistory(g) {
    activeGoal = g;
    contributions = await savingsService.getContributions(g.id);
    showHistoryModal = true;
  }

  async function markComplete(g) {
    try {
      await savingsService.update(g.id, { is_completed: !g.is_completed });
      showToast(g.is_completed ? 'Dipindah ke aktif' : '🎉 Selamat, tujuan tercapai!');
      await loadGoals();
    } catch (e) { showToast(e.message, 'error'); }
  }

  async function deleteGoal() {
    try {
      await savingsService.delete(deletingId);
      showToast('Tabungan rencana dihapus');
      showDeleteConfirm = false; deletingId = null;
      await loadGoals();
    } catch (e) { showToast(e.message, 'error'); }
  }

  function onCatChange(val) {
    formCategory = val;
    const meta = getCatMeta(val);
    formColor = meta.color; formIcon = meta.icon;
  }

  function fmtInput(e) {
    let v = e.target.value.replace(/\D/g,'');
    e.target.value = v ? parseInt(v,10).toLocaleString('id-ID') : '';
    return e.target.value;
  }
</script>

<svelte:head><title>Tabungan Rencana — Dompet</title></svelte:head>

<Topbar title="Tabungan Rencana">
  <button class="btn btn-primary" on:click={openAdd}>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
    </svg>
    <span class="btn-label">+ Rencana Baru</span>
  </button>
</Topbar>

<div class="page-content">

  <!-- Summary banner -->
  {#if activeGoals.length > 0}
  <div class="summary-banner">
    <div class="summary-item">
      <div class="summary-label">Total Terkumpul</div>
      <div class="summary-value">{formatCurrencyShort(totalSaved)}</div>
    </div>
    <div class="summary-divider"></div>
    <div class="summary-item">
      <div class="summary-label">Total Target</div>
      <div class="summary-value">{formatCurrencyShort(totalTarget)}</div>
    </div>
    <div class="summary-divider"></div>
    <div class="summary-item">
      <div class="summary-label">Rencana Aktif</div>
      <div class="summary-value">{activeGoals.length}</div>
    </div>
    <div class="summary-progress-wrap">
      <div class="summary-progress-label">Progress keseluruhan</div>
      <div class="summary-progress-track">
        <div class="summary-progress-fill" style="width:{totalTarget>0?Math.min(totalSaved/totalTarget*100,100):0}%"></div>
      </div>
      <div class="summary-progress-pct">{totalTarget>0?Math.round(totalSaved/totalTarget*100):0}%</div>
    </div>
  </div>
  {/if}

  {#if loading}
    <div class="empty-state"><div class="spinner"></div></div>
  {:else if goals.length === 0}
    <div class="empty-state" style="padding:64px 24px;">
      <div class="empty-icon">🎯</div>
      <div class="empty-title">Belum ada tabungan rencana</div>
      <div class="empty-sub">Mulai rencanakan tujuan finansial Anda</div>
      <button class="btn btn-primary" style="margin-top:20px;" on:click={openAdd}>+ Buat Rencana Pertama</button>
    </div>
  {:else}

    <!-- Active goals -->
    {#if activeGoals.length > 0}
      <div class="section-label">Sedang Berjalan ({activeGoals.length})</div>
      <div class="goals-grid">
        {#each activeGoals as g}
          {@const meta = getCatMeta(g.category)}
          {@const pct = Math.min(g.progress_pct, 100)}
          <div class="goal-card">
            <div class="goal-card-header" style="background:{g.color}">
              <span class="goal-icon">{g.icon}</span>
              <div class="goal-card-actions">
                <button class="goal-action-btn" on:click={() => openEdit(g)} title="Edit">✏️</button>
                <button class="goal-action-btn" on:click={() => { deletingId = g.id; showDeleteConfirm = true; }} title="Hapus">🗑️</button>
              </div>
              <div class="goal-cat-badge">{meta.label}</div>
            </div>
            <div class="goal-card-body">
              <div class="goal-name">{g.name}</div>

              {#if g.target_date}
                <div class="goal-date">
                  🗓️ Target: {formatDate(g.target_date)}
                  {#if g.days_remaining > 0}
                    <span class="days-badge">{g.days_remaining} hari lagi</span>
                  {:else}
                    <span class="days-badge days-badge--over">Lewat target!</span>
                  {/if}
                </div>
              {/if}

              <!-- Progress -->
              <div class="goal-progress-wrap">
                <div class="goal-amounts">
                  <span class="goal-current">{formatCurrencyShort(g.current_amount)}</span>
                  <span class="goal-target">dari {formatCurrencyShort(g.target_amount)}</span>
                </div>
                <div class="goal-track">
                  <div class="goal-fill" style="width:{pct}%;background:{g.color}"></div>
                </div>
                <div class="goal-pct-row">
                  <span style="font-size:12px;color:var(--text-3);">{pct}% tercapai</span>
                  {#if g.monthly_needed > 0}
                    <span style="font-size:11.5px;color:var(--text-3);">~{formatCurrencyShort(g.monthly_needed)}/bln</span>
                  {/if}
                </div>
              </div>

              {#if g.notes}
                <div class="goal-notes">💬 {g.notes}</div>
              {/if}

              <!-- Actions -->
              <div class="goal-actions">
                <button class="btn btn-primary btn-sm" style="flex:1;" on:click={() => openContrib(g)}>
                  + Setor / Tarik
                </button>
                <button class="btn btn-ghost btn-sm" on:click={() => openHistory(g)}>Riwayat</button>
                <button class="btn btn-ghost btn-sm" on:click={() => markComplete(g)} title="Tandai selesai">✓</button>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}

    <!-- Completed goals -->
    {#if completedGoals.length > 0}
      <div class="section-label" style="margin-top:28px;">Tercapai 🎉 ({completedGoals.length})</div>
      <div class="goals-grid">
        {#each completedGoals as g}
          {@const meta = getCatMeta(g.category)}
          <div class="goal-card goal-card--done">
            <div class="goal-card-header" style="background:{g.color};opacity:.7;">
              <span class="goal-icon">{g.icon}</span>
              <div class="goal-cat-badge">{meta.label}</div>
            </div>
            <div class="goal-card-body">
              <div style="display:flex;align-items:center;gap:8px;">
                <div class="goal-name">{g.name}</div>
                <span class="badge badge-green">✓ Tercapai</span>
              </div>
              <div style="font-size:13px;color:var(--text-3);margin-top:4px;">
                {formatCurrencyShort(g.current_amount)} terkumpul
              </div>
              <div class="goal-actions" style="margin-top:12px;">
                <button class="btn btn-ghost btn-sm" on:click={() => openHistory(g)}>Riwayat</button>
                <button class="btn btn-ghost btn-sm" on:click={() => markComplete(g)}>Aktifkan Lagi</button>
                <button class="btn btn-ghost btn-sm" style="color:var(--expense);" on:click={() => { deletingId = g.id; showDeleteConfirm = true; }}>Hapus</button>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  {/if}
</div>

<!-- Form Modal -->
<Modal title={editingGoal ? 'Edit Rencana' : 'Rencana Tabungan Baru'} open={showFormModal} on:close={() => showFormModal = false}>
  <div class="goal-form">
    <!-- Category picker -->
    <div class="form-group">
      <label class="form-label">Kategori *</label>
      <div class="cat-grid">
        {#each categories as c}
          <button
            class="cat-opt"
            class:cat-opt--active={formCategory === c.value}
            style="--cat-color:{c.color}"
            on:click={() => onCatChange(c.value)}
          >
            <span style="font-size:20px;">{c.icon}</span>
            <span style="font-size:11px;margin-top:2px;">{c.label}</span>
          </button>
        {/each}
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Nama Rencana *</label>
      <input type="text" class="form-input" placeholder="cth. Liburan ke Bali 2026" bind:value={formName} />
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
      <div class="form-group">
        <label class="form-label">Target Dana *</label>
        <div class="amount-wrap">
          <span class="amount-prefix">Rp</span>
          <input type="text" class="form-input amount" placeholder="0"
            value={formTarget} on:input={e => { formTarget = fmtInput(e); }} inputmode="numeric" />
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Dana Awal</label>
        <div class="amount-wrap">
          <span class="amount-prefix">Rp</span>
          <input type="text" class="form-input amount" placeholder="0"
            value={formCurrent} on:input={e => { formCurrent = fmtInput(e); }} inputmode="numeric" />
        </div>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Target Tanggal (opsional)</label>
      <input type="date" class="form-input" bind:value={formDate} />
    </div>

    <div class="form-group">
      <label class="form-label">Catatan</label>
      <input type="text" class="form-input" placeholder="Opsional..." bind:value={formNotes} />
    </div>

    <button class="btn btn-primary btn-block" on:click={saveGoal} disabled={formLoading}>
      {formLoading ? 'Menyimpan...' : (editingGoal ? 'Perbarui' : 'Buat Rencana')}
    </button>
  </div>
</Modal>

<!-- Contribute Modal -->
<Modal title="Setor / Tarik Dana" open={showContribModal} size="sm" on:close={() => showContribModal = false}>
  {#if activeGoal}
    <div style="background:var(--bg);border-radius:10px;padding:12px;margin-bottom:16px;">
      <div style="font-size:12px;color:var(--text-3);">Tabungan saat ini</div>
      <div style="font-size:20px;font-weight:700;color:var(--primary);">{formatCurrency(activeGoal.current_amount)}</div>
      <div style="font-size:12px;color:var(--text-3);">dari {formatCurrency(activeGoal.target_amount)}</div>
    </div>

    <div class="type-tabs" style="margin-bottom:16px;">
      <button class="type-tab" class:active={contribType==='setor'} class:income={contribType==='setor'}
        on:click={() => contribType='setor'}>💰 Setor</button>
      <button class="type-tab" class:active={contribType==='tarik'} class:expense={contribType==='tarik'}
        on:click={() => contribType='tarik'}>💸 Tarik</button>
    </div>

    <div class="form-group" style="margin-bottom:14px;">
      <label class="form-label">Jumlah *</label>
      <div class="amount-wrap">
        <span class="amount-prefix">Rp</span>
        <input type="text" class="form-input amount" placeholder="0"
          value={contribAmount} on:input={e => { contribAmount = fmtInput(e); }} inputmode="numeric" />
      </div>
    </div>
    <div class="form-group" style="margin-bottom:14px;">
      <label class="form-label">Tanggal</label>
      <input type="date" class="form-input" bind:value={contribDate} />
    </div>
    <div class="form-group" style="margin-bottom:16px;">
      <label class="form-label">Catatan</label>
      <input type="text" class="form-input" placeholder="Opsional..." bind:value={contribNote} />
    </div>

    <button class="btn btn-block btn-primary" style="background:{contribType==='tarik'?'var(--expense)':'var(--income)'}"
      on:click={saveContrib} disabled={contribLoading}>
      {contribLoading ? 'Memproses...' : (contribType==='setor' ? '💰 Setor Dana' : '💸 Tarik Dana')}
    </button>
  {/if}
</Modal>

<!-- History Modal -->
<Modal title="Riwayat Setoran" open={showHistoryModal} on:close={() => showHistoryModal = false}>
  {#if contributions.length === 0}
    <div class="empty-state" style="padding:32px;"><div class="empty-icon">📭</div><div class="empty-title">Belum ada riwayat</div></div>
  {:else}
    <div class="txn-list" style="margin:-20px;">
      {#each contributions as c}
        <div class="txn-item">
          <div class="txn-icon" style="background:{c.amount>0?'#DCFCE7':'#FEE2E2'}">{c.amount>0?'💰':'💸'}</div>
          <div class="txn-info">
            <div class="txn-name">{c.note || (c.amount>0 ? 'Setoran' : 'Penarikan')}</div>
            <div class="txn-meta">{formatDate(c.date)}</div>
          </div>
          <div class="txn-amount" style="color:{c.amount>0?'var(--income)':'var(--expense)'}">
            {c.amount>0?'+':''}{formatCurrencyShort(Math.abs(c.amount))}
          </div>
        </div>
      {/each}
    </div>
  {/if}
</Modal>

<!-- Delete Confirm -->
<Modal title="Hapus Rencana" open={showDeleteConfirm} size="sm" on:close={() => showDeleteConfirm = false}>
  <p style="font-size:14px;color:var(--text-2);margin-bottom:20px;">Hapus tabungan rencana ini beserta seluruh riwayatnya?</p>
  <div style="display:flex;gap:8px;">
    <button class="btn btn-ghost" style="flex:1;" on:click={() => showDeleteConfirm = false}>Batal</button>
    <button class="btn btn-danger" style="flex:1;" on:click={deleteGoal}>Ya, Hapus</button>
  </div>
</Modal>

<style>
  .summary-banner {
    display: flex; align-items: center; gap: 24px;
    background: linear-gradient(135deg,#0EA5E9,#0284C7);
    color: white; border-radius: 16px; padding: 20px 24px;
    margin-bottom: 24px; flex-wrap: wrap;
  }
  .summary-item { display:flex;flex-direction:column;gap:4px; }
  .summary-label { font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;opacity:.7; }
  .summary-value { font-size:20px;font-weight:700;letter-spacing:-.02em; }
  .summary-divider { width:1px;height:40px;background:rgba(255,255,255,.25); }
  .summary-progress-wrap { flex:1;min-width:160px; }
  .summary-progress-label { font-size:11px;opacity:.7;margin-bottom:6px; }
  .summary-progress-track { height:8px;background:rgba(255,255,255,.25);border-radius:99px;overflow:hidden; }
  .summary-progress-fill { height:100%;background:white;border-radius:99px;transition:width .6s ease; }
  .summary-progress-pct { font-size:12px;font-weight:700;margin-top:4px; }

  .section-label { font-size:12px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.05em;margin-bottom:12px; }

  .goals-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px; }

  .goal-card { background:var(--card);border:1px solid var(--border);border-radius:16px;overflow:hidden;transition:box-shadow .2s; }
  .goal-card:hover { box-shadow: 0 6px 20px rgba(0,0,0,.08); }
  .goal-card--done { opacity:.75; }

  .goal-card-header {
    padding:20px 16px 14px;
    position:relative;
    display:flex;align-items:flex-start;justify-content:space-between;
  }
  .goal-icon { font-size:32px;line-height:1; }
  .goal-card-actions { display:flex;gap:4px; }
  .goal-action-btn {
    width:28px;height:28px;border:none;background:rgba(255,255,255,.25);
    border-radius:6px;cursor:pointer;font-size:13px;
    display:flex;align-items:center;justify-content:center;
    transition:background .15s;
  }
  .goal-action-btn:hover { background:rgba(255,255,255,.45); }
  .goal-cat-badge {
    position:absolute;bottom:10px;left:16px;
    font-size:10.5px;font-weight:700;color:white;
    background:rgba(0,0,0,.2);padding:3px 9px;border-radius:99px;
    text-transform:uppercase;letter-spacing:.05em;
  }

  .goal-card-body { padding:14px 16px 16px; }
  .goal-name { font-size:15px;font-weight:700;margin-bottom:6px; }
  .goal-date { font-size:12px;color:var(--text-3);margin-bottom:10px;display:flex;align-items:center;gap:6px;flex-wrap:wrap; }
  .days-badge { background:#FEF3C7;color:#B45309;padding:2px 8px;border-radius:99px;font-size:11px;font-weight:600; }
  .days-badge--over { background:#FEE2E2;color:#B91C1C; }

  .goal-progress-wrap { margin-bottom:10px; }
  .goal-amounts { display:flex;align-items:baseline;gap:6px;margin-bottom:6px; }
  .goal-current { font-size:17px;font-weight:700; }
  .goal-target { font-size:12px;color:var(--text-3); }
  .goal-track { height:8px;background:var(--bg);border-radius:99px;overflow:hidden;margin-bottom:4px; }
  .goal-fill { height:100%;border-radius:99px;transition:width .6s ease; }
  .goal-pct-row { display:flex;justify-content:space-between; }
  .goal-notes { font-size:12px;color:var(--text-3);margin-bottom:10px;font-style:italic; }
  .goal-actions { display:flex;gap:6px;margin-top:12px; }

  /* Form */
  .goal-form { display:flex;flex-direction:column;gap:16px; }
  .cat-grid { display:grid;grid-template-columns:repeat(3,1fr);gap:7px; }
  .cat-opt {
    display:flex;flex-direction:column;align-items:center;gap:3px;
    padding:10px 6px;border:1.5px solid var(--border);border-radius:10px;
    background:transparent;cursor:pointer;font-family:inherit;transition:all .15s;
  }
  .cat-opt:hover { background:var(--bg); }
  .cat-opt--active { border-color:var(--cat-color,var(--primary));background:color-mix(in srgb, var(--cat-color,var(--primary)) 10%, white); }

  /* Type tabs reuse */
  .type-tabs { display:flex;background:var(--bg);border-radius:10px;padding:3px;gap:3px; }
  .type-tab { flex:1;padding:7px;border-radius:7px;border:none;background:transparent;font-size:13px;font-weight:600;color:var(--text-3);cursor:pointer;transition:all .15s;font-family:inherit; }
  .type-tab.active { background:white;box-shadow:0 1px 4px rgba(0,0,0,.08); }
  .type-tab.active.income { color:var(--income); }
  .type-tab.active.expense { color:var(--expense); }
</style>
