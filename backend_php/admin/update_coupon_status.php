<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);

$couponId = isset($_POST['couponid']) ? intval($_POST['couponid']) : 0;
$isActive = isset($_POST['isactive']) ? intval($_POST['isactive']) : -1;

if ($couponId <= 0 || ($isActive !== 0 && $isActive !== 1)) {
    admin_error('couponid and valid isactive are required');
}
if (!admin_table_exists($conn, 'coupons')) {
    admin_error('Coupons table not found');
}

$columns = admin_columns($conn, 'coupons');
$couponIdCol = admin_col($columns, ['couponid', 'id']);
$activeCol = admin_col($columns, ['isactive']);
if ($couponIdCol === null || $activeCol === null) {
    admin_error('Coupon status columns not found');
}

$stmt = $conn->prepare("UPDATE coupons SET `$activeCol` = ? WHERE `$couponIdCol` = ?");
$stmt->bind_param('ii', $isActive, $couponId);
$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update coupon');
}

admin_success(['couponid' => $couponId, 'isactive' => $isActive], 'Coupon status updated');
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);

$couponId = isset($_POST['couponid']) ? intval($_POST['couponid']) : 0;
$isActive = isset($_POST['isactive']) ? intval($_POST['isactive']) : -1;

if ($couponId <= 0 || ($isActive !== 0 && $isActive !== 1)) {
    admin_error('couponid and valid isactive are required');
}
if (!admin_table_exists($conn, 'coupons')) {
    admin_error('Coupons table not found');
}

$columns = admin_columns($conn, 'coupons');
$couponIdCol = admin_col($columns, ['couponid', 'id']);
$activeCol = admin_col($columns, ['isactive']);
if ($couponIdCol === null || $activeCol === null) {
    admin_error('Coupon status columns not found');
}

$stmt = $conn->prepare("UPDATE coupons SET `$activeCol` = ? WHERE `$couponIdCol` = ?");
$stmt->bind_param('ii', $isActive, $couponId);
$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update coupon');
}

admin_success(['couponid' => $couponId, 'isactive' => $isActive], 'Coupon status updated');
?>

