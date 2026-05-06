<?php
require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'] ?? '';
    $fullname = $_POST['name'] ?? '';
    $photo = $_POST['photo'] ?? '';
    $firebase_uid = $_POST['firebase_uid'] ?? '';

    if (empty($email) || empty($firebase_uid)) {
        echo json_encode(["status" => "error", "message" => "Required data missing."]);
        exit;
    }

    // Check if user exists
    $stmt = $conn->prepare(
        "SELECT u.userid, u.fullname, u.email, u.photo, u.roleid, r.rolename
         FROM users u
         LEFT JOIN roles r ON u.roleid = r.roleid
         WHERE u.email = ?"
    );
    
    if (!$stmt) {
        echo json_encode(["status" => "error", "message" => "SQL Prepare Error: " . $conn->error]);
        exit;
    }
    
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if ($user) {
        // User exists, update firebase_uid if not set
        $updateStmt = $conn->prepare("UPDATE users SET firebase_uid = ? WHERE email = ? AND (firebase_uid IS NULL OR firebase_uid = '')");
        $updateStmt->bind_param("ss", $firebase_uid, $email);
        $updateStmt->execute();

        echo json_encode([
            "status" => "success",
            "message" => "User exists.",
            "is_new_user" => false,
            "userid" => (string)$user['userid'],
            "fullname" => $user['fullname'],
            "email" => $user['email'],
            "roleid" => $user['roleid'] ? (string)$user['roleid'] : '1',
            "rolename" => $user['rolename'] ?? 'CUSTOMER',
            "photo" => $user['photo'] ?? ''
        ]);
    } else {
        // Create new user
        $roleid = 1; // Default to CUSTOMER role
        
        // Find if password column exists
        $cols_check = $conn->query("SHOW COLUMNS FROM users LIKE 'password_hash'");
        $pass_col = ($cols_check->num_rows > 0) ? 'password_hash' : 'password';

        $insertStmt = $conn->prepare(
            "INSERT INTO users (firebase_uid, fullname, email, photo, $pass_col, roleid, isactive)
             VALUES (?, ?, ?, ?, '', ?, 1)"
        );
        
        if (!$insertStmt) {
            echo json_encode(["status" => "error", "message" => "SQL Insert Prepare Error: " . $conn->error]);
            exit;
        }
        
        $insertStmt->bind_param("ssssi", $firebase_uid, $fullname, $email, $photo, $roleid);

        if ($insertStmt->execute()) {
            $newUserId = $conn->insert_id;

            echo json_encode([
                "status" => "success",
                "message" => "New user created.",
                "is_new_user" => true,
                "userid" => (string)$newUserId,
                "fullname" => $fullname,
                "email" => $email,
                "roleid" => "1",
                "rolename" => "CUSTOMER",
                "photo" => $photo
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Failed to create user: " . $conn->error]);
        }
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method Request."]);
}
?>
