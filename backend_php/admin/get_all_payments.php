<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'payments')) {
    admin_success([]);
}

$paymentColumns = admin_columns($conn, 'payments');
$paymentIdCol = admin_col($paymentColumns, ['paymentid', 'id']);

$select = [
    admin_int_select_expr('paymentid', $paymentColumns, ['paymentid', 'id'], '0', 'p.'),
    admin_int_select_expr('bookingid', $paymentColumns, ['bookingid'], '0', 'p.'),
    admin_int_select_expr('amount', $paymentColumns, ['amount', 'paidamount'], '0', 'p.'),
    admin_select_expr('paymentstatus', $paymentColumns, ['paymentstatus', 'status'], "'PENDING'", 'p.'),
    admin_select_expr('edatetime', $paymentColumns, ['paiddate', 'paymentdate', 'edatetime', 'created_at'], "''", 'p.')
];

$order = $paymentIdCol !== null ? "p.`$paymentIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM payments p ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch payments');
}

admin_success(admin_rows($result));
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'payments')) {
    admin_success([]);
}

$paymentColumns = admin_columns($conn, 'payments');
$paymentIdCol = admin_col($paymentColumns, ['paymentid', 'id']);

$select = [
    admin_int_select_expr('paymentid', $paymentColumns, ['paymentid', 'id'], '0', 'p.'),
    admin_int_select_expr('bookingid', $paymentColumns, ['bookingid'], '0', 'p.'),
    admin_int_select_expr('amount', $paymentColumns, ['amount', 'paidamount'], '0', 'p.'),
    admin_select_expr('paymentstatus', $paymentColumns, ['paymentstatus', 'status'], "'PENDING'", 'p.'),
    admin_select_expr('edatetime', $paymentColumns, ['paiddate', 'paymentdate', 'edatetime', 'created_at'], "''", 'p.')
];

$order = $paymentIdCol !== null ? "p.`$paymentIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM payments p ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch payments');
}

admin_success(admin_rows($result));
?>

