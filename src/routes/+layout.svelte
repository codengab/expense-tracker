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

  $: isAuthPage    = $page.url.pathname.startsWith('/auth');
  $: isOnboarding  = $page.url.pathname === '/onboarding';
  $: needsSidebar  = !isAuthPage && !isOnboarding;

  onMount(async () => {
    const { data: { session } } = await supabase.auth.getSession();

    if (session?.user) {
      user.set(session.user);
      const wsList = await loadAppData();
      // Redirect dari root atau auth page
      if ($page.url.pathname === '/' || isAuthPage) {
        goto(wsList.length === 0 ? '/onboarding' : '/dashboard', { replaceState: true });
      }
    } else {
      if (!isAuthPage) goto('/auth/login', { replaceState: true });
    }

    isLoading.set(false);

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'INITIAL_SESSION') return;
      user.set(session?.user ?? null);
      if (session?.user) {
        const wsList = await loadAppData();
        if (isAuthPage) goto(wsList.length === 0 ? '/onboarding' : '/dashboard');
      } else {
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
