<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php
$_POST['status'] = 'approved';
require __DIR__ . '/update_hotel_status.php';
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

$_POST['status'] = 'approved';
require __DIR__ . '/update_hotel_status.php';
?>

