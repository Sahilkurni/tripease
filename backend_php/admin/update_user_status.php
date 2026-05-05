<?php
header('Content-Type: application/json');
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
$targetUserId = isset($_POST['target_userid']) ? intval($_POST['target_userid']) : 0;
$isActive = isset($_POST['isactive']) ? intval($_POST['isactive']) : -1;

if ($requestingUserId <= 0 || $targetUserId <= 0 || ($isActive !== 0 && $isActive !== 1)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'userid, target_userid and valid isactive are required',
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

$targetStmt = $conn->prepare('SELECT userid, roleid FROM users WHERE userid = ? LIMIT 1');
$targetStmt->bind_param('i', $targetUserId);
$targetStmt->execute();
$targetResult = $targetStmt->get_result();
$targetUser = $targetResult ? $targetResult->fetch_assoc() : null;
$targetStmt->close();

if (!$targetUser) {
    echo json_encode([
        'status' => 'error',
        'message' => 'User not found',
        'data' => null
    ]);
    exit;
}

$targetRoleStmt = $conn->prepare('SELECT r.rolename FROM roles r WHERE r.roleid = ? LIMIT 1');
$targetRoleStmt->bind_param('i', $targetUser['roleid']);
$targetRoleStmt->execute();
$targetRoleResult = $targetRoleStmt->get_result();
$targetRole = $targetRoleResult ? $targetRoleResult->fetch_assoc() : null;
$targetRoleStmt->close();
$targetIsAdmin = intval($targetUser['roleid']) === 1 || strtoupper(trim($targetRole['rolename'] ?? '')) === 'ADMIN';

if ($targetIsAdmin && $isActive === 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Admin user cannot be deactivated',
        'data' => null
    ]);
    exit;
}

$updateStmt = $conn->prepare('UPDATE users SET isactive = ?, edatetime = NOW() WHERE userid = ?');
$updateStmt->bind_param('ii', $isActive, $targetUserId);
$ok = $updateStmt->execute();
$updateStmt->close();

if (!$ok) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to update user status',
        'data' => null
    ]);
    exit;
}

echo json_encode([
    'status' => 'success',
    'data' => [
        'userid' => $targetUserId,
        'isactive' => $isActive
    ]
]);

$conn->close();
?>
