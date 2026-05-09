<?php
require_once 'c:/xampp/htdocs/tripease_api/config/db.php';
try {
    $sql = "CREATE INDEX idx_entity_type_id_active ON image_master (entity_type, entity_id, isactive)";
    if ($conn->query($sql) === TRUE) {
        echo "Index created successfully\n";
    } else {
        echo "Error creating index: " . $conn->error . "\n";
    }
} catch (Exception $e) {
    echo "Exception: " . $e->getMessage() . "\n";
}
// Try with PDO as well just in case config/db.php provides $pdo
if (isset($pdo)) {
    try {
        $pdo->exec("CREATE INDEX idx_entity_type_id_active_pdo ON image_master (entity_type, entity_id, isactive)");
        echo "Index created successfully via PDO\n";
    } catch (Exception $e) {
        echo "PDO Exception: " . $e->getMessage() . "\n";
    }
}
?>
