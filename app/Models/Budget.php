<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Budget extends Model
{
    use SoftDeletes;
    
    protected $fillable = [
        'workspace_id',
        'category_id',
        'amount',
        'month',
        'year',
    ];

    // Relasi ke workspace
    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    // Relasi ke kategori
    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
