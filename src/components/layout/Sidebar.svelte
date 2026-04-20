<!-- src/components/layout/Sidebar.svelte -->
<script>
  import { page } from '$app/stores';
  import { activeWorkspace, workspaces, sidebarOpen, setWorkspace, displayName, avatarColor } from '$lib/stores';
  import { authService } from '$lib/services/auth.service';
  import { goto } from '$app/navigation';

  const navGroups = [
    {
      label: 'Utama',
      items: [
        { href: '/dashboard',    icon: 'grid',         label: 'Dashboard'        },
        { href: '/transactions', icon: 'list',          label: 'Transaksi'        },
        { href: '/budgets',      icon: 'pie-chart',     label: 'Anggaran'         },
        { href: '/savings',      icon: 'target',        label: 'Tabungan Rencana' },
      ]
    },
    {
      label: 'Aset',
      items: [
        { href: '/wallets', icon: 'credit-card', label: 'Dompet' },
      ]
    },
    {
      label: 'Akun',
      items: [
        { href: '/settings', icon: 'settings', label: 'Pengaturan'        },
        { href: '/profile',  icon: 'user',     label: 'Profil & Keamanan' },
      ]
    }
  ];

  const p = {
    grid:         `<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>`,
    list:         `<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>`,
    'pie-chart':  `<path d="M21.21 15.89A10 10 0 118 2.83"/><path d="M22 12A10 10 0 0012 2v10z"/>`,
    target:       `<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>`,
    'credit-card':`<rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/>`,
    settings:     `<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/>`,
    user:         `<path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/>`,
    logout:       `<path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>`,
    plus:         `<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>`,
  };

  function isActive(href) { return $page.url.pathname.startsWith(href); }
  function closeSidebar() { sidebarOpen.set(false); }

  $: initials = $displayName
    ? $displayName.trim().split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : '??';

  async function handleSignOut() {
    await authService.signOut();
    goto('/auth/login');
  }

  function goToNewWorkspace() {
    closeSidebar();
    goto('/onboarding');
  }
</script>

{#if $sidebarOpen}
  <div class="overlay" on:click={closeSidebar} role="presentation"></div>
{/if}

<aside class="sidebar" class:sidebar--open={$sidebarOpen}>
  <div class="logo-wrap">
    <div class="logo-icon">💰</div>
    <span class="logo-text">Dompet</span>
  </div>

  <!-- Workspace selector + tambah -->
  <div class="ws-section">
    <div class="ws-label-row">
      <span class="ws-label">Workspace</span>
      <button class="ws-add-btn" on:click={goToNewWorkspace} title="Buat workspace baru">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
          {@html p.plus}
        </svg>
      </button>
    </div>
    {#if $workspaces.length > 1}
      <select class="ws-select"
        value={$activeWorkspace?.id}
        on:change={e => { const ws = $workspaces.find(w => w.id === e.target.value); if (ws) setWorkspace(ws); }}>
        {#each $workspaces as ws}
          <option value={ws.id}>{ws.name}</option>
        {/each}
      </select>
    {:else if $workspaces.length === 1}
      <div class="ws-name">{$activeWorkspace?.name || $workspaces[0].name}</div>
    {/if}
  </div>

  <nav class="nav">
    {#each navGroups as group}
      <div class="nav-group-label">{group.label}</div>
      {#each group.items as item}
        <a href={item.href} class="nav-item" class:nav-item--active={isActive(item.href)} on:click={closeSidebar}>
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
            {@html p[item.icon]}
          </svg>
          <span>{item.label}</span>
        </a>
      {/each}
    {/each}
  </nav>

  <div class="sidebar-footer">
    <a href="/profile" class="user-chip" on:click={closeSidebar}>
      <div class="user-av" style="background:{$avatarColor}">{initials}</div>
      <div class="user-info">
        <div class="user-name">{$displayName}</div>
        <div class="user-role">{$activeWorkspace?.role || 'member'}</div>
      </div>
    </a>
    <button class="logout-btn" on:click={handleSignOut} title="Keluar">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px;">
        {@html p.logout}
      </svg>
    </button>
  </div>
</aside>

<style>
  .overlay { position:fixed;inset:0;background:rgba(15,23,42,.4);z-index:49;display:none; }
  @media (max-width:767px) { .overlay { display:block; } }

  .sidebar {
    position:fixed;left:0;top:0;bottom:0;width:var(--sidebar-w,224px);
    background:white;border-right:1px solid var(--border);
    display:flex;flex-direction:column;z-index:50;
    transform:translateX(-100%);transition:transform .25s ease;
  }
  @media (min-width:768px) { .sidebar { transform:none; } }
  .sidebar--open { transform:none; }

  .logo-wrap { display:flex;align-items:center;gap:8px;padding:16px 14px 10px; }
  .logo-icon {
    width:28px;height:28px;background:linear-gradient(135deg,#0EA5E9,#38BDF8);
    border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:14px;
  }
  .logo-text { font-size:16px;font-weight:700;letter-spacing:-.03em; }

  /* Workspace section */
  .ws-section { margin:0 10px 6px;padding:8px 10px;background:#F8FAFC;border:1px solid var(--border);border-radius:9px; }
  .ws-label-row { display:flex;align-items:center;justify-content:space-between;margin-bottom:4px; }
  .ws-label { font-size:10px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.06em; }
  .ws-add-btn {
    width:20px;height:20px;border:none;background:transparent;
    cursor:pointer;color:var(--primary);padding:0;
    display:flex;align-items:center;justify-content:center;
    border-radius:4px;transition:background .15s;
  }
  .ws-add-btn:hover { background:#E0F2FE; }
  .ws-add-btn svg { width:14px;height:14px; }
  .ws-select {
    width:100%;background:transparent;border:none;
    font-size:12.5px;font-weight:600;color:var(--text);
    outline:none;cursor:pointer;padding:0;
  }
  .ws-name { font-size:12.5px;font-weight:600;color:var(--text); }

  .nav { flex:1;padding:4px 8px;overflow-y:auto; }
  .nav-group-label { font-size:10px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.07em;padding:10px 8px 4px; }
  .nav-item {
    display:flex;align-items:center;gap:9px;padding:8px 10px;border-radius:8px;
    font-size:13px;font-weight:500;color:var(--text-2);text-decoration:none;
    transition:all .15s;margin-bottom:1px;
  }
  .nav-item:hover { background:#F1F5F9;color:var(--text); }
  .nav-item--active { background:#E0F2FE;color:var(--primary);font-weight:600; }
  .nav-icon { width:15px;height:15px;flex-shrink:0;opacity:.7; }
  .nav-item--active .nav-icon { opacity:1; }

  .sidebar-footer { padding:8px;border-top:1px solid var(--border);display:flex;align-items:center;gap:6px; }
  .user-chip {
    display:flex;align-items:center;gap:8px;flex:1;
    padding:7px 8px;border-radius:8px;text-decoration:none;transition:background .15s;min-width:0;
  }
  .user-chip:hover { background:var(--bg); }
  .user-av {
    width:30px;height:30px;border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    font-size:11px;font-weight:700;color:white;flex-shrink:0;
  }
  .user-info { min-width:0; }
  .user-name { font-size:12.5px;font-weight:600;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis; }
  .user-role { font-size:11px;color:var(--text-3);text-transform:capitalize; }
  .logout-btn {
    width:32px;height:32px;display:flex;align-items:center;justify-content:center;
    border:none;background:transparent;border-radius:7px;cursor:pointer;
    color:var(--text-3);transition:all .15s;flex-shrink:0;
  }
  .logout-btn:hover { background:#FEF2F2;color:var(--expense); }
</style>
