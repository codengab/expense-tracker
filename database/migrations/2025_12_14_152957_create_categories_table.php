<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
        $table->id();
        $table->foreignId('workspace_id')->constrained()->cascadeOnDelete();
        $table->string('name')->comment('Nama kategori, misal: Gaji, Makanan, Transport');
        $table->enum('type', ['income', 'expense'])->comment('Jenis kategori');
        $table->timestamps();
        $table->softDeletes();
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
