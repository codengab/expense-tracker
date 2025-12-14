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
        Schema::create('workspace_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workspace_id')->constrained()->cascadeOnDelete()->comment('Wallet milik workspace tertentu');
            $table->string('name')->comment('Nama wallet / rekening / e-wallet');
            $table->decimal('balance', 20, 2)->default(0)->comment('Saldo awal / saat ini');
            $table->string('type')->comment('Jenis wallet: cash, bank, e-wallet, crypto, dll');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('workspace_user');
    }
};
