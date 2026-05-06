<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'packages');

$packageId = isset($_POST['packageid']) ? intval($_POST['packageid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($packageId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('packageid and valid status are required');
}
if (!admin_table_exists($conn, 'packages')) {
    admin_error('Packages table not found');
}

$columns = admin_columns($conn, 'packages');
$packageIdCol = admin_col($columns, ['packageid', 'id']);
if ($packageIdCol === null) {
    admin_error('Package id column not found');
}

$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
$isActive = $status === 'approved' ? 1 : 0;

if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$statusCol` = ?, `$activeCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $packageId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$statusCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('si', $status, $packageId);
} elseif ($activeCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$activeCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $packageId);
} else {
    admin_error('No package status column found');
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update package');
}

admin_success(['packageid' => $packageId, 'status' => strtoupper($status)], 'Package status updated');
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('POST');
admin_require_user($conn, $_POST);
admin_ensure_status_column($conn, 'packages');

$packageId = isset($_POST['packageid']) ? intval($_POST['packageid']) : 0;
$status = strtolower(trim($_POST['status'] ?? ''));

if ($packageId <= 0 || !in_array($status, ['approved', 'rejected', 'pending'])) {
    admin_error('packageid and valid status are required');
}
if (!admin_table_exists($conn, 'packages')) {
    admin_error('Packages table not found');
}

$columns = admin_columns($conn, 'packages');
$packageIdCol = admin_col($columns, ['packageid', 'id']);
if ($packageIdCol === null) {
    admin_error('Package id column not found');
}

$statusCol = admin_col($columns, ['status', 'approvalstatus']);
$activeCol = admin_col($columns, ['isactive']);
$isActive = $status === 'approved' ? 1 : 0;

if ($statusCol !== null && $activeCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$statusCol` = ?, `$activeCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('sii', $status, $isActive, $packageId);
} elseif ($statusCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$statusCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('si', $status, $packageId);
} elseif ($activeCol !== null) {
    $stmt = $conn->prepare("UPDATE packages SET `$activeCol` = ? WHERE `$packageIdCol` = ?");
    $stmt->bind_param('ii', $isActive, $packageId);
} else {
    admin_error('No package status column found');
}

$ok = $stmt->execute();
$stmt->close();

if (!$ok) {
    admin_error('Failed to update package');
}

admin_success(['packageid' => $packageId, 'status' => strtoupper($status)], 'Package status updated');
?>

