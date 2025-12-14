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
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workspace_id')->constrained()->cascadeOnDelete();
            $table->string('name')->comment('Nama goal, misal: Dana Liburan, Investasi Emas');
            $table->enum('type', ['saving', 'invest'])->comment('Jenis goal');
            $table->decimal('target_amount', 20, 2)->comment('Target nominal goal');
            $table->date('deadline')->nullable()->comment('Batas waktu goal');
            $table->timestamps();
            $table->softDeletes();
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
