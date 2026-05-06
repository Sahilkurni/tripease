<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php
require_once __DIR__ . '/config/db.php';

function customer_json($payload) {
    echo json_encode($payload);
    exit;
}

function customer_success($data = [], $message = null) {
    $payload = [
        'status' => 'success',
        'data' => $data
    ];
    if ($message !== null) {
        $payload['message'] = $message;
    }
    customer_json($payload);
}

function customer_error($message, $data = []) {
    customer_json([
        'status' => 'error',
        'message' => $message,
        'data' => $data
    ]);
}

function customer_table_exists($conn, $table) {
    $safeTable = $conn->real_escape_string($table);
    $result = $conn->query("SHOW TABLES LIKE '$safeTable'");
    return $result && $result->num_rows > 0;
}

function customer_columns($conn, $table) {
    $safeTable = str_replace('`', '', $table);
    $result = $conn->query("SHOW COLUMNS FROM `$safeTable`");
    $columns = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[strtolower($row['Field'])] = $row['Field'];
        }
    }
    return $columns;
}

function customer_col($columns, $candidates) {
    foreach ($candidates as $candidate) {
        $key = strtolower($candidate);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

function customer_require_userid($source) {
    $userid = isset($source['userid']) ? intval($source['userid']) : 0;
    if ($userid <= 0) {
        customer_error('userid is required');
    }
    return $userid;
}

function customer_ensure_wishlist($conn) {
    $conn->query(
        "CREATE TABLE IF NOT EXISTS wishlist (
            id INT AUTO_INCREMENT PRIMARY KEY,
            userid INT NOT NULL,
            item_type ENUM('hotel','package') NOT NULL,
            item_id INT NOT NULL,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_wishlist_item (userid, item_type, item_id)
        )"
    );
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/config/db.php';

function customer_json($payload) {
    echo json_encode($payload);
    exit;
}

function customer_success($data = [], $message = null) {
    $payload = [
        'status' => 'success',
        'data' => $data
    ];
    if ($message !== null) {
        $payload['message'] = $message;
    }
    customer_json($payload);
}

function customer_error($message, $data = []) {
    customer_json([
        'status' => 'error',
        'message' => $message,
        'data' => $data
    ]);
}

function customer_table_exists($conn, $table) {
    $safeTable = $conn->real_escape_string($table);
    $result = $conn->query("SHOW TABLES LIKE '$safeTable'");
    return $result && $result->num_rows > 0;
}

function customer_columns($conn, $table) {
    $safeTable = str_replace('`', '', $table);
    $result = $conn->query("SHOW COLUMNS FROM `$safeTable`");
    $columns = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[strtolower($row['Field'])] = $row['Field'];
        }
    }
    return $columns;
}

function customer_col($columns, $candidates) {
    foreach ($candidates as $candidate) {
        $key = strtolower($candidate);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

function customer_require_userid($source) {
    $userid = isset($source['userid']) ? intval($source['userid']) : 0;
    if ($userid <= 0) {
        customer_error('userid is required');
    }
    return $userid;
}

function customer_ensure_wishlist($conn) {
    $conn->query(
        "CREATE TABLE IF NOT EXISTS wishlist (
            id INT AUTO_INCREMENT PRIMARY KEY,
            userid INT NOT NULL,
            item_type ENUM('hotel','package') NOT NULL,
            item_id INT NOT NULL,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_wishlist_item (userid, item_type, item_id)
        )"
    );
}
?>

