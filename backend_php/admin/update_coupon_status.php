<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

$couponid = $_POST['couponid'] ?? '';
$isactive = $_POST['isactive'] ?? '';

if ($couponid === '' || $isactive === '') {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    $stmt = $pdo->prepare("UPDATE coupons SET isactive = ? WHERE couponid = ?");
    $stmt->execute([$isactive, $couponid]);
    echo json_encode(["status" => "success", "message" => "Coupon status updated"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
