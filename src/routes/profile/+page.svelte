<!-- src/routes/profile/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authService } from '$lib/services/auth.service';
  import { showToast, user } from '$lib/stores';
  import Topbar from '../../components/layout/Topbar.svelte';

  let authUser = null;
  let profile = null;
  let loading = true;
  let section = 'profile'; // profile | password | email | security

  // Profile form
  let displayName = '';
  let avatarColor = '#0EA5E9';
  let profileLoading = false;

  // Password form
  let newPassword = '';
  let confirmPassword = '';
  let passwordLoading = false;
  let pwStrength = 0;

  // Email forms
  let resetEmail = '';
  let resetLoading = false;
  let resetSent = false;
  let resendLoading = false;
  let resendSent = false;

  const avatarColors = [
    '#0EA5E9','#16A34A','#8B5CF6','#F97316',
    '#EC4899','#EF4444','#F59E0B','#06B6D4','#64748B'
  ];

  onMount(async () => {
    authUser = await authService.getUser();
    if (!authUser) { goto('/auth/login'); return; }
    profile = await authService.getProfile();
    displayName = profile?.display_name || '';
    avatarColor = profile?.avatar_color || '#0EA5E9';
    resetEmail = authUser.email || '';
    loading = false;
  });

  // Password strength
  $: {
    let s = 0;
    if (newPassword.length >= 8) s++;
    if (/[A-Z]/.test(newPassword)) s++;
    if (/[0-9]/.test(newPassword)) s++;
    if (/[^A-Za-z0-9]/.test(newPassword)) s++;
    pwStrength = s;
  }

  const strengthMeta = [
    { label: '',              color: 'var(--border)'  },
    { label: 'Lemah',         color: '#DC2626'        },
    { label: 'Cukup',         color: '#F59E0B'        },
    { label: 'Kuat',          color: '#16A34A'        },
    { label: 'Sangat Kuat',   color: '#0EA5E9'        },
  ];

  function initials(name, email) {
    if (name?.trim()) return name.trim().slice(0, 2).toUpperCase();
    return (email || '??').slice(0, 2).toUpperCase();
  }

  function displayLabel(name, email) {
    return name?.trim() || email || 'Pengguna';
  }

  async function saveProfile() {
    profileLoading = true;
    try {
      await authService.upsertProfile(displayName.trim() || null, avatarColor);
      profile = { ...profile, display_name: displayName.trim(), avatar_color: avatarColor };
      showToast('Profil berhasil disimpan!');
    } catch (e) { showToast(e.message, 'error'); }
    finally { profileLoading = false; }
  }

  async function changePassword() {
    if (!newPassword) { showToast('Password baru wajib diisi', 'error'); return; }
    if (newPassword.length < 8) { showToast('Minimal 8 karakter', 'error'); return; }
    if (newPassword !== confirmPassword) { showToast('Konfirmasi tidak cocok', 'error'); return; }
    passwordLoading = true;
    try {
      await authService.changePassword(newPassword);
      showToast('Password berhasil diubah!');
      newPassword = ''; confirmPassword = '';
    } catch (e) { showToast(e.message, 'error'); }
    finally { passwordLoading = false; }
  }

  async function sendResetLink() {
    if (!resetEmail) { showToast('Email wajib diisi', 'error'); return; }
    resetLoading = true;
    try {
      await authService.sendPasswordReset(resetEmail);
      resetSent = true; showToast('Link reset terkirim!');
    } catch (e) { showToast(e.message, 'error'); }
    finally { resetLoading = false; }
  }

  async function resendConfirmation() {
    resendLoading = true;
    try {
      await authService.resendConfirmation(authUser.email);
      resendSent = true; showToast('Email konfirmasi terkirim!');
    } catch (e) { showToast(e.message, 'error'); }
    finally { resendLoading = false; }
  }

  async function signOut() {
    await authService.signOut();
    goto('/auth/login');
  }
</script>

<svelte:head><title>Profil & Keamanan — Dompet</title></svelte:head>
<Topbar title="Profil & Keamanan" />

<div class="page-content">
{#if loading}
  <div class="empty-state"><div class="spinner"></div></div>
{:else}
<div class="layout">

  <!-- LEFT sidebar nav -->
  <aside class="prof-nav">
    <!-- Avatar -->
    <div class="avatar-block">
      <div class="avatar-circle" style="background:{profile?.avatar_color||avatarColor}">
        {initials(profile?.display_name, authUser?.email)}
      </div>
      <div class="avatar-name">{displayLabel(profile?.display_name, authUser?.email)}</div>
      <div class="avatar-email">{authUser?.email}</div>
      {#if authUser?.email_confirmed_at}
        <span class="badge badge-green" style="margin-top:6px;">✓ Terverifikasi</span>
      {:else}
        <span class="badge badge-amber" style="margin-top:6px;">⚠ Belum terverifikasi</span>
      {/if}
    </div>

    <nav class="tab-list">
      {#each [
        { id:'profile',  emoji:'👤', label:'Profil'           },
        { id:'password', emoji:'🔒', label:'Ubah Password'    },
        { id:'email',    emoji:'📧', label:'Verifikasi Email'  },
        { id:'security', emoji:'🛡️', label:'Keamanan'         },
      ] as t}
        <button class="tab-btn" class:active={section===t.id} on:click={() => section=t.id}>
          <span>{t.emoji}</span> <span>{t.label}</span>
        </button>
      {/each}
    </nav>
  </aside>

  <!-- RIGHT content -->
  <div class="prof-content">

    <!-- ── PROFIL ── -->
    {#if section === 'profile'}
      <div class="sec-card">
        <div class="sec-head"><h2>Informasi Profil</h2></div>
        <div class="sec-body">

          <!-- Avatar color picker -->
          <div class="form-group">
            <label class="form-label">Warna Avatar</label>
            <div class="color-row">
              {#each avatarColors as c}
                <button
                  class="color-swatch"
                  style="background:{c};outline:{avatarColor===c?'3px solid '+c+';outline-offset:3px':''}"
                  on:click={() => avatarColor = c}
                >
                  {#if avatarColor === c}<span class="color-check">✓</span>{/if}
                </button>
              {/each}
              <!-- Preview -->
              <div class="avatar-preview" style="background:{avatarColor}">
                {initials(displayName, authUser?.email)}
              </div>
            </div>
          </div>

          <!-- Display name -->
          <div class="form-group">
            <label class="form-label">Nama Tampilan</label>
            <input type="text" class="form-input" placeholder="cth. Budi Santoso"
              bind:value={displayName} maxlength="50" />
            <span style="font-size:11.5px;color:var(--text-3);">
              Tampil di sidebar dan workspace. Kosongkan untuk pakai email.
            </span>
          </div>

          <!-- Email (read-only) -->
          <div class="form-group">
            <label class="form-label">Email</label>
            <input type="email" class="form-input" value={authUser?.email||''} disabled />
          </div>

          <!-- Info rows -->
          <div class="info-table">
            <div class="info-row">
              <span class="info-k">Bergabung</span>
              <span class="info-v">{authUser?.created_at ? new Date(authUser.created_at).toLocaleDateString('id-ID',{day:'numeric',month:'long',year:'numeric'}) : '-'}</span>
            </div>
            <div class="info-row">
              <span class="info-k">Login Terakhir</span>
              <span class="info-v">{authUser?.last_sign_in_at ? new Date(authUser.last_sign_in_at).toLocaleDateString('id-ID',{day:'numeric',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}) : '-'}</span>
            </div>
          </div>

          <button class="btn btn-primary" on:click={saveProfile} disabled={profileLoading}>
            {profileLoading ? 'Menyimpan...' : '💾 Simpan Profil'}
          </button>
        </div>
      </div>

    <!-- ── PASSWORD ── -->
    {:else if section === 'password'}
      <div class="sec-card">
        <div class="sec-head">
          <h2>Ubah Password</h2>
          <p>Password minimal 8 karakter.</p>
        </div>
        <div class="sec-body">
          <div class="form-group">
            <label class="form-label">Password Baru *</label>
            <input type="password" class="form-input" placeholder="Minimal 8 karakter"
              bind:value={newPassword} autocomplete="new-password" />
            {#if newPassword}
              <div class="strength-wrap">
                <div class="strength-bars">
                  {#each Array(4) as _, i}
                    <div class="strength-bar" style="background:{i<pwStrength ? strengthMeta[pwStrength].color : 'var(--border)'}"></div>
                  {/each}
                </div>
                <span class="strength-text" style="color:{strengthMeta[pwStrength].color}">
                  {strengthMeta[pwStrength].label}
                </span>
              </div>
              <div class="hints">
                <span class:ok={newPassword.length>=8}>✓ Min. 8 karakter</span>
                <span class:ok={/[A-Z]/.test(newPassword)}>✓ Huruf kapital</span>
                <span class:ok={/[0-9]/.test(newPassword)}>✓ Angka</span>
                <span class:ok={/[^A-Za-z0-9]/.test(newPassword)}>✓ Karakter khusus</span>
              </div>
            {/if}
          </div>

          <div class="form-group">
            <label class="form-label">Konfirmasi Password *</label>
            <input type="password" class="form-input"
              placeholder="Ulangi password baru"
              bind:value={confirmPassword} autocomplete="new-password"
              style={confirmPassword && confirmPassword!==newPassword ? 'border-color:var(--expense)' : ''} />
            {#if confirmPassword && confirmPassword !== newPassword}
              <span style="font-size:12px;color:var(--expense);">Password tidak cocok</span>
            {/if}
          </div>

          <button class="btn btn-primary" on:click={changePassword} disabled={passwordLoading}>
            {passwordLoading ? 'Memproses...' : '🔒 Ubah Password'}
          </button>
        </div>
      </div>

      <!-- Reset via link -->
      <div class="sec-card" style="margin-top:16px;">
        <div class="sec-head">
          <h2>Reset Password via Link Email</h2>
          <p>Link berlaku <strong>1 jam</strong> dan hanya bisa dipakai sekali.</p>
        </div>
        <div class="sec-body">
          {#if resetSent}
            <div class="banner banner-success">
              <span>📧</span>
              <div><strong>Link terkirim!</strong><br><small>Cek inbox {resetEmail} — link berlaku 1 jam.</small></div>
            </div>
            <button class="btn btn-ghost btn-sm" style="margin-top:10px;" on:click={() => resetSent=false}>Kirim Ulang</button>
          {:else}
            <div class="form-group">
              <label class="form-label">Email</label>
              <input type="email" class="form-input" bind:value={resetEmail} />
            </div>
            <button class="btn btn-ghost" on:click={sendResetLink} disabled={resetLoading}>
              {resetLoading ? 'Mengirim...' : '📧 Kirim Link Reset'}
            </button>
          {/if}
        </div>
      </div>

    <!-- ── EMAIL VERIFIKASI ── -->
    {:else if section === 'email'}
      <div class="sec-card">
        <div class="sec-head"><h2>Verifikasi Email</h2></div>
        <div class="sec-body">
          {#if authUser?.email_confirmed_at}
            <div class="banner banner-success">
              <span>✅</span>
              <div>
                <strong>Email sudah terverifikasi</strong><br>
                <small>Diverifikasi {new Date(authUser.email_confirmed_at).toLocaleDateString('id-ID',{day:'numeric',month:'long',year:'numeric'})}</small>
              </div>
            </div>
          {:else}
            <div class="banner banner-warning">
              <span>⚠️</span>
              <div><strong>Email belum terverifikasi</strong><br><small>Verifikasi untuk keamanan akun.</small></div>
            </div>

            {#if resendSent}
              <div class="banner banner-success" style="margin-top:12px;">
                <span>📧</span>
                <div><strong>Email konfirmasi terkirim!</strong><br><small>Cek inbox dan klik link di dalamnya. Berlaku 24 jam.</small></div>
              </div>
            {:else}
              <button class="btn btn-primary" style="margin-top:12px;" on:click={resendConfirmation} disabled={resendLoading}>
                {resendLoading ? 'Mengirim...' : '📧 Kirim Ulang Konfirmasi'}
              </button>
            {/if}
          {/if}

          <div class="info-box">
            <strong>ℹ️ Info link email</strong>
            <ul>
              <li>Konfirmasi email berlaku <strong>24 jam</strong></li>
              <li>Reset password berlaku <strong>1 jam</strong></li>
              <li>Setiap link hanya bisa dipakai <strong>sekali</strong></li>
              <li>Cek folder <strong>Spam/Junk</strong> jika tidak ada di inbox</li>
            </ul>
          </div>
        </div>
      </div>

    <!-- ── KEAMANAN ── -->
    {:else if section === 'security'}
      <div class="sec-card">
        <div class="sec-head"><h2>Sesi Aktif</h2></div>
        <div class="sec-body">
          <div class="session-row">
            <div class="session-icon">💻</div>
            <div>
              <div style="font-size:14px;font-weight:600;">Sesi Saat Ini</div>
              <div style="font-size:12px;color:var(--text-3);">Browser · {new Date().toLocaleDateString('id-ID',{day:'numeric',month:'long',year:'numeric'})}</div>
            </div>
            <span class="badge badge-green">Aktif</span>
          </div>
        </div>
      </div>

      <div class="sec-card danger" style="margin-top:16px;">
        <div class="sec-head"><h2 style="color:var(--expense)">Zona Berbahaya</h2></div>
        <div class="sec-body">
          <div class="danger-row">
            <div>
              <div style="font-size:14px;font-weight:600;">Keluar dari Semua Perangkat</div>
              <div style="font-size:12px;color:var(--text-3);">Akhiri semua sesi aktif</div>
            </div>
            <button class="btn btn-danger btn-sm" on:click={signOut}>Keluar</button>
          </div>
        </div>
      </div>
    {/if}

  </div><!-- /prof-content -->
</div><!-- /layout -->
{/if}
</div>

<style>
  .layout { display:grid;grid-template-columns:220px 1fr;gap:20px;align-items:start; }
  @media (max-width:768px) { .layout { grid-template-columns:1fr; } }

  /* LEFT NAV */
  .prof-nav { background:var(--card);border:1px solid var(--border);border-radius:14px;overflow:hidden;position:sticky;top:72px; }
  .avatar-block { padding:20px 14px 14px;text-align:center;border-bottom:1px solid var(--border); }
  .avatar-circle { width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:700;color:white;margin:0 auto 8px; }
  .avatar-name { font-size:13.5px;font-weight:700;color:var(--text); }
  .avatar-email { font-size:11.5px;color:var(--text-3);word-break:break-all;margin-top:2px; }

  .tab-list { padding:8px; }
  .tab-btn { display:flex;align-items:center;gap:9px;width:100%;padding:8px 10px;border-radius:8px;border:none;background:transparent;font-size:13px;font-weight:500;color:var(--text-2);cursor:pointer;font-family:inherit;transition:all .15s;text-align:left;margin-bottom:2px; }
  .tab-btn:hover { background:var(--bg); }
  .tab-btn.active { background:#E0F2FE;color:var(--primary);font-weight:600; }

  /* RIGHT CONTENT */
  .prof-content { display:flex;flex-direction:column; }
  .sec-card { background:var(--card);border:1px solid var(--border);border-radius:14px;overflow:hidden; }
  .sec-card.danger { border-color:#FECACA; }
  .sec-head { padding:14px 18px;border-bottom:1px solid var(--border); }
  .sec-head h2 { font-size:14.5px;font-weight:700; }
  .sec-head p { font-size:12.5px;color:var(--text-3);margin-top:3px;line-height:1.5; }
  .sec-body { padding:18px;display:flex;flex-direction:column;gap:14px; }

  /* Avatar color picker */
  .color-row { display:flex;align-items:center;gap:8px;flex-wrap:wrap; }
  .color-swatch { width:30px;height:30px;border-radius:50%;border:none;cursor:pointer;position:relative;transition:transform .15s;display:flex;align-items:center;justify-content:center; }
  .color-swatch:hover { transform:scale(1.15); }
  .color-check { color:white;font-size:13px;font-weight:700;line-height:1; }
  .avatar-preview { width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;color:white;margin-left:8px;border:2px solid var(--border); }

  /* Info table */
  .info-table { display:flex;flex-direction:column; }
  .info-row { display:flex;justify-content:space-between;align-items:center;padding:9px 0;border-bottom:1px solid var(--border); }
  .info-row:last-child { border:none; }
  .info-k { font-size:12.5px;color:var(--text-3); }
  .info-v { font-size:13px;font-weight:500;text-align:right; }

  /* Password strength */
  .strength-wrap { display:flex;align-items:center;gap:8px;margin-top:8px; }
  .strength-bars { display:flex;gap:4px;flex:1; }
  .strength-bar { flex:1;height:4px;border-radius:99px;transition:background .25s; }
  .strength-text { font-size:12px;font-weight:600;min-width:70px; }

  .hints { display:flex;flex-wrap:wrap;gap:6px;margin-top:6px; }
  .hints span { font-size:11.5px;color:var(--text-3);padding:3px 8px;background:var(--bg);border-radius:6px;transition:all .2s; }
  .hints .ok { color:var(--income);background:#DCFCE7; }

  /* Banners */
  .banner { display:flex;align-items:center;gap:12px;padding:14px;border-radius:10px;font-size:13.5px; }
  .banner span { font-size:22px;flex-shrink:0; }
  .banner-success { background:#F0FDF4;border:1px solid #BBF7D0; }
  .banner-warning { background:#FFFBEB;border:1px solid #FDE68A; }

  .info-box { background:var(--bg);border-radius:10px;padding:13px;font-size:13px;color:var(--text-2); }
  .info-box ul { margin:8px 0 0 16px;display:flex;flex-direction:column;gap:5px; }

  /* Session & danger */
  .session-row { display:flex;align-items:center;gap:12px; }
  .session-icon { width:40px;height:40px;background:var(--bg);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px; }
  .danger-row { display:flex;align-items:center;justify-content:space-between;padding:12px;background:#FFF5F5;border-radius:10px;border:1px solid #FEE2E2; }
</style>
