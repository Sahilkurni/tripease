<?php
// backend_php/register.php
include 'db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = $_POST['fullname'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($fullname) || empty($email) || empty($password) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "All fields are required."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT userid FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Email already exists."]);
        exit;
    }

    $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
    $roleStmt->bind_param("i", $roleid);
    $roleStmt->execute();
    $roleResult = $roleStmt->get_result();

    if ($roleResult->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
        exit;
    }

    $roleRow = $roleResult->fetch_assoc();
    $rolename = $roleRow['rolename'];

    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    $uid = '0';

    $stmt = $conn->prepare("INSERT INTO users (fullname, email, password, roleid, uid, isactive) VALUES (?, ?, ?, ?, ?, 1)");
    $stmt->bind_param("sssii", $fullname, $email, $password_hash, $roleid, $uid);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Registration successful.",
            "userid" => (string)$stmt->insert_id,
            "fullname" => $fullname,
            "email" => $email,
            "roleid" => (string)$roleid,
            "rolename" => $rolename,
            "photo" => ""
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Registration failed."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?><?php
// backend_php/register.php
include 'db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = $_POST['fullname'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($fullname) || empty($email) || empty($password) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "All fields are required."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT userid FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Email already exists."]);
        exit;
    }

    $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
    $roleStmt->bind_param("i", $roleid);
    $roleStmt->execute();
    $roleResult = $roleStmt->get_result();

    if ($roleResult->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
        exit;
    }

    $roleRow = $roleResult->fetch_assoc();
    $rolename = $roleRow['rolename'];

    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    $uid = '0';

    $stmt = $conn->prepare("INSERT INTO users (fullname, email, password, roleid, uid, isactive) VALUES (?, ?, ?, ?, ?, 1)");
    $stmt->bind_param("sssii", $fullname, $email, $password_hash, $roleid, $uid);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Registration successful.",
            "userid" => (string)$stmt->insert_id,
            "fullname" => $fullname,
            "email" => $email,
            "roleid" => (string)$roleid,
            "rolename" => $rolename,
            "photo" => ""
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Registration failed."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?><?php
// backend_php/register.php
include 'db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = $_POST['fullname'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($fullname) || empty($email) || empty($password) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "All fields are required."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT userid FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Email already exists."]);
        exit;
    }

    $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
    $roleStmt->bind_param("i", $roleid);
    $roleStmt->execute();
    $roleResult = $roleStmt->get_result();

    if ($roleResult->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
        exit;
    }

    $roleRow = $roleResult->fetch_assoc();
    $rolename = $roleRow['rolename'];

    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    $uid = '0';

    $stmt = $conn->prepare("INSERT INTO users (fullname, email, password, roleid, uid, isactive) VALUES (?, ?, ?, ?, ?, 1)");
    $stmt->bind_param("sssii", $fullname, $email, $password_hash, $roleid, $uid);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Registration successful.",
            "userid" => (string)$stmt->insert_id,
            "fullname" => $fullname,
            "email" => $email,
            "roleid" => (string)$roleid,
            "rolename" => $rolename,
            "photo" => ""
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Registration failed."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?><?php
// backend_php/register.php
include 'db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = $_POST['fullname'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    $roleid = $_POST['roleid'] ?? '';

    if (empty($fullname) || empty($email) || empty($password) || empty($roleid)) {
        echo json_encode(["status" => "error", "message" => "All fields are required."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT userid FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Email already exists."]);
        exit;
    }

    $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
    $roleStmt->bind_param("i", $roleid);
    $roleStmt->execute();
    $roleResult = $roleStmt->get_result();

    if ($roleResult->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
        exit;
    }

    $roleRow = $roleResult->fetch_assoc();
    $rolename = $roleRow['rolename'];

    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    $uid = '0';

    $stmt = $conn->prepare("INSERT INTO users (fullname, email, password, roleid, uid, isactive) VALUES (?, ?, ?, ?, ?, 1)");
    $stmt->bind_param("sssii", $fullname, $email, $password_hash, $roleid, $uid);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Registration successful.",
            "userid" => (string)$stmt->insert_id,
            "fullname" => $fullname,
            "email" => $email,
            "roleid" => (string)$roleid,
            "rolename" => $rolename,
            "photo" => ""
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Registration failed."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?>
