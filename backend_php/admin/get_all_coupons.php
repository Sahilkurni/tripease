<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'coupons')) {
    admin_success([]);
}

$columns = admin_columns($conn, 'coupons');
$couponIdCol = admin_col($columns, ['couponid', 'id']);

$select = [
    admin_int_select_expr('couponid', $columns, ['couponid', 'id'], '0', 'c.'),
    admin_select_expr('code', $columns, ['code', 'couponcode'], "''", 'c.'),
    admin_select_expr('discount_type', $columns, ['discount_type', 'discounttype'], "''", 'c.'),
    admin_int_select_expr('discount_value', $columns, ['discount_value', 'discountvalue'], '0', 'c.'),
    admin_int_select_expr('min_booking_amount', $columns, ['min_booking_amount', 'minamount'], '0', 'c.'),
    admin_int_select_expr('max_discount', $columns, ['max_discount'], '0', 'c.'),
    admin_select_expr('valid_until', $columns, ['valid_until', 'expirydate'], "''", 'c.'),
    admin_int_select_expr('isactive', $columns, ['isactive'], '1', 'c.')
];

$order = $couponIdCol !== null ? "c.`$couponIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM coupons c ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch coupons');
}

admin_success(admin_rows($result));
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'coupons')) {
    admin_success([]);
}

$columns = admin_columns($conn, 'coupons');
$couponIdCol = admin_col($columns, ['couponid', 'id']);

$select = [
    admin_int_select_expr('couponid', $columns, ['couponid', 'id'], '0', 'c.'),
    admin_select_expr('code', $columns, ['code', 'couponcode'], "''", 'c.'),
    admin_select_expr('discount_type', $columns, ['discount_type', 'discounttype'], "''", 'c.'),
    admin_int_select_expr('discount_value', $columns, ['discount_value', 'discountvalue'], '0', 'c.'),
    admin_int_select_expr('min_booking_amount', $columns, ['min_booking_amount', 'minamount'], '0', 'c.'),
    admin_int_select_expr('max_discount', $columns, ['max_discount'], '0', 'c.'),
    admin_select_expr('valid_until', $columns, ['valid_until', 'expirydate'], "''", 'c.'),
    admin_int_select_expr('isactive', $columns, ['isactive'], '1', 'c.')
];

$order = $couponIdCol !== null ? "c.`$couponIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM coupons c ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch coupons');
}

admin_success(admin_rows($result));
?>

