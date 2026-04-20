<!-- src/routes/settings/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  import { get } from 'svelte/store';
  import { onWorkspaceReady } from '$lib/utils/workspace-loader';
  import { workspaceId, activeWorkspace, workspaces, setWorkspace, showToast } from '$lib/stores';
  import { workspaceService } from '$lib/services/workspace.service';
  import { categoryService } from '$lib/services/category.service';
  import { auth, supabase } from '$lib/supabase';
  import Modal from '../../components/ui/Modal.svelte';
  import Topbar from '../../components/layout/Topbar.svelte';
  import { goto } from '$app/navigation';

  let user = null;
  let members = [];
  let allCategories = [];       // semua kategori (default + kustom)
  let loading = { members: false, cats: false };
  let showInviteModal = false;
  let showCatModal = false;
  let editingCat = null;        // null = tambah baru, object = edit
  let wspOwner = get(activeWorkspace).owner_id;

  // Filter tab kategori
  let catFilter = 'all';        // 'all' | 'expense' | 'income'

  // Invite form
  let inviteEmail = '';
  let inviteRole  = 'member';
  let inviteLoading = false;

  // Category form
  let catName    = '';
  let catType    = 'expense';
  let catColor   = '#F97316';
  let catLoading = false;

  const catColors = [
    '#F97316','#EF4444','#F59E0B','#16A34A',
    '#0EA5E9','#8B5CF6','#EC4899','#06B6D4',
    '#64748B','#10B981','#DC2626','#3B82F6',
  ];

  const roles = [
    { value: 'admin',  label: 'Admin',  desc: 'Akses penuh'          },
    { value: 'member', label: 'Member', desc: 'Bisa input transaksi' },
    { value: 'viewer', label: 'Viewer', desc: 'Hanya lihat'          },
  ];

  // ── Derived ────────────────────────────────────────────────
  $: defaultCategories = allCategories.filter(c => c.workspace_id === null);
  $: customCategories  = allCategories.filter(c => c.workspace_id !== null);

  $: visibleDefault = catFilter === 'all'
    ? defaultCategories
    : defaultCategories.filter(c => c.type === catFilter);

  $: visibleCustom = catFilter === 'all'
    ? customCategories
    : customCategories.filter(c => c.type === catFilter);

  // Validasi: apakah nama sudah dipakai (case-insensitive, tipe sama)
  function isDuplicate(name, type, excludeId = null) {
    return allCategories.some(c =>
      c.id !== excludeId &&
      c.name.toLowerCase().trim() === name.toLowerCase().trim() &&
      c.type === type
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────
  onMount(async () => {
    const { data: { user: u } } = await supabase.auth.getUser();
    user = u;
  });

  onWorkspaceReady(async (wsId) => { await loadAll(wsId); });


  async function loadAll(wsId = get(workspaceId)) {
    if (!wsId) return;
    loading.members = true;
    loading.cats    = true;
    try {
      const [mems, cats] = await Promise.all([
        workspaceService.getMembers(wsId),
        categoryService.getAll(wsId),
      ]);
      members       = mems;
      allCategories = cats;
    } finally {
      loading.members = false;
      loading.cats    = false;
    }
  }

  // ── Category actions ───────────────────────────────────────
  function openAddCat() {
    editingCat = null;
    catName = ''; catType = 'expense'; catColor = '#F97316';
    showCatModal = true;
  }

  function openEditCat(cat) {
    editingCat = cat;
    catName  = cat.name;
    catType  = cat.type;
    catColor = cat.color || '#94A3B8';
    showCatModal = true;
  }

  async function saveCategory() {
    const trimmed = catName.trim();
    if (!trimmed) { showToast('Nama kategori wajib diisi', 'error'); return; }

    // Cek duplikat
    if (isDuplicate(trimmed, catType, editingCat?.id)) {
      showToast(`Kategori "${trimmed}" (${catType === 'expense' ? 'pengeluaran' : 'pemasukan'}) sudah ada!`, 'error');
      return;
    }

    catLoading = true;
    try {
      if (editingCat) {
        await categoryService.update(editingCat.id, { name: trimmed, color: catColor });
        showToast('Kategori diperbarui');
      } else {
        await categoryService.create(get(workspaceId), { name: trimmed, type: catType, color: catColor });
        showToast('Kategori ditambahkan');
      }
      showCatModal = false;
      await loadAll();
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      catLoading = false;
    }
  }

  async function deleteCategory(cat) {
    if (cat.workspace_id === null) {
      showToast('Kategori bawaan tidak bisa dihapus', 'error'); return;
    }
    if (!confirm(`Hapus kategori "${cat.name}"?`)) return;
    try {
      await categoryService.delete(cat.id);
      showToast('Kategori dihapus');
      await loadAll();
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  // ── Member actions ─────────────────────────────────────────
  async function invite() {
    if(user.id != wspOwner){showToast("Hanya owner yang bisa menambahkan member","error"); return}
    if (!inviteEmail) { showToast('Email wajib diisi', 'error'); return; }
    inviteLoading = true;
    try {
      await workspaceService.inviteMember(get(workspaceId), inviteEmail, inviteRole);
      showToast(`Undangan dikirim ke ${inviteEmail}`);
      showInviteModal = false; inviteEmail = '';
      await loadAll();
    } catch (e) { showToast(e.message, 'error'); }
    finally { inviteLoading = false; }
  }

  async function removeMember(id) {
    if (!confirm('Hapus anggota ini dari workspace?')) return;
    try {
      await workspaceService.removeMember(id);
      showToast('Anggota dihapus'); await loadAll();
    } catch (e) { showToast(e.message, 'error'); }
  }

  async function updateRole(memberId, role) {
    try {
      await workspaceService.updateMemberRole(memberId, role);
      showToast('Role diperbarui'); await loadAll();
    } catch (e) { showToast(e.message, 'error'); }
  }

  // ── Helpers ────────────────────────────────────────────────
  function roleColor(role) {
    return { admin: 'badge-blue', member: 'badge-green', viewer: 'badge-gray' }[role] || 'badge-gray';
  }
  function initials(email) { return email?.slice(0, 2).toUpperCase() || '??'; }
</script>

<svelte:head><title>Pengaturan — Dompet</title></svelte:head>
<Topbar title="Pengaturan" />

<div class="page-content" style="max-width:760px;">

  <!-- ── Profil ── -->
  <section class="settings-section">
    <h2 class="section-title">Profil</h2>
    <div class="card">
      <div class="card-body">
        <div style="display:flex;align-items:center;gap:14px;margin-bottom:16px;">
          <div class="avatar">{initials(user?.email)}</div>
          <div>
            <div style="font-size:15px;font-weight:700;">{user?.email}</div>
            <a href="/profile" style="font-size:12px;color:var(--primary);text-decoration:none;font-weight:500;">
              Kelola profil & keamanan →
            </a>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── Workspace Members ── -->
  <section class="settings-section">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;">
      <h2 class="section-title" style="margin:0;">Workspace: {$activeWorkspace?.name}</h2>
      <div style="display:flex;gap:6px;">
        <a href="/onboarding" class="btn btn-ghost btn-sm">+ Workspace</a>
        {#if (user?.id == wspOwner)}
          <button class="btn btn-ghost btn-sm" on:click={() => showInviteModal = true}>+ Undang</button>
        {/if}
      </div>
    </div>
    <div class="card">
      <div class="txn-list">
        {#each members as m}
          <div class="txn-item">
            <div class="avatar avatar-sm">{initials(m.email)}</div>
            <div class="txn-info">
              <div class="txn-name">{m.email}</div>
              <div class="txn-meta">{m.joined_at ? 'Bergabung' : 'Diundang'}</div>
            </div>
            <div style="display:flex;align-items:center;gap:8px;">
              {#if m.user_id === user?.id}
                <span class="badge {roleColor(m.role)}">{m.role}</span>
                <span style="font-size:12px;color:var(--text-3);">(Anda)</span>
              {:else}
                <select class="form-select" style="width:auto;font-size:12px;padding:4px 8px;"
                  value={m.role} on:change={e => updateRole(m.id, e.target.value)}>
                  {#each roles as r}<option value={r.value}>{r.label}</option>{/each}
                </select>
                  {#if (user?.id == wspOwner)}
                  <button class="btn btn-ghost btn-sm" style="color:var(--expense);"
                    on:click={() => removeMember(m.id)}>Hapus</button>
                  {/if}
              {/if}
            </div>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- ── Kategori ── -->
  <section class="settings-section">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;">
      <h2 class="section-title" style="margin:0;">Kategori</h2>
      <button class="btn btn-primary btn-sm" on:click={openAddCat}>+ Tambah Kategori</button>
    </div>

    <div class="card">
      <!-- Filter tabs + counter -->
      <div class="cat-toolbar">
        <div class="cat-tabs">
          {#each [['all','Semua'],['expense','Pengeluaran'],['income','Pemasukan']] as [val, label]}
            <button class="cat-tab" class:cat-tab--active={catFilter === val}
              on:click={() => catFilter = val}>
              {label}
              <span class="cat-tab-count">
                {val === 'all'
                  ? allCategories.length
                  : allCategories.filter(c => c.type === val).length}
              </span>
            </button>
          {/each}
        </div>
        <div style="font-size:11.5px;color:var(--text-3);">
          {customCategories.length} kustom · {defaultCategories.length} bawaan
        </div>
      </div>

      {#if loading.cats}
        <div class="empty-state" style="padding:32px;"><div class="spinner"></div></div>
      {:else}

        <!-- Kategori Kustom -->
        {#if visibleCustom.length > 0}
          <div class="cat-group-label">
            <span>Kustom ({visibleCustom.length})</span>
            <span class="cat-group-hint">Klik untuk edit</span>
          </div>
          {#each visibleCustom as cat}
            <div class="cat-row cat-row--custom" on:click={() => openEditCat(cat)}
              role="button" tabindex="0">
              <div class="cat-dot-wrap">
                <div class="cat-dot" style="background:{cat.color}"></div>
              </div>
              <div class="cat-info">
                <span class="cat-name">{cat.name}</span>
                <span class="cat-badge" class:cat-badge--expense={cat.type==='expense'}
                  class:cat-badge--income={cat.type==='income'}>
                  {cat.type === 'expense' ? 'Pengeluaran' : 'Pemasukan'}
                </span>
              </div>
              <div class="cat-actions">
                <button class="cat-edit-btn" on:click|stopPropagation={() => openEditCat(cat)}>✏️</button>
                <button class="cat-del-btn"  on:click|stopPropagation={() => deleteCategory(cat)}>🗑️</button>
              </div>
            </div>
          {/each}
        {:else if catFilter !== 'all' && customCategories.length > 0}
          <!-- ada kustom tapi disaring -->
        {:else if customCategories.length === 0}
          <div class="cat-empty">
            <span>🏷️</span>
            <span>Belum ada kategori kustom — klik <strong>+ Tambah</strong> untuk mulai</span>
          </div>
        {/if}

        <!-- Kategori Bawaan -->
        {#if visibleDefault.length > 0}
          <div class="cat-group-label" style="margin-top:{visibleCustom.length > 0 ? 4 : 0}px;">
            <span>Bawaan ({visibleDefault.length})</span>
            <span class="cat-group-hint">Tidak bisa diedit / dihapus</span>
          </div>
          <div class="cat-default-grid">
            {#each visibleDefault as cat}
              <div class="cat-default-chip"
                style="--chip-color:{cat.color};border-left:3px solid {cat.color};">
                <span class="cat-chip-dot" style="background:{cat.color}"></span>
                <span class="cat-chip-name">{cat.name}</span>
                <span class="cat-chip-type"
                  class:cat-badge--expense={cat.type==='expense'}
                  class:cat-badge--income={cat.type==='income'}>
                  {cat.type === 'expense' ? 'Keluar' : 'Masuk'}
                </span>
              </div>
            {/each}
          </div>
        {/if}

      {/if}
    </div>
  </section>

  <!-- ── Lainnya ── -->
  <section class="settings-section">
    <h2 class="section-title">Lainnya</h2>
    <div class="card">
      <div class="card-body">
        <div style="display:flex;align-items:center;justify-content:space-between;">
          <div>
            <div style="font-size:14px;font-weight:600;">Keluar dari akun</div>
            <div style="font-size:12px;color:var(--text-3);">Sesi Anda akan diakhiri</div>
          </div>
          <button class="btn btn-danger btn-sm"
            on:click={() => { auth.signOut(); goto('/auth/login'); }}>
            Keluar
          </button>
        </div>
      </div>
    </div>
  </section>
</div>

<!-- ── Invite Modal ── -->
<Modal title="Undang Anggota" open={showInviteModal} size="sm" on:close={() => showInviteModal = false}>
  <div style="display:flex;flex-direction:column;gap:14px;">
    <div class="form-group">
      <label class="form-label">Email *</label>
      <input type="email" class="form-input" placeholder="email@contoh.com" bind:value={inviteEmail} />
    </div>
    <div class="form-group">
      <label class="form-label">Role</label>
      <div style="display:flex;flex-direction:column;gap:8px;">
        {#each roles as r}
          <label style="display:flex;align-items:center;gap:10px;padding:10px;
            border:1.5px solid {inviteRole===r.value?'var(--primary)':'var(--border)'};
            border-radius:9px;cursor:pointer;
            background:{inviteRole===r.value?'var(--primary-light)':'white'}">
            <input type="radio" bind:group={inviteRole} value={r.value} style="accent-color:var(--primary);" />
            <div>
              <strong style="font-size:13.5px;">{r.label}</strong>
              <span style="font-size:12px;color:var(--text-3);margin-left:6px;">— {r.desc}</span>
            </div>
          </label>
        {/each}
      </div>
    </div>
    <button class="btn btn-primary btn-block" on:click={invite} disabled={inviteLoading}>
      {inviteLoading ? 'Mengirim...' : 'Kirim Undangan'}
    </button>
  </div>
</Modal>

<!-- ── Add / Edit Category Modal ── -->
<Modal
  title={editingCat ? `Edit: ${editingCat.name}` : 'Tambah Kategori Kustom'}
  open={showCatModal}
  size="sm"
  on:close={() => showCatModal = false}
>
  <div style="display:flex;flex-direction:column;gap:16px;">

    <!-- Nama -->
    <div class="form-group">
      <label class="form-label">Nama Kategori *</label>
      <input type="text" class="form-input" placeholder="cth. Hewan Peliharaan"
        bind:value={catName} maxlength="40"
        on:keydown={e => e.key === 'Enter' && saveCategory()} />
      <!-- Live duplicate warning -->
      {#if catName.trim() && isDuplicate(catName, catType, editingCat?.id)}
        <div class="dup-warning">
          ⚠️ Kategori "{catName.trim()}" sudah ada untuk tipe {catType === 'expense' ? 'pengeluaran' : 'pemasukan'}
        </div>
      {/if}
    </div>

    <!-- Tipe (hanya saat tambah baru, tidak bisa diubah saat edit) -->
    {#if !editingCat}
      <div class="form-group">
        <label class="form-label">Tipe *</label>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">
          <button class="type-toggle"
            class:type-toggle--expense={catType === 'expense'}
            on:click={() => catType = 'expense'}>
            <span>📤</span> Pengeluaran
          </button>
          <button class="type-toggle"
            class:type-toggle--income={catType === 'income'}
            on:click={() => catType = 'income'}>
            <span>📥</span> Pemasukan
          </button>
        </div>
      </div>
    {:else}
      <!-- Readonly tipe saat edit -->
      <div class="form-group">
        <label class="form-label">Tipe</label>
        <div class="type-readonly" class:type-readonly--expense={editingCat.type==='expense'}
          class:type-readonly--income={editingCat.type==='income'}>
          {editingCat.type === 'expense' ? '📤 Pengeluaran' : '📥 Pemasukan'}
          <span style="font-size:11px;opacity:.7;">— tidak bisa diubah</span>
        </div>
      </div>
    {/if}

    <!-- Warna -->
    <div class="form-group">
      <label class="form-label">Warna</label>
      <div class="color-picker">
        {#each catColors as c}
          <button class="color-btn"
            style="background:{c}"
            class:color-btn--active={catColor === c}
            on:click={() => catColor = c}
            aria-label={c}>
            {#if catColor === c}<span class="color-check">✓</span>{/if}
          </button>
        {/each}
        <!-- Preview -->
        <div class="color-preview" style="background:{catColor}20;border-left:3px solid {catColor};">
          <div class="cat-dot" style="background:{catColor};width:10px;height:10px;"></div>
          <span style="font-size:12px;font-weight:600;color:{catColor};">{catName || 'Preview'}</span>
        </div>
      </div>
    </div>

    <button class="btn btn-primary btn-block" on:click={saveCategory}
      disabled={catLoading || (catName.trim() && isDuplicate(catName, catType, editingCat?.id))}>
      {catLoading ? 'Menyimpan...' : (editingCat ? 'Perbarui Kategori' : 'Tambah Kategori')}
    </button>
  </div>
</Modal>

<style>
  .settings-section { margin-bottom: 24px; }
  .section-title { font-size: 14px; font-weight: 700; color: var(--text-2); margin-bottom: 12px; }

  .avatar {
    width: 40px; height: 40px;
    background: var(--primary-light); color: var(--primary);
    border-radius: 50%; display: flex; align-items: center;
    justify-content: center; font-size: 14px; font-weight: 700;
  }
  .avatar-sm { width: 34px; height: 34px; font-size: 12px; }

  /* ── Category toolbar ── */
  .cat-toolbar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 14px; border-bottom: 1px solid var(--border);
    flex-wrap: wrap; gap: 8px;
  }
  .cat-tabs { display: flex; gap: 4px; }
  .cat-tab {
    display: flex; align-items: center; gap: 5px;
    padding: 5px 10px; border-radius: 7px; border: none;
    background: transparent; font-size: 12.5px; font-weight: 500;
    color: var(--text-3); cursor: pointer; font-family: inherit;
    transition: all .15s;
  }
  .cat-tab:hover { background: var(--bg); color: var(--text); }
  .cat-tab--active { background: var(--bg); color: var(--text); font-weight: 700; }
  .cat-tab-count {
    font-size: 10.5px; font-weight: 700;
    background: var(--border); color: var(--text-3);
    padding: 1px 6px; border-radius: 99px;
  }
  .cat-tab--active .cat-tab-count { background: var(--primary); color: white; }

  /* ── Category group label ── */
  .cat-group-label {
    display: flex; justify-content: space-between; align-items: center;
    padding: 8px 14px 5px;
    font-size: 10.5px; font-weight: 700; color: var(--text-3);
    text-transform: uppercase; letter-spacing: .05em;
    background: #FAFBFC; border-bottom: 1px solid var(--border);
  }
  .cat-group-hint { font-size: 10px; font-weight: 500; color: var(--text-3); text-transform: none; letter-spacing: 0; }

  /* ── Custom category rows ── */
  .cat-row {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 14px; border-bottom: 1px solid var(--border);
    transition: background .1s;
  }
  .cat-row:last-of-type { border-bottom: none; }
  .cat-row--custom { cursor: pointer; }
  .cat-row--custom:hover { background: #FAFBFC; }

  .cat-dot-wrap { width: 14px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .cat-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }

  .cat-info { flex: 1; display: flex; align-items: center; gap: 8px; min-width: 0; }
  .cat-name { font-size: 13.5px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .cat-badge {
    font-size: 10.5px; font-weight: 600; padding: 2px 7px; border-radius: 99px;
    white-space: nowrap; flex-shrink: 0;
  }
  .cat-badge--expense { background: #FEE2E2; color: #B91C1C; }
  .cat-badge--income  { background: #DCFCE7; color: #15803D; }

  .cat-actions { display: flex; gap: 4px; flex-shrink: 0; }
  .cat-edit-btn, .cat-del-btn {
    width: 28px; height: 28px; border: none; background: transparent;
    border-radius: 6px; cursor: pointer; font-size: 13px;
    display: flex; align-items: center; justify-content: center;
    transition: background .15s;
  }
  .cat-edit-btn:hover { background: #EFF6FF; }
  .cat-del-btn:hover  { background: #FEF2F2; }

  /* ── Empty custom ── */
  .cat-empty {
    display: flex; align-items: center; gap: 8px;
    padding: 14px 14px; font-size: 13px; color: var(--text-3);
    border-bottom: 1px solid var(--border);
  }

  /* ── Default categories grid ── */
  .cat-default-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 1px;
    background: var(--border);
  }
  .cat-default-chip {
    display: flex; align-items: center; gap: 8px;
    padding: 9px 12px;
    background: white;
    transition: background .1s;
  }
  .cat-default-chip:hover { background: #FAFBFC; }
  .cat-chip-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .cat-chip-name { font-size: 12.5px; font-weight: 500; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .cat-chip-type {
    font-size: 10px; font-weight: 600; padding: 1px 6px; border-radius: 99px; flex-shrink: 0;
  }

  /* ── Duplicate warning ── */
  .dup-warning {
    font-size: 12px; color: var(--expense);
    background: #FEF2F2; border: 1px solid #FECACA;
    border-radius: 7px; padding: 7px 10px; margin-top: 4px;
  }

  /* ── Type toggle buttons ── */
  .type-toggle {
    display: flex; align-items: center; justify-content: center; gap: 6px;
    padding: 9px; border-radius: 9px; border: 1.5px solid var(--border);
    background: transparent; font-size: 13px; font-weight: 600;
    color: var(--text-2); cursor: pointer; font-family: inherit;
    transition: all .15s;
  }
  .type-toggle:hover { background: var(--bg); }
  .type-toggle--expense { border-color: var(--expense); background: #FEF2F2; color: var(--expense); }
  .type-toggle--income  { border-color: var(--income);  background: #F0FDF4; color: var(--income);  }

  /* ── Readonly type ── */
  .type-readonly {
    padding: 9px 12px; border-radius: 9px; font-size: 13px; font-weight: 600;
    display: flex; align-items: center; gap: 8px;
  }
  .type-readonly--expense { background: #FEF2F2; color: var(--expense); }
  .type-readonly--income  { background: #F0FDF4; color: var(--income);  }

  /* ── Color picker ── */
  .color-picker { display: flex; flex-wrap: wrap; gap: 7px; align-items: center; }
  .color-btn {
    width: 26px; height: 26px; border-radius: 50%; border: none;
    cursor: pointer; position: relative; transition: transform .15s;
    display: flex; align-items: center; justify-content: center;
  }
  .color-btn:hover { transform: scale(1.2); }
  .color-btn--active { outline: 3px solid currentColor; outline-offset: 2px; }
  .color-check { color: white; font-size: 12px; font-weight: 700; line-height: 1; }
  .color-preview {
    display: flex; align-items: center; gap: 6px;
    padding: 5px 10px; border-radius: 7px; margin-left: 4px;
    flex: 1; min-width: 80px;
  }
</style>
