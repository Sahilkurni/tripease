<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

$couponcode = $_POST['couponcode'] ?? '';
$discounttype = $_POST['discounttype'] ?? '';
$discountvalue = $_POST['discountvalue'] ?? '';
$minamount = $_POST['minamount'] ?? 0;
$expirydate = $_POST['expirydate'] ?? '';
$isactive = $_POST['isactive'] ?? 1;

if ($couponcode === '' || $discounttype === '' || $discountvalue === '') {
    echo json_encode(["status" => "error", "message" => "Missing required parameters"]);
    exit;
}

try {
    // Check if code exists
    $stmt = $pdo->prepare("SELECT couponid FROM coupons WHERE couponcode = ?");
    $stmt->execute([$couponcode]);
    if ($stmt->fetch()) {
        echo json_encode(["status" => "error", "message" => "Coupon code already exists"]);
        exit;
    }

    $stmt = $pdo->prepare("INSERT INTO coupons (couponcode, discounttype, discountvalue, minamount, expirydate, isactive) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$couponcode, $discounttype, $discountvalue, $minamount, $expirydate, $isactive]);
    echo json_encode(["status" => "success", "message" => "Coupon created successfully"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
