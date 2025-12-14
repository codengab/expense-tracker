<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Goal extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'workspace_id',
        'name',
        'type',
        'target_amount',
        'deadline',
    ];

    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    public function goalEntries()
    {
        return $this->hasMany(GoalEntry::class);
    }
}
