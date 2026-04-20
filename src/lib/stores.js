// src/lib/stores.js
import { writable, derived } from 'svelte/store';

// Auth
export const user        = writable(null);
export const userProfile = writable(null); // { display_name, avatar_color }
export const isLoading   = writable(true);

// Active workspace
export const activeWorkspace = writable(null);
export const workspaces      = writable([]);

// UI
export const sidebarOpen = writable(false);
export const toast       = writable(null);

// Derived
export const workspaceId = derived(activeWorkspace, $ws => $ws?.id ?? null);

// Display name helper — pakai display_name kalau ada, fallback ke email
export const displayName = derived([user, userProfile], ([$user, $profile]) => {
  if ($profile?.display_name?.trim()) return $profile.display_name.trim();
  return $user?.email || '';
});

export const avatarColor = derived(userProfile, $p => $p?.avatar_color || '#0EA5E9');

// Toast
let toastTimer;
export function showToast(message, type = 'success') {
  clearTimeout(toastTimer);
  toast.set({ message, type });
  toastTimer = setTimeout(() => toast.set(null), 3500);
}

// Workspace helpers
export function setWorkspace(ws) {
  activeWorkspace.set(ws);
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem('activeWorkspaceId', ws?.id || '');
  }
}

export function loadStoredWorkspace(workspaceList) {
  if (typeof localStorage === 'undefined') return;
  const storedId = localStorage.getItem('activeWorkspaceId');
  const found = workspaceList.find(w => w.id === storedId);
  if (found) activeWorkspace.set(found);
  else if (workspaceList.length > 0) activeWorkspace.set(workspaceList[0]);
}
