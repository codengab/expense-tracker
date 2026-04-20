// src/lib/utils/workspace-loader.js
import { workspaceId } from "$lib/stores";
import { onMount, onDestroy } from "svelte";

/**
 * Subscribe ke perubahan workspaceId dan jalankan callback
 * setiap kali workspaceId tersedia atau berganti.
 *
 * Perbaikan dari versi lama:
 * - Hapus flag `ran` yang logikanya salah (reset → cek → selalu true)
 * - Simpan wsId terakhir untuk deteksi perubahan workspace yang sesungguhnya
 * - Callback dipanggil tepat sekali per nilai wsId yang unik
 */
export function onWorkspaceReady(callback) {
  let unsub;
  let lastWsId = null;

  onMount(() => {
    unsub = workspaceId.subscribe(async (wsId) => {
      if (!wsId) return;
      // Hanya jalankan jika wsId benar-benar berubah
      if (wsId === lastWsId) return;
      lastWsId = wsId;
      await callback(wsId);
    });
  });

  onDestroy(() => {
    if (unsub) unsub();
  });
}
