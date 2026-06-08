<?php
require_once 'C:/xampp/htdocs/tripease_api/config/db.php';

// Fix buses table: copy new columns to old columns
$pdo->exec("UPDATE buses SET busname = bus_name, bustype = bus_type, totalseats = total_seats WHERE busname IS NULL OR busname = ''");

// Test buses query
$stmt = $pdo->prepare("SELECT * FROM buses WHERE partnerid = 22 AND isactive = 1");
$stmt->execute();
$buses = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Buses for partner 22: " . count($buses) . "\n";
print_r($buses);

// Test packages query
$stmt = $pdo->prepare("SELECT * FROM packages WHERE partnerid = 22 AND isactive = 1");
$stmt->execute();
$packages = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Packages for partner 22: " . count($packages) . "\n";
print_r($packages);
?>
