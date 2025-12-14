<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transfer extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'workspace_id',
        'from_wallet_id',
        'to_wallet_id',
        'amount',
        'transfer_date',
        'description',
    ];

    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    public function fromWallet()
    {
        return $this->belongsTo(Wallet::class, 'from_wallet_id');
    }

    public function toWallet()
    {
        return $this->belongsTo(Wallet::class, 'to_wallet_id');
    }
}
