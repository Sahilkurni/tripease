<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);

if (!admin_table_exists($conn, 'coupons')) {
    $createSql = "CREATE TABLE coupons (
        couponid INT AUTO_INCREMENT PRIMARY KEY,
        code VARCHAR(50) NOT NULL UNIQUE,
        discount_type VARCHAR(20) NOT NULL,
        discount_value DECIMAL(10,2) NOT NULL DEFAULT 0,
        min_booking_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        max_discount DECIMAL(10,2) NOT NULL DEFAULT 0,
        valid_until DATE NULL,
        isactive TINYINT NOT NULL DEFAULT 1,
        edatetime DATETIME DEFAULT CURRENT_TIMESTAMP
    )";
    if (!$conn->query($createSql)) {
        admin_error('Failed to prepare coupons table');
    }
}

$columns = admin_columns($conn, 'coupons');
$code = strtoupper(trim($_POST['code'] ?? ''));
$discountType = strtoupper(trim($_POST['discount_type'] ?? ''));
$discountValue = isset($_POST['discount_value']) ? floatval($_POST['discount_value']) : 0;
$minBookingAmount = isset($_POST['min_booking_amount']) ? floatval($_POST['min_booking_amount']) : 0;
$maxDiscount = isset($_POST['max_discount']) ? floatval($_POST['max_discount']) : 0;
$validUntil = trim($_POST['valid_until'] ?? '');
$isActive = isset($_POST['isactive']) ? intval($_POST['isactive']) : 1;

if ($code === '' || !in_array($discountType, ['PERCENTAGE', 'FIXED']) || $discountValue <= 0) {
    admin_error('Valid code, discount_type and discount_value are required');
}

$codeCol = admin_col($columns, ['code', 'couponcode']);
if ($codeCol === null) {
    admin_error('Coupon code column not found');
}

$checkStmt = $conn->prepare("SELECT `$codeCol` FROM coupons WHERE `$codeCol` = ? LIMIT 1");
$checkStmt->bind_param('s', $code);
$checkStmt->execute();
$exists = $checkStmt->get_result();
$alreadyExists = $exists && $exists->fetch_assoc();
$checkStmt->close();
if ($alreadyExists) {
    admin_error('Coupon code already exists');
}

$mapping = [
    ['code', ['code', 'couponcode'], $code, 's'],
    ['discount_type', ['discount_type', 'discounttype'], $discountType, 's'],
    ['discount_value', ['discount_value', 'discountvalue'], $discountValue, 'd'],
    ['min_booking_amount', ['min_booking_amount', 'minamount'], $minBookingAmount, 'd'],
    ['max_discount', ['max_discount'], $maxDiscount, 'd'],
    ['valid_until', ['valid_until', 'expirydate'], $validUntil === '' ? null : $validUntil, 's'],
    ['isactive', ['isactive'], $isActive, 'i']
];

$insertColumns = [];
$placeholders = [];
$values = [];
$types = '';
foreach ($mapping as $item) {
    $column = admin_col($columns, $item[1]);
    if ($column !== null) {
        $insertColumns[] = "`$column`";
        $placeholders[] = '?';
        $values[] = $item[2];
        $types .= $item[3];
    }
}

$sql = 'INSERT INTO coupons (' . implode(', ', $insertColumns) . ') VALUES (' . implode(', ', $placeholders) . ')';
$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$values);
$ok = $stmt->execute();
$couponId = $stmt->insert_id;
$stmt->close();

if (!$ok) {
    admin_error('Failed to create coupon');
}

admin_success(['couponid' => $couponId], 'Coupon created successfully');
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);

if (!admin_table_exists($conn, 'coupons')) {
    $createSql = "CREATE TABLE coupons (
        couponid INT AUTO_INCREMENT PRIMARY KEY,
        code VARCHAR(50) NOT NULL UNIQUE,
        discount_type VARCHAR(20) NOT NULL,
        discount_value DECIMAL(10,2) NOT NULL DEFAULT 0,
        min_booking_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        max_discount DECIMAL(10,2) NOT NULL DEFAULT 0,
        valid_until DATE NULL,
        isactive TINYINT NOT NULL DEFAULT 1,
        edatetime DATETIME DEFAULT CURRENT_TIMESTAMP
    )";
    if (!$conn->query($createSql)) {
        admin_error('Failed to prepare coupons table');
    }
}

$columns = admin_columns($conn, 'coupons');
$code = strtoupper(trim($_POST['code'] ?? ''));
$discountType = strtoupper(trim($_POST['discount_type'] ?? ''));
$discountValue = isset($_POST['discount_value']) ? floatval($_POST['discount_value']) : 0;
$minBookingAmount = isset($_POST['min_booking_amount']) ? floatval($_POST['min_booking_amount']) : 0;
$maxDiscount = isset($_POST['max_discount']) ? floatval($_POST['max_discount']) : 0;
$validUntil = trim($_POST['valid_until'] ?? '');
$isActive = isset($_POST['isactive']) ? intval($_POST['isactive']) : 1;

if ($code === '' || !in_array($discountType, ['PERCENTAGE', 'FIXED']) || $discountValue <= 0) {
    admin_error('Valid code, discount_type and discount_value are required');
}

$codeCol = admin_col($columns, ['code', 'couponcode']);
if ($codeCol === null) {
    admin_error('Coupon code column not found');
}

$checkStmt = $conn->prepare("SELECT `$codeCol` FROM coupons WHERE `$codeCol` = ? LIMIT 1");
$checkStmt->bind_param('s', $code);
$checkStmt->execute();
$exists = $checkStmt->get_result();
$alreadyExists = $exists && $exists->fetch_assoc();
$checkStmt->close();
if ($alreadyExists) {
    admin_error('Coupon code already exists');
}

$mapping = [
    ['code', ['code', 'couponcode'], $code, 's'],
    ['discount_type', ['discount_type', 'discounttype'], $discountType, 's'],
    ['discount_value', ['discount_value', 'discountvalue'], $discountValue, 'd'],
    ['min_booking_amount', ['min_booking_amount', 'minamount'], $minBookingAmount, 'd'],
    ['max_discount', ['max_discount'], $maxDiscount, 'd'],
    ['valid_until', ['valid_until', 'expirydate'], $validUntil === '' ? null : $validUntil, 's'],
    ['isactive', ['isactive'], $isActive, 'i']
];

$insertColumns = [];
$placeholders = [];
$values = [];
$types = '';
foreach ($mapping as $item) {
    $column = admin_col($columns, $item[1]);
    if ($column !== null) {
        $insertColumns[] = "`$column`";
        $placeholders[] = '?';
        $values[] = $item[2];
        $types .= $item[3];
    }
}

$sql = 'INSERT INTO coupons (' . implode(', ', $insertColumns) . ') VALUES (' . implode(', ', $placeholders) . ')';
$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$values);
$ok = $stmt->execute();
$couponId = $stmt->insert_id;
$stmt->close();

if (!$ok) {
    admin_error('Failed to create coupon');
}

admin_success(['couponid' => $couponId], 'Coupon created successfully');
?>

