<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'buses');

$busId = isset($_POST['busid']) ? intval($_POST['busid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($busId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('busid and valid status are required');
}
if (!admin_table_exists($conn, 'buses')) {
    admin_error('Buses table not found');
}

$columns = admin_columns($conn, 'buses');
$busIdCol = admin_col($columns, ['busid', 'id']);
$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
if ($busIdCol === null || ($statusCol === null && $activeCol === null)) {
    admin_error('Bus status columns not found');
}

$isActive = $status === 'approved' ? 1 : 0;
if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE buses SET `$statusCol` = ?, `$activeCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $busId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE buses SET `$statusCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('si', $status, $busId);
} else {
    $stmt = $conn->prepare("UPDATE buses SET `$activeCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $busId);
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update bus');
}

admin_success(['busid' => $busId, 'status' => strtoupper($status)], 'Bus status updated');
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'buses');

$busId = isset($_POST['busid']) ? intval($_POST['busid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($busId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('busid and valid status are required');
}
if (!admin_table_exists($conn, 'buses')) {
    admin_error('Buses table not found');
}

$columns = admin_columns($conn, 'buses');
$busIdCol = admin_col($columns, ['busid', 'id']);
$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
if ($busIdCol === null || ($statusCol === null && $activeCol === null)) {
    admin_error('Bus status columns not found');
}

$isActive = $status === 'approved' ? 1 : 0;
if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE buses SET `$statusCol` = ?, `$activeCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $busId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE buses SET `$statusCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('si', $status, $busId);
} else {
    $stmt = $conn->prepare("UPDATE buses SET `$activeCol` = ? WHERE `$busIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $busId);
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update bus');
}

admin_success(['busid' => $busId, 'status' => strtoupper($status)], 'Bus status updated');
?>

