// src/lib/utils/workspace-loader.js
// Helper untuk load data saat workspaceId tersedia atau berubah
// Solusi untuk race condition antara auth restore dan component mount

import { workspaceId } from '$lib/stores';
import { onMount, onDestroy } from 'svelte';

/**
 * Panggil ini di <script> halaman untuk load data
 * saat workspaceId tersedia, baik saat mount maupun setelah restore session.
 * 
 * Contoh:
 *   onWorkspaceReady(async (wsId) => {
 *     data = await myService.getAll(wsId);
 *   });
 */
export function onWorkspaceReady(callback) {
  let unsub;
  let ran = false; // hindari double-run

  onMount(() => {
    unsub = workspaceId.subscribe(async (wsId) => {
      if (!wsId) return;
      // Reset flag setiap kali wsId berubah (ganti workspace)
      ran = false;
      if (!ran) {
        ran = true;
        await callback(wsId);
      }
    });
  });

  onDestroy(() => {
    if (unsub) unsub();
  });
}
