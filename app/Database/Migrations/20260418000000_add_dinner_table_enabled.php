<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Migration_add_dinner_table_enabled extends Migration
{
    public function up(): void
    {
        $this->forge->addColumn('dinner_tables', [
            'enabled' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'null'       => false,
                'default'    => 1,
            ]
        ]);
    }

    public function down(): void
    {
        $this->forge->dropColumn('dinner_tables', 'enabled');
    }
}
