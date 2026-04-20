<!-- src/components/ui/Modal.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  import { fade, fly } from 'svelte/transition';

  export let title = '';
  export let open = false;
  export let size = 'md'; // sm | md | lg

  const dispatch = createEventDispatcher();

  function close() {
    dispatch('close');
  }

  function handleKeydown(e) {
    if (e.key === 'Escape') close();
  }
</script>

<svelte:window on:keydown={handleKeydown} />

{#if open}
  <!-- Backdrop -->
  <div
    class="modal-backdrop"
    transition:fade={{ duration: 200 }}
    on:click={close}
    role="presentation"
  ></div>

  <!-- Dialog -->
  <div
    class="modal-wrapper"
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
  >
    <div
      class="modal modal--{size}"
      transition:fly={{ y: 16, duration: 250 }}
    >
      <!-- Header -->
      <div class="modal__header">
        <h2 id="modal-title" class="modal__title">{title}</h2>
        <button class="modal__close" on:click={close} aria-label="Tutup">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6L6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Content -->
      <div class="modal__body">
        <slot />
      </div>
    </div>
  </div>
{/if}

<style>
  .modal-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.4);
    backdrop-filter: blur(2px);
    z-index: 100;
  }
  .modal-wrapper {
    position: fixed;
    inset: 0;
    z-index: 101;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    padding: 1rem;
  }
  @media (min-width: 640px) {
    .modal-wrapper {
      align-items: center;
    }
  }
  .modal {
    background: #FFFFFF;
    border-radius: 1rem;
    box-shadow: 0 20px 60px rgba(0,0,0,0.15);
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
  }
  .modal--sm { max-width: 26rem; }
  .modal--md { max-width: 36rem; }
  .modal--lg { max-width: 48rem; }

  .modal__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.25rem 1.5rem;
    border-bottom: 1px solid #E2E8F0;
  }
  .modal__title {
    font-size: 1rem;
    font-weight: 600;
    color: #0F172A;
  }
  .modal__close {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    border-radius: 0.5rem;
    color: #64748B;
    background: transparent;
    border: none;
    cursor: pointer;
    transition: background 0.15s;
  }
  .modal__close:hover { background: #F1F5F9; }
  .modal__body { padding: 1.5rem; }
</style>
