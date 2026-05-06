<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

$table = admin_table_exists($conn, 'support_tickets') ? 'support_tickets' : (admin_table_exists($conn, 'support') ? 'support' : null);
if ($table === null) {
    admin_success([]);
}

$ticketColumns = admin_columns($conn, $table);
$userColumns = admin_table_exists($conn, 'users') ? admin_columns($conn, 'users') : [];
$ticketIdCol = admin_col($ticketColumns, ['ticketid', 'supportid', 'id']);
$userIdCol = admin_col($ticketColumns, ['userid']);

$select = [
    admin_int_select_expr('ticketid', $ticketColumns, ['ticketid', 'supportid', 'id'], '0', 't.'),
    admin_select_expr('issue', $ticketColumns, ['issue', 'subject', 'message', 'description'], "''", 't.'),
    admin_select_expr('status', $ticketColumns, ['status'], "'OPEN'", 't.'),
    admin_select_expr('edatetime', $ticketColumns, ['edatetime', 'created_at', 'createddate'], "''", 't.')
];

$joins = '';
if ($userIdCol !== null && admin_table_exists($conn, 'users') && admin_col($userColumns, ['userid']) !== null) {
    $fullNameCol = admin_col($userColumns, ['fullname', 'name']);
    $select[] = $fullNameCol !== null ? "COALESCE(u.`$fullNameCol`, '') AS `fullname`" : "'' AS `fullname`";
    $joins .= " LEFT JOIN users u ON u.`" . admin_col($userColumns, ['userid']) . "` = t.`$userIdCol`";
} else {
    $select[] = "'' AS `fullname`";
}

$order = $ticketIdCol !== null ? "t.`$ticketIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM `$table` t $joins ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch support tickets');
}

admin_success(admin_rows($result));
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

$table = admin_table_exists($conn, 'support_tickets') ? 'support_tickets' : (admin_table_exists($conn, 'support') ? 'support' : null);
if ($table === null) {
    admin_success([]);
}

$ticketColumns = admin_columns($conn, $table);
$userColumns = admin_table_exists($conn, 'users') ? admin_columns($conn, 'users') : [];
$ticketIdCol = admin_col($ticketColumns, ['ticketid', 'supportid', 'id']);
$userIdCol = admin_col($ticketColumns, ['userid']);

$select = [
    admin_int_select_expr('ticketid', $ticketColumns, ['ticketid', 'supportid', 'id'], '0', 't.'),
    admin_select_expr('issue', $ticketColumns, ['issue', 'subject', 'message', 'description'], "''", 't.'),
    admin_select_expr('status', $ticketColumns, ['status'], "'OPEN'", 't.'),
    admin_select_expr('edatetime', $ticketColumns, ['edatetime', 'created_at', 'createddate'], "''", 't.')
];

$joins = '';
if ($userIdCol !== null && admin_table_exists($conn, 'users') && admin_col($userColumns, ['userid']) !== null) {
    $fullNameCol = admin_col($userColumns, ['fullname', 'name']);
    $select[] = $fullNameCol !== null ? "COALESCE(u.`$fullNameCol`, '') AS `fullname`" : "'' AS `fullname`";
    $joins .= " LEFT JOIN users u ON u.`" . admin_col($userColumns, ['userid']) . "` = t.`$userIdCol`";
} else {
    $select[] = "'' AS `fullname`";
}

$order = $ticketIdCol !== null ? "t.`$ticketIdCol` DESC" : '1 DESC';
$sql = 'SELECT ' . implode(', ', $select) . " FROM `$table` t $joins ORDER BY $order";
$result = $conn->query($sql);

if (!$result) {
    admin_error('Failed to fetch support tickets');
}

admin_success(admin_rows($result));
?>

