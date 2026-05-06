<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);
admin_ensure_status_column($conn, 'packages');

$packageColumns = admin_columns($conn, 'packages');
$statusCol = admin_col($packageColumns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $packageColumns, 'pkg');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(pkg.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(pkg.isactive, 0) = 0";
$partnerColumns = admin_table_exists($conn, 'partners') ? admin_columns($conn, 'partners') : [];
$partnerUserCol = admin_col($partnerColumns, ['userid', 'uid']);
$partnerUserJoin = $partnerUserCol !== null ? "LEFT JOIN users pu ON p.`$partnerUserCol` = pu.userid" : "";

$sql = "SELECT
            pkg.packageid,
            pkg.packagename,
            pkg.price,
            pkg.days,
            pkg.nights,
            pkg.isactive,
            $statusSelect,
            COALESCE(pu.fullname, au.fullname, p.ownername, p.companyname, '') AS agentname
        FROM packages pkg
        LEFT JOIN partners p ON pkg.partnerid = p.partnerid
        $partnerUserJoin
        LEFT JOIN users au ON pkg.uid = au.userid
        $pendingWhere
        ORDER BY pkg.packageid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch packages');
}

$rows = admin_rows($result);
echo json_encode([
    'status' => 'success',
    'debug_sql' => $sql,
    'row_count' => count($rows),
    'data' => $rows
]);
exit;
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);
admin_ensure_status_column($conn, 'packages');

$packageColumns = admin_columns($conn, 'packages');
$statusCol = admin_col($packageColumns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $packageColumns, 'pkg');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(pkg.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(pkg.isactive, 0) = 0";
$partnerColumns = admin_table_exists($conn, 'partners') ? admin_columns($conn, 'partners') : [];
$partnerUserCol = admin_col($partnerColumns, ['userid', 'uid']);
$partnerUserJoin = $partnerUserCol !== null ? "LEFT JOIN users pu ON p.`$partnerUserCol` = pu.userid" : "";

$sql = "SELECT
            pkg.packageid,
            pkg.packagename,
            pkg.price,
            pkg.days,
            pkg.nights,
            pkg.isactive,
            $statusSelect,
            COALESCE(pu.fullname, au.fullname, p.ownername, p.companyname, '') AS agentname
        FROM packages pkg
        LEFT JOIN partners p ON pkg.partnerid = p.partnerid
        $partnerUserJoin
        LEFT JOIN users au ON pkg.uid = au.userid
        $pendingWhere
        ORDER BY pkg.packageid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch packages');
}

$rows = admin_rows($result);
echo json_encode([
    'status' => 'success',
    'debug_sql' => $sql,
    'row_count' => count($rows),
    'data' => $rows
]);
exit;
?>

