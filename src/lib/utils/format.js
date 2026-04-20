// src/lib/utils/format.js

const IDR = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0
});

export function formatCurrency(amount) {
  return IDR.format(amount || 0);
}

export function formatCurrencyShort(amount) {
  const n = Math.abs(amount || 0);
  if (n >= 1_000_000_000) return `Rp ${(n / 1_000_000_000).toFixed(1)}M`;
  if (n >= 1_000_000) return `Rp ${(n / 1_000_000).toFixed(1)}jt`;
  if (n >= 1_000) return `Rp ${(n / 1_000).toFixed(0)}rb`;
  return formatCurrency(amount);
}

export function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });
}

export function formatDateShort(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'short'
  });
}

export function formatMonthYear(year, month) {
  return new Date(year, month - 1, 1).toLocaleDateString('id-ID', {
    month: 'long',
    year: 'numeric'
  });
}

export function toDateInput(date = new Date()) {
  return date.toISOString().split('T')[0];
}

export function getCurrentMonthYear() {
  const now = new Date();
  return { month: now.getMonth() + 1, year: now.getFullYear() };
}

export function getMonthOptions() {
  return Array.from({ length: 12 }, (_, i) => ({
    value: i + 1,
    label: new Date(2024, i, 1).toLocaleDateString('id-ID', { month: 'long' })
  }));
}

export function getYearOptions(range = 3) {
  const year = new Date().getFullYear();
  return Array.from({ length: range * 2 + 1 }, (_, i) => year - range + i);
}

export function groupByDate(transactions) {
  const groups = {};
  for (const t of transactions) {
    const date = t.date;
    if (!groups[date]) groups[date] = [];
    groups[date].push(t);
  }
  return Object.entries(groups)
    .sort(([a], [b]) => b.localeCompare(a))
    .map(([date, items]) => ({ date, items }));
}
