<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/customer_helpers.php';

try {
    $userid = customer_require_userid($_GET);
    if (!customer_table_exists($conn, 'users')) {
        customer_error('Users table not found');
    }

    $columns = customer_columns($conn, 'users');
    $userIdCol = customer_col($columns, ['userid', 'id']);
    $nameCol = customer_col($columns, ['fullname', 'name']);
    $emailCol = customer_col($columns, ['email']);
    $roleIdCol = customer_col($columns, ['roleid']);
    $photoCol = customer_col($columns, ['profilephoto', 'photo']);

    if ($userIdCol === null) {
        customer_error('User id column not found');
    }

    $select = [
        $nameCol ? "COALESCE(u.`$nameCol`, '') AS name" : "'' AS name",
        $emailCol ? "COALESCE(u.`$emailCol`, '') AS email" : "'' AS email",
        $photoCol ? "COALESCE(u.`$photoCol`, '') AS profile_photo" : "'' AS profile_photo",
        "COALESCE(r.rolename, '') AS role"
    ];
    $join = $roleIdCol ? "LEFT JOIN roles r ON r.roleid = u.`$roleIdCol`" : "";
    $stmt = $conn->prepare("SELECT " . implode(', ', $select) . " FROM users u $join WHERE u.`$userIdCol` = ? LIMIT 1");
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();
    $profile = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    if (!$profile) {
        customer_error('User not found');
    }

    customer_success($profile);
} catch (Exception $e) {
    customer_error($e->getMessage());
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/customer_helpers.php';

try {
    $userid = customer_require_userid($_GET);
    if (!customer_table_exists($conn, 'users')) {
        customer_error('Users table not found');
    }

    $columns = customer_columns($conn, 'users');
    $userIdCol = customer_col($columns, ['userid', 'id']);
    $nameCol = customer_col($columns, ['fullname', 'name']);
    $emailCol = customer_col($columns, ['email']);
    $roleIdCol = customer_col($columns, ['roleid']);
    $photoCol = customer_col($columns, ['profilephoto', 'photo']);

    if ($userIdCol === null) {
        customer_error('User id column not found');
    }

    $select = [
        $nameCol ? "COALESCE(u.`$nameCol`, '') AS name" : "'' AS name",
        $emailCol ? "COALESCE(u.`$emailCol`, '') AS email" : "'' AS email",
        $photoCol ? "COALESCE(u.`$photoCol`, '') AS profile_photo" : "'' AS profile_photo",
        "COALESCE(r.rolename, '') AS role"
    ];
    $join = $roleIdCol ? "LEFT JOIN roles r ON r.roleid = u.`$roleIdCol`" : "";
    $stmt = $conn->prepare("SELECT " . implode(', ', $select) . " FROM users u $join WHERE u.`$userIdCol` = ? LIMIT 1");
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();
    $profile = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    if (!$profile) {
        customer_error('User not found');
    }

    customer_success($profile);
} catch (Exception $e) {
    customer_error($e->getMessage());
}
?>

