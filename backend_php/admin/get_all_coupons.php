<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT couponid, couponcode, discounttype, discountvalue, minamount, expirydate, isactive 
        FROM coupons 
        ORDER BY couponid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
