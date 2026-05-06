<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'bookings')) {
    admin_success([]);
}

$bookingColumns = admin_columns($conn, 'bookings');
$userColumns = admin_table_exists($conn, 'users') ? admin_columns($conn, 'users') : [];
$bookingIdCol = admin_col($bookingColumns, ['bookingid', 'id']);
$userIdCol = admin_col($bookingColumns, ['userid']);

$select = [
    admin_int_select_expr('bookingid', $bookingColumns, ['bookingid', 'id'], '0', 'b.'),
    admin_select_expr('bookingtype', $bookingColumns, ['bookingtype', 'service', 'type'], "''", 'b.'),
    admin_int_select_expr('totalamount', $bookingColumns, ['totalamount', 'finalamount', 'amount'], '0', 'b.'),
    admin_select_expr('bookingstatus', $bookingColumns, ['bookingstatus', 'status'], "'PENDING'", 'b.')
];

$joins = '';
if ($userIdCol !== null && admin_table_exists($conn, 'users') && admin_col($userColumns, ['userid']) !== null) {
    $fullNameCol = admin_col($userColumns, ['fullname', 'name']);
    $select[] = $fullNameCol !== null ? "COALESCE(u.`$fullNameCol`, '') AS `fullname`" : "'' AS `fullname`";
    $joins .= " LEFT JOIN users u ON u.`" . admin_col($userColumns, ['userid']) . "` = b.`$userIdCol`";
} else {
    $select[] = "'' AS `fullname`";
}

$order = $bookingIdCol !== null ? "b.`$bookingIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM bookings b $joins ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch bookings');
}

admin_success(admin_rows($result));
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

if (!admin_table_exists($conn, 'bookings')) {
    admin_success([]);
}

$bookingColumns = admin_columns($conn, 'bookings');
$userColumns = admin_table_exists($conn, 'users') ? admin_columns($conn, 'users') : [];
$bookingIdCol = admin_col($bookingColumns, ['bookingid', 'id']);
$userIdCol = admin_col($bookingColumns, ['userid']);

$select = [
    admin_int_select_expr('bookingid', $bookingColumns, ['bookingid', 'id'], '0', 'b.'),
    admin_select_expr('bookingtype', $bookingColumns, ['bookingtype', 'service', 'type'], "''", 'b.'),
    admin_int_select_expr('totalamount', $bookingColumns, ['totalamount', 'finalamount', 'amount'], '0', 'b.'),
    admin_select_expr('bookingstatus', $bookingColumns, ['bookingstatus', 'status'], "'PENDING'", 'b.')
];

$joins = '';
if ($userIdCol !== null && admin_table_exists($conn, 'users') && admin_col($userColumns, ['userid']) !== null) {
    $fullNameCol = admin_col($userColumns, ['fullname', 'name']);
    $select[] = $fullNameCol !== null ? "COALESCE(u.`$fullNameCol`, '') AS `fullname`" : "'' AS `fullname`";
    $joins .= " LEFT JOIN users u ON u.`" . admin_col($userColumns, ['userid']) . "` = b.`$userIdCol`";
} else {
    $select[] = "'' AS `fullname`";
}

$order = $bookingIdCol !== null ? "b.`$bookingIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM bookings b $joins ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch bookings');
}

admin_success(admin_rows($result));
?>

