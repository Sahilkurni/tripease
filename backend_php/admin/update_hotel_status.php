<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'hotels');

$hotelId = isset($_POST['hotelid']) ? intval($_POST['hotelid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($hotelId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('hotelid and valid status are required');
}
if (!admin_table_exists($conn, 'hotels')) {
    admin_error('Hotels table not found');
}

$columns = admin_columns($conn, 'hotels');
$hotelIdCol = admin_col($columns, ['hotelid', 'id']);
if ($hotelIdCol === null) {
    admin_error('Hotel id column not found');
}

$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
$isActive = $status === 'approved' ? 1 : 0;

if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$statusCol` = ?, `$activeCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $hotelId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$statusCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('si', $status, $hotelId);
} elseif ($activeCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$activeCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $hotelId);
} else {
    admin_error('No hotel status column found');
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update hotel');
}

admin_success(['hotelid' => $hotelId, 'status' => strtoupper($status)], 'Hotel status updated');
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'hotels');

$hotelId = isset($_POST['hotelid']) ? intval($_POST['hotelid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($hotelId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('hotelid and valid status are required');
}
if (!admin_table_exists($conn, 'hotels')) {
    admin_error('Hotels table not found');
}

$columns = admin_columns($conn, 'hotels');
$hotelIdCol = admin_col($columns, ['hotelid', 'id']);
if ($hotelIdCol === null) {
    admin_error('Hotel id column not found');
}

$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
$isActive = $status === 'approved' ? 1 : 0;

if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$statusCol` = ?, `$activeCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $hotelId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$statusCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('si', $status, $hotelId);
} elseif ($activeCol !== null) {
    $stmt = $conn->prepare("UPDATE hotels SET `$activeCol` = ? WHERE `$hotelIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $hotelId);
} else {
    admin_error('No hotel status column found');
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update hotel');
}

admin_success(['hotelid' => $hotelId, 'status' => strtoupper($status)], 'Hotel status updated');
?>

