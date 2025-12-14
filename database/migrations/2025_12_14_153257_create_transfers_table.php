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
        Schema::create('transfers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workspace_id')->constrained()->cascadeOnDelete();
            $table->foreignId('from_wallet_id')->constrained('wallets')->cascadeOnDelete();
            $table->foreignId('to_wallet_id')->constrained('wallets')->cascadeOnDelete();
            $table->decimal('amount', 20, 2)->comment('Jumlah transfer');
            $table->date('transfer_date')->comment('Tanggal transfer');
            $table->string('description')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transfers');
    }
};
