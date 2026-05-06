<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);
admin_ensure_status_column($conn, 'hotels');

$hotelColumns = admin_columns($conn, 'hotels');
$statusCol = admin_col($hotelColumns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $hotelColumns, 'h');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(h.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(h.isactive, 0) = 0";
$partnerColumns = admin_table_exists($conn, 'partners') ? admin_columns($conn, 'partners') : [];
$partnerUserCol = admin_col($partnerColumns, ['userid', 'uid']);
$partnerUserJoin = $partnerUserCol !== null ? "LEFT JOIN users pu ON p.`$partnerUserCol` = pu.userid" : "";

$sql = "SELECT
            h.hotelid,
            h.hotelname,
            h.cityid,
            h.star_rating,
            h.isactive,
            $statusSelect,
            COALESCE(pu.fullname, hu.fullname, p.ownername, p.companyname, '') AS ownername
        FROM hotels h
        LEFT JOIN partners p ON h.partnerid = p.partnerid
        $partnerUserJoin
        LEFT JOIN users hu ON h.uid = hu.userid
        $pendingWhere
        ORDER BY h.hotelid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch hotels');
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
admin_ensure_status_column($conn, 'hotels');

$hotelColumns = admin_columns($conn, 'hotels');
$statusCol = admin_col($hotelColumns, ['status', 'approvalstatus']);
$statusSelect = admin_status_expr('status', $hotelColumns, 'h');
$pendingWhere = $statusCol !== null
    ? "WHERE LOWER(COALESCE(h.`$statusCol`, 'pending')) = 'pending'"
    : "WHERE COALESCE(h.isactive, 0) = 0";
$partnerColumns = admin_table_exists($conn, 'partners') ? admin_columns($conn, 'partners') : [];
$partnerUserCol = admin_col($partnerColumns, ['userid', 'uid']);
$partnerUserJoin = $partnerUserCol !== null ? "LEFT JOIN users pu ON p.`$partnerUserCol` = pu.userid" : "";

$sql = "SELECT
            h.hotelid,
            h.hotelname,
            h.cityid,
            h.star_rating,
            h.isactive,
            $statusSelect,
            COALESCE(pu.fullname, hu.fullname, p.ownername, p.companyname, '') AS ownername
        FROM hotels h
        LEFT JOIN partners p ON h.partnerid = p.partnerid
        $partnerUserJoin
        LEFT JOIN users hu ON h.uid = hu.userid
        $pendingWhere
        ORDER BY h.hotelid DESC";

$result = $conn->query($sql);
if (!$result) {
    admin_error('Failed to fetch hotels');
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

