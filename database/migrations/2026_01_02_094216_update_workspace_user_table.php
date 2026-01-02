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
       Schema::table('workspace_user', function (Blueprint $table) {

            if (! Schema::hasColumn('workspace_user', 'role')) {
                $table->enum('role', ['owner', 'admin', 'member'])
                    ->default('member')
                    ->after('user_id');
            }

            if (! Schema::hasColumn('workspace_user', 'created_at')) {
                $table->timestamps();
            }

            // pastikan tidak ada duplikasi user-workspace
            $table->unique(['workspace_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('workspace_user', function (Blueprint $table) {
            $table->dropUnique(['workspace_id', 'user_id']);
            $table->dropColumn('role');
            $table->dropTimestamps();
        });
    }
};
