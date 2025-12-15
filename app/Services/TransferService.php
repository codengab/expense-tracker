<?php

namespace App\Services;

use App\Models\Transfer;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;

class TransferService
{
  public function create(array $data): Transfer
  {
    return DB::transaction(function () use ($data) {
      if ($data['from_wallet_id'] === $data['to_wallet_id']) {
        throw new Exception('Wallet asal dan tujuan tidak boleh sama');
      }

      $from = Wallet::lockForUpdate()->findOrFail($data['from_wallet_id']);
      $to = Wallet::lockForUpdate()->findOrFail($data['to_wallet_id']);
      if ($from->balance < $data['amount']) {
        throw new Exception('Saldo tidak mencukupi');
      }
      $from->balance -= $data['amount'];
      $to->balance   += $data['amount'];

      $from->save();
      $to->save();
      return Transfer::create([
        'workspace_id'   => $from->workspace_id,
        'from_wallet_id' => $from->id,
        'to_wallet_id'   => $to->id,
        'amount'         => $data['amount'],
        'transfer_date'  => $data['transfer_date'],
        'description'    => $data['description'] ?? null,
      ]);
    });
  }
}
