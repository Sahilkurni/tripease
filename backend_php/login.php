<?php
require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
    
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';

    if (empty($email) || empty($password)) {
        echo json_encode(["status" => "error", "message" => "Email and password required."]);
        exit;
    }

    try {
        // Find if password column is 'password' or 'password_hash'
        $cols_check = $conn->query("SHOW COLUMNS FROM users LIKE 'password_hash'");
        $pass_col = ($cols_check->num_rows > 0) ? 'password_hash' : 'password';

        $stmt = $conn->prepare(
            "SELECT u.userid, u.fullname, u.email, u.$pass_col as password, u.roleid, u.photo, u.isactive, r.rolename 
             FROM users u 
             LEFT JOIN roles r ON u.roleid = r.roleid 
             WHERE u.email = ?"
        );
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();

        if ($user) {
            if ($user['password'] != null && password_verify($password, $user['password'])) {
                if ($user['isactive'] == 0) {
                    echo json_encode(["status" => "error", "message" => "Account is deactivated."]);
                    exit;
                }
                echo json_encode([
                    "status" => "success",
                    "message" => "Login successful.",
                    "userid" => (string)$user['userid'],
                    "fullname" => $user['fullname'],
                    "email" => $user['email'],
                    "roleid" => (string)$user['roleid'],
                    "rolename" => $user['rolename'],
                    "photo" => $user['photo'] ?? ''
                ]);
            } else {
                echo json_encode(["status" => "error", "message" => "Invalid credentials."]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Invalid credentials."]);
        }
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => "Login failed: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
}
?>
