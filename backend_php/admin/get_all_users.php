<?php
header('Content-Type: application/json');
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

$isAdmin = $authUser && (
    intval($authUser['roleid']) === 1 ||
    strtoupper(trim($authUser['rolename'] ?? '')) === 'ADMIN'
);

if (!$authUser || intval($authUser['isactive']) !== 1 || !$isAdmin) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Unauthorized access',
        'data' => null
    ]);
    exit;
}

$sql = "SELECT u.userid, u.fullname, u.email, u.roleid, r.rolename, u.isactive, u.edatetime
        FROM users u
        LEFT JOIN roles r ON r.roleid = u.roleid
        ORDER BY u.userid DESC";
$result = $conn->query($sql);

if (!$result) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to fetch users',
        'data' => null
    ]);
    exit;
}

$users = [];
while ($row = $result->fetch_assoc()) {
    $users[] = [
        'userid' => intval($row['userid']),
        'fullname' => $row['fullname'] ?? '',
        'email' => $row['email'] ?? '',
        'mobile' => '',
        'roleid' => intval($row['roleid'] ?? 0),
        'rolename' => $row['rolename'] ?? '',
        'isactive' => intval($row['isactive'] ?? 0),
        'edatetime' => $row['edatetime'] ?? null
    ];
}

echo json_encode([
    'status' => 'success',
    'data' => $users
]);

$conn->close();
?>
