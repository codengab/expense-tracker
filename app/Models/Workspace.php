<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Models\User;

class Workspace extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'name',
        'description',
    ];

    public function users()
    {
        return $this->belongsToMany(User::class)
                    ->withPivot('role')
                    ->withTimestamps();
    }

    public function wallets()
    {
        return $this->hasMany(Wallet::class);
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
    }

    public function goals()
    {
        return $this->hasMany(Goal::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function transfers()
    {
        return $this->hasMany(Transfer::class);
    }

    public function budgets()
    {
        return $this->hasMany(Budget::class);
    }
}
