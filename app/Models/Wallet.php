<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Wallet extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'workspace_id',
        'name',
        'balance',
        'type',
    ];

    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function goalEntries()
    {
        return $this->hasMany(GoalEntry::class);
    }

    public function transfersFrom()
    {
        return $this->hasMany(Transfer::class, 'from_wallet_id');
    }

    public function transfersTo()
    {
        return $this->hasMany(Transfer::class, 'to_wallet_id');
    }
}
