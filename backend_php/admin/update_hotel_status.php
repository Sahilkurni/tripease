<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

$hotelid = $_POST['hotelid'] ?? '';
$isactive = $_POST['isactive'] ?? '';

if ($hotelid === '' || $isactive === '') {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    $stmt = $pdo->prepare("UPDATE hotels SET isactive = ? WHERE hotelid = ?");
    $stmt->execute([$isactive, $hotelid]);
    echo json_encode(["status" => "success", "message" => "Hotel status updated"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
