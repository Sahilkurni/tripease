<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);
admin_ensure_status_column($conn, 'buses');

if (!admin_table_exists($conn, 'buses')) {
    admin_error('Buses table not found');
}

$columns = admin_columns($conn, 'buses');
$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $columns, 'b');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(b.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(b.isactive, 0) = 0";

$sql = "SELECT
            b.*,
            $statusSelect
        FROM buses b
        $pendingWhere
        ORDER BY b.busid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch buses');
}

admin_success(admin_rows($result));
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);
admin_ensure_status_column($conn, 'buses');

if (!admin_table_exists($conn, 'buses')) {
    admin_error('Buses table not found');
}

$columns = admin_columns($conn, 'buses');
$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $columns, 'b');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(b.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(b.isactive, 0) = 0";

$sql = "SELECT
            b.*,
            $statusSelect
        FROM buses b
        $pendingWhere
        ORDER BY b.busid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch buses');
}

admin_success(admin_rows($result));
?>

