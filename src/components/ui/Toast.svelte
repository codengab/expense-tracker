<!-- src/components/ui/Toast.svelte -->
<script>
  import { toast } from '$lib/stores';
  import { fly } from 'svelte/transition';
</script>

{#if $toast}
  <div
    class="toast toast--{$toast.type}"
    in:fly={{ y: 20, duration: 250 }}
    out:fly={{ y: 20, duration: 200 }}
  >
    <span class="toast__icon">
      {#if $toast.type === 'success'}✓{:else if $toast.type === 'error'}✕{:else}ℹ{/if}
    </span>
    <span>{$toast.message}</span>
  </div>
{/if}

<style>
  .toast {
    position: fixed;
    bottom: 1.5rem;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.25rem;
    border-radius: 0.75rem;
    font-size: 0.875rem;
    font-weight: 500;
    z-index: 9999;
    box-shadow: 0 4px 24px rgba(0,0,0,0.12);
    white-space: nowrap;
  }
  .toast--success { background: #16A34A; color: white; }
  .toast--error { background: #DC2626; color: white; }
  .toast--info { background: #0EA5E9; color: white; }
  .toast__icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 1.25rem;
    height: 1.25rem;
    background: rgba(255,255,255,0.25);
    border-radius: 50%;
    font-size: 0.75rem;
  }
</style>
