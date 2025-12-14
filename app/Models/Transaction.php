<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transaction extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'workspace_id',
        'wallet_id',
        'category_id',
        'amount',
        'transaction_date',
        'description',
        'type',
    ];

    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
