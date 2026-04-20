# 💰 Dompet App

Aplikasi keuangan pribadi & keluarga — dibangun dengan SvelteKit, Tailwind CSS, dan Supabase.

---

## 🚀 Tech Stack

| Layer      | Teknologi                          |
|------------|------------------------------------|
| Frontend   | SvelteKit (SSG/SPA)               |
| Styling    | Tailwind CSS + Custom CSS Vars     |
| Backend    | Supabase (PostgreSQL + Auth + RLS) |
| Hosting    | Cloudflare Pages                   |

---

## 📁 Struktur Project

```
dompet-app/
├── src/
│   ├── app.html                  # HTML template
│   ├── app.css                   # Global styles & design tokens
│   ├── lib/
│   │   ├── supabase.js           # Supabase client & auth helpers
│   │   ├── stores.js             # Svelte writable stores
│   │   ├── services/
│   │   │   ├── wallet.service.js
│   │   │   ├── transaction.service.js
│   │   │   ├── budget.service.js
│   │   │   ├── category.service.js
│   │   │   └── workspace.service.js
│   │   └── utils/
│   │       └── format.js         # Currency, date formatters (IDR)
│   ├── components/
│   │   ├── ui/
│   │   │   ├── Modal.svelte
│   │   │   └── Toast.svelte
│   │   ├── layout/
│   │   │   ├── Sidebar.svelte
│   │   │   └── Topbar.svelte
│   │   └── forms/
│   │       ├── TransactionForm.svelte
│   │       └── CopyBudgetForm.svelte
│   └── routes/
│       ├── +layout.svelte        # Root layout with auth guard
│       ├── auth/
│       │   ├── login/+page.svelte
│       │   └── onboarding/+page.svelte
│       ├── dashboard/+page.svelte
│       ├── transactions/+page.svelte
│       ├── budgets/+page.svelte
│       ├── wallets/+page.svelte
│       └── settings/+page.svelte
├── supabase/
│   └── schema.sql                # Full DB schema + RLS + Views + Functions
├── docs/
│   └── app-demo.html             # Static interactive prototype
├── svelte.config.js
├── vite.config.js
├── tailwind.config.js
└── package.json
```

---

## ⚡ Quick Start

### 1. Clone & Install

```bash
git clone https://github.com/codengab/expense-tracker
cd expense-tracker
npm install
```

### 2. Setup Supabase

1. Buat project baru di [supabase.com](https://supabase.com)
2. Buka **SQL Editor**, jalankan `supabase/schema.sql`
3. Aktifkan **Email Auth** di Authentication → Providers

### 3. Environment Variables

```bash
cp .env.example .env
# Edit .env dengan URL dan anon key dari Supabase dashboard
```

### 4. Run Dev Server

```bash
npm run dev
```

---

## 🗄️ Database Schema

### Tables

| Table               | Deskripsi                              |
|---------------------|----------------------------------------|
| `workspaces`        | Workspace keluarga/personal            |
| `workspace_members` | Anggota + role (admin/member/viewer)   |
| `wallets`           | Dompet (tunai, bank, e-wallet, dll)    |
| `categories`        | Kategori transaksi (default + kustom)  |
| `transactions`      | Semua transaksi income/expense/transfer|
| `budgets`           | Anggaran per kategori per bulan        |

### Views (SQL)

| View               | Deskripsi                              |
|--------------------|----------------------------------------|
| `wallet_balances`  | Saldo dompet terkini (real-time)       |
| `monthly_summary`  | Ringkasan income/expense per bulan     |
| `budget_usage`     | Penggunaan anggaran + persentase       |

### Functions (SQL)

| Function      | Deskripsi                                      |
|---------------|------------------------------------------------|
| `copy_budget` | Salin anggaran bulan ke bulan (replace/merge)  |

---

## 🔐 Row Level Security (RLS)

Setiap tabel dilindungi RLS. User hanya bisa akses data workspace yang mereka ikuti:

- **Admin** → akses penuh (CRUD semua)
- **Member** → bisa buat/edit transaksi
- **Viewer** → hanya baca

---

## 🎨 Design Tokens

```css
:root {
  --bg:           #F1F5F9;  /* Background halaman */
  --card:         #FFFFFF;  /* Background card */
  --border:       #E2E8F0;  /* Border */
  --primary:      #0EA5E9;  /* Biru utama */
  --income:       #16A34A;  /* Hijau pemasukan */
  --expense:      #DC2626;  /* Merah pengeluaran */
  --warning:      #F59E0B;  /* Amber peringatan */
}
```

---

## 📱 Fitur

- [x] Auth (login, register, logout)
- [x] Onboarding (buat workspace pertama)
- [x] Manajemen dompet (CRUD, toggle aktif, saldo real-time)
- [x] Kategori (default sistem + kustom per workspace)
- [x] Transaksi (income, expense, transfer + filter)
- [x] Anggaran per kategori per bulan
- [x] Copy budget (replace / merge)
- [x] Dashboard dengan statistik
- [x] Laporan pengeluaran per kategori
- [x] Multi-user workspace
- [x] Role management (admin/member/viewer)
- [x] Undang anggota via email
- [x] Toast notifications
- [x] Mobile-responsive sidebar
- [x] Format IDR (Rp 1,5jt / Rp 24,5rb)

---

## 🚀 Deploy ke Cloudflare Pages

```bash
npm run build

# Atau connect GitHub repo ke Cloudflare Pages:
# Build command: npm run build
# Build output: .svelte-kit/cloudflare
# Environment: NODE_VERSION=18
```

Tambahkan environment variables di Cloudflare Pages dashboard.

---

## 🔄 Panduan Pengembangan

### Tambah Halaman Baru

```
src/routes/nama-halaman/+page.svelte
```

### Tambah Service Baru

```js
// src/lib/services/nama.service.js
import { supabase } from '$lib/supabase';

export const namaService = {
  async getAll(workspaceId) {
    const { data, error } = await supabase
      .from('nama_table')
      .select('*')
      .eq('workspace_id', workspaceId);
    if (error) throw error;
    return data;
  }
};
```

### Format Mata Uang

```js
import { formatCurrency, formatCurrencyShort } from '$lib/utils/format';

formatCurrency(1500000)      // → "Rp 1.500.000"
formatCurrencyShort(1500000) // → "Rp 1,5jt"
formatCurrencyShort(75000)   // → "Rp 75rb"
```

---

## 📝 Lisensi

Apache2
