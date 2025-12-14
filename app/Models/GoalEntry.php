<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class GoalEntry extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'goal_id',
        'wallet_id',
        'amount',
        'quantity',
        'price_per_unit',
        'entry_date',
    ];

    public function goal()
    {
        return $this->belongsTo(Goal::class);
    }

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }
}
