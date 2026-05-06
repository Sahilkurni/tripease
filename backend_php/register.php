<?php
require_once __DIR__ . '/db.php';

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

    $roleid_int = (int)$roleid;

    $roleStmt = $conn->prepare("SELECT rolename FROM roles WHERE roleid = ?");
    $roleStmt->bind_param("i", $roleid_int);
    $roleStmt->execute();
    $roleResult = $roleStmt->get_result();

    if ($roleResult->num_rows === 0) {
        echo json_encode(["status" => "error", "message" => "Invalid role selected."]);
        exit;
    }

    $roleRow = $roleResult->fetch_assoc();
    $rolename = $roleRow['rolename'];

    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    
    // Check if password column is 'password' or 'password_hash'
    $cols_check = $conn->query("SHOW COLUMNS FROM users LIKE 'password_hash'");
    $pass_col = ($cols_check->num_rows > 0) ? 'password_hash' : 'password';

    $sql = "INSERT INTO users (fullname, email, $pass_col, roleid, isactive) VALUES (?, ?, ?, ?, 1)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssi", $fullname, $email, $password_hash, $roleid_int);

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
        echo json_encode(["status" => "error", "message" => "Registration failed: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?>
