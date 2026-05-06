<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid request method',
        'data' => null
    ]);
    exit;
}

$requestingUserId = isset($_POST['userid']) ? intval($_POST['userid']) : 0;
$partnerId = isset($_POST['partnerid']) ? intval($_POST['partnerid']) : 0;
$status = strtoupper(trim($_POST['status'] ?? ''));
$commissionRaw = $_POST['commission'] ?? null;

if ($requestingUserId <= 0 || $partnerId <= 0 || !in_array($status, ['APPROVED', 'REJECTED'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'userid, partnerid and valid status are required',
        'data' => null
    ]);
    exit;
}

$commission = null;
if ($commissionRaw !== null && $commissionRaw !== '') {
    $commission = floatval($commissionRaw);
    if ($commission < 0 || $commission > 100) {
        echo json_encode([
            'status' => 'error',
            'message' => 'commission must be between 0 and 100',
            'data' => null
        ]);
        exit;
    }
}

$authStmt = $conn->prepare('SELECT u.roleid, u.isactive, r.rolename FROM users u LEFT JOIN roles r ON r.roleid = u.roleid WHERE u.userid = ? LIMIT 1');
$authStmt->bind_param('i', $requestingUserId);
$authStmt->execute();
$authResult = $authStmt->get_result();
$authUser = $authResult ? $authResult->fetch_assoc() : null;
$authStmt->close();

$isAdmin = $authUser && intval($authUser['roleid']) === 1;

if (!$authUser || intval($authUser['isactive']) !== 1 || !$isAdmin) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Unauthorized access',
        'data' => null
    ]);
    exit;
}

$partnerCheckStmt = $conn->prepare('SELECT partnerid FROM partners WHERE partnerid = ? LIMIT 1');
$partnerCheckStmt->bind_param('i', $partnerId);
$partnerCheckStmt->execute();
$partnerExistsResult = $partnerCheckStmt->get_result();
$partnerExists = $partnerExistsResult ? $partnerExistsResult->fetch_assoc() : null;
$partnerCheckStmt->close();

if (!$partnerExists) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Partner not found',
        'data' => null
    ]);
    exit;
}

if ($commission !== null) {
    $updateStmt = $conn->prepare('UPDATE partners SET status = ?, commission = ?, edatetime = NOW() WHERE partnerid = ?');
    $updateStmt->bind_param('sdi', $status, $commission, $partnerId);
} else {
    $updateStmt = $conn->prepare('UPDATE partners SET status = ?, edatetime = NOW() WHERE partnerid = ?');
    $updateStmt->bind_param('si', $status, $partnerId);
}

$ok = $updateStmt->execute();
$updateStmt->close();

if (!$ok) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update partner',
        'data' => null
    ]);
    exit;
}

echo json_encode([
    'status' => 'success',
    'data' => [
        'partnerid' => $partnerId,
        'status' => $status,
        'commission' => $commission
    ]
]);

$conn->close();
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid request method',
        'data' => null
    ]);
    exit;
}

$requestingUserId = isset($_POST['userid']) ? intval($_POST['userid']) : 0;
$partnerId = isset($_POST['partnerid']) ? intval($_POST['partnerid']) : 0;
$status = strtoupper(trim($_POST['status'] ?? ''));
$commissionRaw = $_POST['commission'] ?? null;

if ($requestingUserId <= 0 || $partnerId <= 0 || !in_array($status, ['APPROVED', 'REJECTED'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'userid, partnerid and valid status are required',
        'data' => null
    ]);
    exit;
}

$commission = null;
if ($commissionRaw !== null && $commissionRaw !== '') {
    $commission = floatval($commissionRaw);
    if ($commission < 0 || $commission > 100) {
        echo json_encode([
            'status' => 'error',
            'message' => 'commission must be between 0 and 100',
            'data' => null
        ]);
        exit;
    }
}

$authStmt = $conn->prepare('SELECT u.roleid, u.isactive, r.rolename FROM users u LEFT JOIN roles r ON r.roleid = u.roleid WHERE u.userid = ? LIMIT 1');
$authStmt->bind_param('i', $requestingUserId);
$authStmt->execute();
$authResult = $authStmt->get_result();
$authUser = $authResult ? $authResult->fetch_assoc() : null;
$authStmt->close();

$isAdmin = $authUser && intval($authUser['roleid']) === 1;

if (!$authUser || intval($authUser['isactive']) !== 1 || !$isAdmin) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Unauthorized access',
        'data' => null
    ]);
    exit;
}

$partnerCheckStmt = $conn->prepare('SELECT partnerid FROM partners WHERE partnerid = ? LIMIT 1');
$partnerCheckStmt->bind_param('i', $partnerId);
$partnerCheckStmt->execute();
$partnerExistsResult = $partnerCheckStmt->get_result();
$partnerExists = $partnerExistsResult ? $partnerExistsResult->fetch_assoc() : null;
$partnerCheckStmt->close();

if (!$partnerExists) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Partner not found',
        'data' => null
    ]);
    exit;
}

if ($commission !== null) {
    $updateStmt = $conn->prepare('UPDATE partners SET status = ?, commission = ?, edatetime = NOW() WHERE partnerid = ?');
    $updateStmt->bind_param('sdi', $status, $commission, $partnerId);
} else {
    $updateStmt = $conn->prepare('UPDATE partners SET status = ?, edatetime = NOW() WHERE partnerid = ?');
    $updateStmt->bind_param('si', $status, $partnerId);
}

$ok = $updateStmt->execute();
$updateStmt->close();

if (!$ok) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update partner',
        'data' => null
    ]);
    exit;
}

echo json_encode([
    'status' => 'success',
    'data' => [
        'partnerid' => $partnerId,
        'status' => $status,
        'commission' => $commission
    ]
]);

$conn->close();
?>

