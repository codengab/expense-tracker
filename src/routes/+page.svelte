<!-- src/routes/+page.svelte -->
<!-- Root "/" — redirect logic ada di +layout.svelte -->
<!-- File ini hanya perlu exist agar SvelteKit tidak 404 -->
<script>
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';

  // Fallback redirect kalau layout belum sempat handle
  onMount(() => {
    goto('/dashboard', { replaceState: true });
  });
</script>
