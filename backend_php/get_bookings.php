<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/config/db.php';

function table_columns($conn, $table) {
    $result = $conn->query("SHOW COLUMNS FROM `$table`");
    $columns = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[strtolower($row['Field'])] = $row['Field'];
        }
    }
    return $columns;
}

function col($columns, $names) {
    foreach ($names as $name) {
        $key = strtolower($name);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

try {
    $tableCheck = $conn->query("SHOW TABLES LIKE 'bookings'");
    if (!$tableCheck || $tableCheck->num_rows === 0) {
        echo json_encode(['status' => 'success', 'data' => []]);
        exit;
    }

    $columns = table_columns($conn, 'bookings');
    $bookingId = col($columns, ['bookingid', 'id']);
    $userId = col($columns, ['userid']);
    $type = col($columns, ['bookingtype', 'service', 'type']);
    $amount = col($columns, ['finalamount', 'totalamount', 'amount']);
    $status = col($columns, ['bookingstatus', 'status']);
    $date = col($columns, ['bookdate', 'edatetime', 'created_at']);

    $select = [];
    $select[] = $bookingId ? "`$bookingId` AS bookingid" : "0 AS bookingid";
    $select[] = $userId ? "`$userId` AS userid" : "0 AS userid";
    $select[] = $type ? "COALESCE(`$type`, 'Booking') AS bookingtype" : "'Booking' AS bookingtype";
    $select[] = $amount ? "COALESCE(`$amount`, 0) AS amount" : "0 AS amount";
    $select[] = $status ? "COALESCE(`$status`, 'PENDING') AS status" : "'PENDING' AS status";
    $select[] = $date ? "COALESCE(`$date`, '') AS bookdate" : "'' AS bookdate";

    $userid = isset($_GET['userid']) ? intval($_GET['userid']) : 0;
    $sql = 'SELECT ' . implode(', ', $select) . ' FROM bookings';
    $order = $bookingId ? " ORDER BY `$bookingId` DESC" : '';

    if ($userid > 0 && $userId) {
        $stmt = $conn->prepare($sql . " WHERE `$userId` = ? $order LIMIT 10");
        $stmt->bind_param('i', $userid);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        $result = $conn->query($sql . "$order LIMIT 10");
    }

    if (!$result) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to fetch bookings', 'data' => []]);
        exit;
    }

    $bookings = [];
    while ($row = $result->fetch_assoc()) {
        $bookings[] = $row;
    }

    echo json_encode(['status' => 'success', 'data' => $bookings]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage(), 'data' => []]);
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/config/db.php';

function table_columns($conn, $table) {
    $result = $conn->query("SHOW COLUMNS FROM `$table`");
    $columns = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[strtolower($row['Field'])] = $row['Field'];
        }
    }
    return $columns;
}

function col($columns, $names) {
    foreach ($names as $name) {
        $key = strtolower($name);
        if (isset($columns[$key])) {
            return $columns[$key];
        }
    }
    return null;
}

try {
    $tableCheck = $conn->query("SHOW TABLES LIKE 'bookings'");
    if (!$tableCheck || $tableCheck->num_rows === 0) {
        echo json_encode(['status' => 'success', 'data' => []]);
        exit;
    }

    $columns = table_columns($conn, 'bookings');
    $bookingId = col($columns, ['bookingid', 'id']);
    $userId = col($columns, ['userid']);
    $type = col($columns, ['bookingtype', 'service', 'type']);
    $amount = col($columns, ['finalamount', 'totalamount', 'amount']);
    $status = col($columns, ['bookingstatus', 'status']);
    $date = col($columns, ['bookdate', 'edatetime', 'created_at']);

    $select = [];
    $select[] = $bookingId ? "`$bookingId` AS bookingid" : "0 AS bookingid";
    $select[] = $userId ? "`$userId` AS userid" : "0 AS userid";
    $select[] = $type ? "COALESCE(`$type`, 'Booking') AS bookingtype" : "'Booking' AS bookingtype";
    $select[] = $amount ? "COALESCE(`$amount`, 0) AS amount" : "0 AS amount";
    $select[] = $status ? "COALESCE(`$status`, 'PENDING') AS status" : "'PENDING' AS status";
    $select[] = $date ? "COALESCE(`$date`, '') AS bookdate" : "'' AS bookdate";

    $userid = isset($_GET['userid']) ? intval($_GET['userid']) : 0;
    $sql = 'SELECT ' . implode(', ', $select) . ' FROM bookings';
    $order = $bookingId ? " ORDER BY `$bookingId` DESC" : '';

    if ($userid > 0 && $userId) {
        $stmt = $conn->prepare($sql . " WHERE `$userId` = ? $order LIMIT 10");
        $stmt->bind_param('i', $userid);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        $result = $conn->query($sql . "$order LIMIT 10");
    }

    if (!$result) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to fetch bookings', 'data' => []]);
        exit;
    }

    $bookings = [];
    while ($row = $result->fetch_assoc()) {
        $bookings[] = $row;
    }

    echo json_encode(['status' => 'success', 'data' => $bookings]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage(), 'data' => []]);
}
?>

