<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;

class TransactionService
{
  /**
   * Create transaction (income/expense).
   */
  public function create(array $data): Transaction
  {
    return DB::transaction(function () use ($data) {
      // Lock wallet (anti double submit / race condition)
      $wallet = Wallet::lockForUpdate()->findOrFail($data['wallet_id']);

      $category = $wallet->workspace->categories()->findOrFail($data['category_id']);
      $amount = $data['amount'];

      // saldo calc
      if ($category->type == "expense") {
        if ($wallet->balance < $amount) {
          throw new Exception('Saldo tidak mencukupi');
        }

        $wallet->balance -= $amount;
      } else {
        $wallet->balance += $amount;
      }

      $wallet->save();

      return Transaction::create([
        'workspace_id'     => $wallet->workspace_id,
        'wallet_id'        => $wallet->id,
        'category_id'      => $category->id,
        'amount'           => $amount,
        'transaction_date' => $data['transaction_date'],
        'description'      => $data['description'] ?? null,
      ]);
    });
  }

  /**
   * Update Transaction
   */

  public function update(Transaction $transaction, array $data): Transaction
  {
    return DB::transaction(function () use ($transaction, $data) {
      $wallet = Wallet::lockForUpdate()->findOrFail($transaction->wallet_id);

      // rollback saldo
      if ($transaction->category->type === 'expense') {
        $wallet->balance += $transaction->amount;
      } else {
        $wallet->balance -= $transaction->amount;
      }

      // update saldo
      $category = $wallet->workspace
        ->categories()
        ->findOrFail($data['category_id']);

      if ($category->type === 'expense') {
        if ($wallet->balance < $data['amount']) {
          throw new Exception('Saldo tidak mencukupi');
        }
        $wallet->balance -= $data['amount'];
      } else {
        $wallet->balance += $data['amount'];
      }

      $wallet->save();

      $transaction->update([
        'category_id'      => $category->id,
        'amount'           => $data['amount'],
        'transaction_date' => $data['transaction_date'],
        'description'      => $data['description'] ?? null,
      ]);

      return $transaction;
    });
  }

  /**
   * Delete transaction
   * Sof Deletes
   */
  public function delete(Transaction $transaction): void
  {
    DB::transaction(function () use ($transaction) {

      $wallet = Wallet::lockForUpdate()->findOrFail($transaction->wallet_id);

      if ($transaction->category->type === 'expense') {
        $wallet->balance += $transaction->amount;
      } else {
        $wallet->balance -= $transaction->amount;
      }

      $wallet->save();
      $transaction->delete();
    });
  }
}
