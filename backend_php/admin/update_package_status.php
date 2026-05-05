<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

$packageid = $_POST['packageid'] ?? '';
$isactive = $_POST['isactive'] ?? '';

if ($packageid === '' || $isactive === '') {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    $stmt = $pdo->prepare("UPDATE packages SET isactive = ? WHERE packageid = ?");
    $stmt->execute([$isactive, $packageid]);
    echo json_encode(["status" => "success", "message" => "Package status updated"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
