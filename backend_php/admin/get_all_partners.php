<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid request method',
        'data' => null
    ]);
    exit;
}

$requestingUserId = isset($_GET['userid']) ? intval($_GET['userid']) : 0;
if ($requestingUserId <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'userid is required',
        'data' => null
    ]);
    exit;
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

$partnersTableCheck = $conn->query("SHOW TABLES LIKE 'partners'");
if (!$partnersTableCheck || $partnersTableCheck->num_rows === 0) {
    echo json_encode([
        'status' => 'success',
        'data' => []
    ]);
    exit;
}

$partnerColumns = [];
$columnsResult = $conn->query("SHOW COLUMNS FROM partners");
if ($columnsResult) {
    while ($columnRow = $columnsResult->fetch_assoc()) {
        $partnerColumns[] = strtolower($columnRow['Field']);
    }
}

$citySelect = "''";
if (in_array('city', $partnerColumns)) {
    $citySelect = 'COALESCE(p.city, \'\')';
} elseif (in_array('cityname', $partnerColumns)) {
    $citySelect = 'COALESCE(p.cityname, \'\')';
}

$companySelect = in_array('companyname', $partnerColumns)
    ? "COALESCE(p.companyname, '')"
    : "''";
$statusSelect = in_array('status', $partnerColumns)
    ? "COALESCE(p.status, 'PENDING')"
    : "'PENDING'";
$commissionSelect = in_array('commission', $partnerColumns)
    ? "COALESCE(p.commission, 0)"
    : "0";
$partnerUserIdJoin = in_array('userid', $partnerColumns) ? 'p.userid' : '0';

$sql = "SELECT p.partnerid, $companySelect AS companyname, COALESCE(u.fullname, '') AS ownername,
               $citySelect AS city, $statusSelect AS status, $commissionSelect AS commission
        FROM partners p
        LEFT JOIN users u ON u.userid = $partnerUserIdJoin
        ORDER BY p.partnerid DESC";

$result = $conn->query($sql);
if (!$result) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to fetch partners',
        'data' => null
    ]);
    exit;
}

$partners = [];
while ($row = $result->fetch_assoc()) {
    $partners[] = [
        'partnerid' => intval($row['partnerid']),
        'companyname' => $row['companyname'] ?? '',
        'ownername' => $row['ownername'] ?? '',
        'city' => $row['city'] ?? '',
        'status' => strtoupper($row['status'] ?? 'PENDING'),
        'commission' => floatval($row['commission'] ?? 0)
    ];
}

echo json_encode([
    'status' => 'success',
    'data' => $partners
]);

$conn->close();
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid request method',
        'data' => null
    ]);
    exit;
}

$requestingUserId = isset($_GET['userid']) ? intval($_GET['userid']) : 0;
if ($requestingUserId <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'userid is required',
        'data' => null
    ]);
    exit;
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

$partnersTableCheck = $conn->query("SHOW TABLES LIKE 'partners'");
if (!$partnersTableCheck || $partnersTableCheck->num_rows === 0) {
    echo json_encode([
        'status' => 'success',
        'data' => []
    ]);
    exit;
}

$partnerColumns = [];
$columnsResult = $conn->query("SHOW COLUMNS FROM partners");
if ($columnsResult) {
    while ($columnRow = $columnsResult->fetch_assoc()) {
        $partnerColumns[] = strtolower($columnRow['Field']);
    }
}

$citySelect = "''";
if (in_array('city', $partnerColumns)) {
    $citySelect = 'COALESCE(p.city, \'\')';
} elseif (in_array('cityname', $partnerColumns)) {
    $citySelect = 'COALESCE(p.cityname, \'\')';
}

$companySelect = in_array('companyname', $partnerColumns)
    ? "COALESCE(p.companyname, '')"
    : "''";
$statusSelect = in_array('status', $partnerColumns)
    ? "COALESCE(p.status, 'PENDING')"
    : "'PENDING'";
$commissionSelect = in_array('commission', $partnerColumns)
    ? "COALESCE(p.commission, 0)"
    : "0";
$partnerUserIdJoin = in_array('userid', $partnerColumns) ? 'p.userid' : '0';

$sql = "SELECT p.partnerid, $companySelect AS companyname, COALESCE(u.fullname, '') AS ownername,
               $citySelect AS city, $statusSelect AS status, $commissionSelect AS commission
        FROM partners p
        LEFT JOIN users u ON u.userid = $partnerUserIdJoin
        ORDER BY p.partnerid DESC";

$result = $conn->query($sql);
if (!$result) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to fetch partners',
        'data' => null
    ]);
    exit;
}

$partners = [];
while ($row = $result->fetch_assoc()) {
    $partners[] = [
        'partnerid' => intval($row['partnerid']),
        'companyname' => $row['companyname'] ?? '',
        'ownername' => $row['ownername'] ?? '',
        'city' => $row['city'] ?? '',
        'status' => strtoupper($row['status'] ?? 'PENDING'),
        'commission' => floatval($row['commission'] ?? 0)
    ];
}

echo json_encode([
    'status' => 'success',
    'data' => $partners
]);

$conn->close();
?>

