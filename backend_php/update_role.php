<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php
// backend_php/update_role.php
require_once __DIR__ . '/config/db.php';


if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
    
    $userid = $_POST['userid'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($userid) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "Missing required fields."]);
        exit;
    }

    try {
        $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
        $roleStmt->execute([$roleid]);
        $roleRow = $roleStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$roleRow) {
            echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
            exit;
        }

        $rolename = $roleRow['rolename'];

        $updateStmt = $conn->prepare("UPDATE users SET roleid = ? WHERE userid = ?");
        $updateStmt->execute([$roleid, $userid]);

        echo json_encode([
            "status" => "success",
            "message" => "Role updated successfully.",
            "roleid" => (string)$roleid,
            "rolename" => $rolename
        ]);
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => "Update failed: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

// backend_php/update_role.php
require_once __DIR__ . '/config/db.php';


if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
    
    $userid = $_POST['userid'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($userid) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "Missing required fields."]);
        exit;
    }

    try {
        $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
        $roleStmt->execute([$roleid]);
        $roleRow = $roleStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$roleRow) {
            echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
            exit;
        }

        $rolename = $roleRow['rolename'];

        $updateStmt = $conn->prepare("UPDATE users SET roleid = ? WHERE userid = ?");
        $updateStmt->execute([$roleid, $userid]);

        echo json_encode([
            "status" => "success",
            "message" => "Role updated successfully.",
            "roleid" => (string)$roleid,
            "rolename" => $rolename
        ]);
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => "Update failed: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
}
?>

