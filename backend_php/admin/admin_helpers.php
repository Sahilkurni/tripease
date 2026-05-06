<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php


require_once __DIR__ . '/../db.php';

function admin_json($payload) {
    echo json_encode($payload);
    exit;
}

function admin_error($message, $data = null) {
    admin_json([
        'status' => 'error',
        'message' => $message,
        'data' => $data
    ]);
}

function admin_success($data = [], $message = null) {
    $payload = [
        'status' => 'success',
        'data' => $data
    ];
    if ($message !== null) {
        $payload['message'] = $message;
    }
    admin_json($payload);
}

function admin_require_method($method) {
    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        admin_error('Invalid request method');
    }
}

function admin_require_user($conn, $source) {
    $userid = isset($source['userid']) ? intval($source['userid']) : 0;
    if ($userid <= 0) {
        admin_error('userid is required');
    }

    $stmt = $conn->prepare('SELECT u.roleid, u.isactive, r.rolename FROM users u LEFT JOIN roles r ON r.roleid = u.roleid WHERE u.userid = ? LIMIT 1');
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    $roleName = strtoupper(trim($user['rolename'] ?? ''));
    $roleId = intval($user['roleid'] ?? 0);
    $isAdmin = $user && ($roleName === 'ADMIN' || $roleId === 1 || $roleId === 4);

    if (!$user || intval($user['isactive'] ?? 0) !== 1 || !$isAdmin) {
        admin_error('Unauthorized access');
    }

    return $userid;
}

function admin_ensure_status_column($conn, $table) {
    if (!admin_table_exists($conn, $table)) {
        return false;
    }

    $columns = admin_columns($conn, $table);
    if (admin_col($columns, ['status', 'approvalstatus']) !== null) {
        return true;
    }

    $safeTable = str_replace('`', '', $table);
    return (bool) $conn->query(
        "ALTER TABLE `$safeTable` ADD COLUMN `status` ENUM('pending','approved','rejected') DEFAULT 'pending'"
    );
}

function admin_status_expr($alias, $columns, $tableAlias) {
    $statusCol = admin_col($columns, ['status', 'approvalstatus']);
    if ($statusCol !== null) {
        return "$tableAlias.`$statusCol` AS `$alias`";
    }
    return "'pending' AS `$alias`";
}

function admin_table_exists($conn, $table) {
    $safeTable = $conn->real_escape_string($table);
    $result = $conn->query("SHOW TABLES LIKE '$safeTable'");
    return $result && $result->num_rows > 0;
}

function admin_columns($conn, $table) {
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

function admin_col($columns, $candidates) {
    foreach ($candidates as $candidate) {
        $key = strtolower($candidate);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

function admin_select_expr($alias, $columns, $candidates, $fallback = "''", $prefix = '') {
    $column = admin_col($columns, $candidates);
    if ($column === null) {
        return "$fallback AS `$alias`";
    }
    return "COALESCE($prefix`$column`, $fallback) AS `$alias`";
}

function admin_int_select_expr($alias, $columns, $candidates, $fallback = '0', $prefix = '') {
    $column = admin_col($columns, $candidates);
    if ($column === null) {
        return "$fallback AS `$alias`";
    }
    return "COALESCE($prefix`$column`, $fallback) AS `$alias`";
}

function admin_rows($result) {
    $rows = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
    }
    return $rows;
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}



require_once __DIR__ . '/../db.php';

function admin_json($payload) {
    echo json_encode($payload);
    exit;
}

function admin_error($message, $data = null) {
    admin_json([
        'status' => 'error',
        'message' => $message,
        'data' => $data
    ]);
}

function admin_success($data = [], $message = null) {
    $payload = [
        'status' => 'success',
        'data' => $data
    ];
    if ($message !== null) {
        $payload['message'] = $message;
    }
    admin_json($payload);
}

function admin_require_method($method) {
    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        admin_error('Invalid request method');
    }
}

function admin_require_user($conn, $source) {
    $userid = isset($source['userid']) ? intval($source['userid']) : 0;
    if ($userid <= 0) {
        admin_error('userid is required');
    }

    $stmt = $conn->prepare('SELECT u.roleid, u.isactive, r.rolename FROM users u LEFT JOIN roles r ON r.roleid = u.roleid WHERE u.userid = ? LIMIT 1');
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    $roleName = strtoupper(trim($user['rolename'] ?? ''));
    $roleId = intval($user['roleid'] ?? 0);
    $isAdmin = $user && ($roleName === 'ADMIN' || $roleId === 1 || $roleId === 4);

    if (!$user || intval($user['isactive'] ?? 0) !== 1 || !$isAdmin) {
        admin_error('Unauthorized access');
    }

    return $userid;
}

function admin_ensure_status_column($conn, $table) {
    if (!admin_table_exists($conn, $table)) {
        return false;
    }

    $columns = admin_columns($conn, $table);
    if (admin_col($columns, ['status', 'approvalstatus']) !== null) {
        return true;
    }

    $safeTable = str_replace('`', '', $table);
    return (bool) $conn->query(
        "ALTER TABLE `$safeTable` ADD COLUMN `status` ENUM('pending','approved','rejected') DEFAULT 'pending'"
    );
}

function admin_status_expr($alias, $columns, $tableAlias) {
    $statusCol = admin_col($columns, ['status', 'approvalstatus']);
    if ($statusCol !== null) {
        return "$tableAlias.`$statusCol` AS `$alias`";
    }
    return "'pending' AS `$alias`";
}

function admin_table_exists($conn, $table) {
    $safeTable = $conn->real_escape_string($table);
    $result = $conn->query("SHOW TABLES LIKE '$safeTable'");
    return $result && $result->num_rows > 0;
}

function admin_columns($conn, $table) {
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

function admin_col($columns, $candidates) {
    foreach ($candidates as $candidate) {
        $key = strtolower($candidate);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

function admin_select_expr($alias, $columns, $candidates, $fallback = "''", $prefix = '') {
    $column = admin_col($columns, $candidates);
    if ($column === null) {
        return "$fallback AS `$alias`";
    }
    return "COALESCE($prefix`$column`, $fallback) AS `$alias`";
}

function admin_int_select_expr($alias, $columns, $candidates, $fallback = '0', $prefix = '') {
    $column = admin_col($columns, $candidates);
    if ($column === null) {
        return "$fallback AS `$alias`";
    }
    return "COALESCE($prefix`$column`, $fallback) AS `$alias`";
}

function admin_rows($result) {
    $rows = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
    }
    return $rows;
}
?>

