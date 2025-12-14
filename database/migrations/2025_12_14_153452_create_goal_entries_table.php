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
        Schema::create('goal_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('goal_id')->constrained()->cascadeOnDelete();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 20, 2)->comment('Nominal setoran / pembelian');
            $table->decimal('quantity', 20, 3)->nullable()->comment('Gram / unit untuk investasi emas/commodity');
            $table->decimal('price_per_unit', 20, 2)->nullable()->comment('Harga per unit saat membeli, opsional untuk emas/commodity');
            $table->date('entry_date')->comment('Tanggal pencatatan');
            $table->timestamps();
            $table->softDeletes();
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('goal_entries');
    }
};
