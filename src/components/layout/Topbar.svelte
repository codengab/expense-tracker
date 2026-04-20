<!-- src/components/layout/Topbar.svelte -->
<script>
  import { sidebarOpen } from '$lib/stores';
  export let title = '';
</script>

<header class="topbar">
  <button class="hamburger" on:click={() => sidebarOpen.update(v => !v)} aria-label="Menu">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
      <line x1="3" y1="6" x2="21" y2="6"/>
      <line x1="3" y1="12" x2="21" y2="12"/>
      <line x1="3" y1="18" x2="21" y2="18"/>
    </svg>
  </button>

  <span class="topbar-title">{title}</span>

  <!-- Slot actions dibungkus agar tidak overflow di mobile -->
  <div class="topbar-actions">
    <slot />
  </div>
</header>

<style>
  .topbar {
    background: white;
    border-bottom: 1px solid var(--border);
    padding: 0 16px;
    height: 52px;
    display: flex;
    align-items: center;
    gap: 10px;
    position: sticky;
    top: 0;
    z-index: 10;
    min-width: 0; /* penting agar tidak overflow */
  }

  .hamburger {
    display: none;
    width: 34px; height: 34px;
    border: none; background: transparent;
    border-radius: 7px; cursor: pointer;
    color: var(--text-2); padding: 6px;
    flex-shrink: 0;
    transition: background .15s;
  }
  .hamburger svg { width: 18px; height: 18px; display: block; }
  .hamburger:hover { background: var(--bg); }
  @media (max-width: 767px) {
    .hamburger { display: flex; align-items: center; justify-content: center; }
  }

  .topbar-title {
    font-size: 14px;
    font-weight: 600;
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
  }

  .topbar-actions {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-shrink: 0; /* jangan pernah shrink, biarkan title yang menyusut */
  }

  /* Tombol di actions: lebih compact di mobile */
  :global(.topbar-actions .btn) {
    padding: 6px 10px;
    font-size: 12.5px;
    white-space: nowrap;
  }
  @media (max-width: 480px) {
    :global(.topbar-actions .btn span.btn-label) {
      display: none; /* sembunyikan label teks, sisakan icon */
    }
    :global(.topbar-actions .btn) {
      padding: 6px 8px;
      min-width: 32px;
      justify-content: center;
    }
  }
</style>
