<?php
require_once 'c:/xampp/htdocs/tripease_api/config/db.php';
$result = $conn->query("SHOW TABLES");
while ($row = $result->fetch_array()) {
    $table = $row[0];
    echo "Table: $table\n";
    $cols = $conn->query("DESCRIBE `$table`");
    while ($col = $cols->fetch_assoc()) {
        echo "  " . $col['Field'] . " (" . $col['Type'] . ")\n";
    }
    echo "\n";
}
?>
