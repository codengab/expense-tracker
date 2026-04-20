<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';
  import { authService } from '$lib/services/auth.service';
  import { user, userProfile, isLoading, workspaces, activeWorkspace, loadStoredWorkspace } from '$lib/stores';
  import { workspaceService } from '$lib/services/workspace.service';
  import Sidebar from '../components/layout/Sidebar.svelte';
  import Toast from '../components/ui/Toast.svelte';

  $: isAuthPage   = $page.url.pathname.startsWith('/auth');
  $: isOnboarding = $page.url.pathname === '/onboarding';

  onMount(async () => {
    // ── getSession() membaca token dari localStorage secara sinkron ──
    const { data: { session } } = await supabase.auth.getSession();

    if (session?.user) {
      user.set(session.user);
      const wsList = await loadAppData();
      if ($page.url.pathname === '/' || isAuthPage) {
        goto(wsList.length === 0 ? '/onboarding' : '/dashboard', { replaceState: true });
      }
    } else {
      if (!isAuthPage) goto('/auth/login', { replaceState: true });
    }

    // Set false SETELAH semua data siap — mencegah halaman render
    // sebelum workspaceId tersedia, yang menyebabkan spinner infinite
    isLoading.set(false);

    // Subscribe perubahan auth (login baru, logout, token expire+refresh)
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      // INITIAL_SESSION sudah ditangani oleh getSession() di atas — skip
      if (event === 'INITIAL_SESSION') return;

      // TOKEN_REFRESHED: token baru, user tetap sama → tidak perlu reload data
      if (event === 'TOKEN_REFRESHED') {
        user.set(session?.user ?? null);
        return;
      }

      user.set(session?.user ?? null);

      if (session?.user) {
        const wsList = await loadAppData();
        if (isAuthPage) goto(wsList.length === 0 ? '/onboarding' : '/dashboard');
      } else {
        // Logout atau session expired
        userProfile.set(null);
        workspaces.set([]);
        activeWorkspace.set(null);
        goto('/auth/login');
      }
    });

    return () => subscription.unsubscribe();
  });

  async function loadAppData() {
    const [profile, wsList] = await Promise.all([
      authService.getProfile().catch(() => null),
      workspaceService.getUserWorkspaces().catch(() => []),
    ]);
    userProfile.set(profile);
    workspaces.set(wsList);
    loadStoredWorkspace(wsList);
    return wsList;
  }
</script>

{#if $isLoading}
  <div class="init-loader">
    <div class="init-logo">💰</div>
    <div class="init-spinner"></div>
  </div>
{:else if isAuthPage}
  <slot />
{:else if isOnboarding}
  {#if $user}<slot />{/if}
{:else if $user}
  <div class="app-shell">
    <Sidebar />
    <div class="main-content"><slot /></div>
  </div>
{:else}
  <!-- user null tapi bukan auth page: sedang redirect ke login -->
  <!-- Tampilkan blank bukan spinner agar tidak flicker -->
{/if}

<Toast />

<style>
  .init-loader {
    display: flex; flex-direction: column; align-items: center;
    justify-content: center; gap: 20px; min-height: 100vh; background: var(--bg, #F1F5F9);
  }
  .init-logo { font-size: 40px; animation: logo-pulse 1.4s ease-in-out infinite; }
  .init-spinner {
    width: 24px; height: 24px; border: 2.5px solid #E2E8F0;
    border-top-color: #0EA5E9; border-radius: 50%; animation: spin .7s linear infinite;
  }
  @keyframes logo-pulse { 0%,100%{transform:scale(1);opacity:1} 50%{transform:scale(.85);opacity:.55} }
  @keyframes spin { to{transform:rotate(360deg)} }
</style>
