<?php
require_once 'C:/xampp/htdocs/tripease_api/config/db.php';

echo "=== TABLES ===\n";
$stmt = $pdo->query("SHOW TABLES");
$tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
print_r($tables);

foreach (['buses', 'bus_trips', 'bus_seats'] as $table) {
    if (in_array($table, $tables)) {
        echo "\n=== SCHEMA FOR $table ===\n";
        $stmt = $pdo->query("DESCRIBE `$table`");
        print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
        
        echo "\n=== SAMPLE DATA FOR $table ===\n";
        $stmt = $pdo->query("SELECT * FROM `$table` LIMIT 3");
        print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
    } else {
        echo "\nTable $table does not exist.\n";
    }
}
?>
