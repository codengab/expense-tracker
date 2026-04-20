<!-- src/components/forms/TransactionForm.svelte -->
<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { workspaceId, showToast } from '$lib/stores';
  import { transactionService } from '$lib/services/transaction.service';
  import { categoryService } from '$lib/services/category.service';
  import { walletService } from '$lib/services/wallet.service';
  import { toDateInput } from '$lib/utils/format';

  export let transaction = null; // null = create mode

  const dispatch = createEventDispatcher();

  let type = transaction?.type || 'expense';
  let amount = transaction?.amount || '';
  let categoryId = transaction?.category_id || '';
  let walletId = transaction?.wallet_id || '';
  let toWalletId = transaction?.to_wallet_id || '';
  let date = transaction?.date || toDateInput();
  let note = transaction?.note || '';

  let categories = [];
  let wallets = [];
  let loading = false;
  let error = '';

  $: filteredCategories = categories.filter(c => c.type === type || type === 'transfer');
  $: isTransfer = type === 'transfer';

  onMount(async () => {
    try {
      const [cats, wals] = await Promise.all([
        categoryService.getAll($workspaceId),
        walletService.getAll($workspaceId)
      ]);
      categories = cats;
      wallets = wals.filter(w => w.is_active);
      if (!walletId && wallets.length) walletId = wallets[0].id;
    } catch (e) {
      error = e.message;
    }
  });

  async function handleSubmit() {
    if (!amount || !walletId || (!isTransfer && !categoryId)) {
      error = 'Lengkapi semua field yang wajib diisi';
      return;
    }

    loading = true;
    error = '';

    try {
      const payload = {
        type,
        amount: parseFloat(String(amount).replace(/\./g, '').replace(',', '.')),
        wallet_id: walletId,
        to_wallet_id: isTransfer ? toWalletId : null,
        category_id: isTransfer ? null : categoryId,
        date,
        note: note || null
      };

      if (transaction?.id) {
        await transactionService.update(transaction.id, payload);
        showToast('Transaksi berhasil diperbarui');
      } else {
        await transactionService.create($workspaceId, payload);
        showToast('Transaksi berhasil ditambahkan');
      }

      dispatch('saved');
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  }

  function formatAmountInput(e) {
    let val = e.target.value.replace(/\D/g, '');
    amount = val ? parseInt(val, 10).toLocaleString('id-ID') : '';
    e.target.value = amount;
  }
</script>

<form on:submit|preventDefault={handleSubmit} class="txn-form">
  <!-- Type Tabs -->
  <div class="type-tabs">
    {#each [['expense','Pengeluaran'], ['income','Pemasukan'], ['transfer','Transfer']] as [val, label]}
      <button
        type="button"
        class="type-tab"
        class:type-tab--active={type === val}
        class:type-tab--expense={val === 'expense' && type === val}
        class:type-tab--income={val === 'income' && type === val}
        class:type-tab--transfer={val === 'transfer' && type === val}
        on:click={() => { type = val; categoryId = ''; }}
      >
        {label}
      </button>
    {/each}
  </div>

  <!-- Amount -->
  <div class="field">
    <label class="label">Jumlah <span class="required">*</span></label>
    <div class="amount-wrap">
      <span class="currency-prefix">Rp</span>
      <input
        type="text"
        class="input amount-input"
        placeholder="0"
        value={amount}
        on:input={formatAmountInput}
        inputmode="numeric"
        required
      />
    </div>
  </div>

  <!-- Wallet -->
  <div class="field">
    <label class="label">{isTransfer ? 'Dari Dompet' : 'Dompet'} <span class="required">*</span></label>
    <select class="input" bind:value={walletId} required>
      <option value="">-- Pilih dompet --</option>
      {#each wallets as w}
        <option value={w.id}>{w.name}</option>
      {/each}
    </select>
  </div>

  <!-- To Wallet (transfer only) -->
  {#if isTransfer}
    <div class="field">
      <label class="label">Ke Dompet <span class="required">*</span></label>
      <select class="input" bind:value={toWalletId} required>
        <option value="">-- Pilih dompet tujuan --</option>
        {#each wallets.filter(w => w.id !== walletId) as w}
          <option value={w.id}>{w.name}</option>
        {/each}
      </select>
    </div>
  {/if}

  <!-- Category -->
  {#if !isTransfer}
    <div class="field">
      <label class="label">Kategori <span class="required">*</span></label>
      <select class="input" bind:value={categoryId} required>
        <option value="">-- Pilih kategori --</option>
        {#each filteredCategories as c}
          <option value={c.id}>{c.name}</option>
        {/each}
      </select>
    </div>
  {/if}

  <!-- Date -->
  <div class="field">
    <label class="label">Tanggal <span class="required">*</span></label>
    <input type="date" class="input" bind:value={date} required />
  </div>

  <!-- Note -->
  <div class="field">
    <label class="label">Catatan</label>
    <input type="text" class="input" placeholder="Opsional..." bind:value={note} />
  </div>

  {#if error}
    <p class="error-msg">{error}</p>
  {/if}

  <button type="submit" class="btn-submit" disabled={loading}>
    {loading ? 'Menyimpan...' : transaction?.id ? 'Perbarui' : 'Simpan'}
  </button>
</form>

<style>
  .txn-form { display: flex; flex-direction: column; gap: 1rem; }

  .type-tabs {
    display: flex;
    background: #F1F5F9;
    border-radius: 0.75rem;
    padding: 0.25rem;
    gap: 0.25rem;
  }
  .type-tab {
    flex: 1;
    padding: 0.5rem;
    border-radius: 0.5rem;
    border: none;
    background: transparent;
    font-size: 0.8125rem;
    font-weight: 500;
    color: #64748B;
    cursor: pointer;
    transition: all 0.15s;
  }
  .type-tab--active { background: white; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }
  .type-tab--expense { color: #DC2626; }
  .type-tab--income { color: #16A34A; }
  .type-tab--transfer { color: #0EA5E9; }

  .field { display: flex; flex-direction: column; gap: 0.375rem; }
  .label { font-size: 0.8125rem; font-weight: 500; color: #374151; }
  .required { color: #DC2626; }

  .input {
    padding: 0.625rem 0.875rem;
    border: 1px solid #E2E8F0;
    border-radius: 0.625rem;
    font-size: 0.9375rem;
    color: #0F172A;
    background: white;
    outline: none;
    transition: border-color 0.15s;
    width: 100%;
    box-sizing: border-box;
  }
  .input:focus { border-color: #0EA5E9; box-shadow: 0 0 0 3px rgba(14,165,233,0.1); }

  .amount-wrap { position: relative; display: flex; align-items: center; }
  .currency-prefix {
    position: absolute;
    left: 0.875rem;
    color: #64748B;
    font-size: 0.9375rem;
    pointer-events: none;
  }
  .amount-input { padding-left: 2.5rem; font-weight: 600; font-size: 1.125rem; }

  .error-msg {
    font-size: 0.8125rem;
    color: #DC2626;
    padding: 0.5rem 0.75rem;
    background: #FEF2F2;
    border-radius: 0.5rem;
  }

  .btn-submit {
    padding: 0.75rem;
    background: #0EA5E9;
    color: white;
    border: none;
    border-radius: 0.75rem;
    font-size: 0.9375rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.15s;
    margin-top: 0.25rem;
  }
  .btn-submit:hover { background: #0284C7; }
  .btn-submit:disabled { opacity: 0.6; cursor: not-allowed; }
</style>
