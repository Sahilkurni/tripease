<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/config/db.php';

try {
    $conn->query("ALTER TABLE buses ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending'");

    $sql = "SELECT busid, operator, source, destination, departure, arrival, seats, fare, isactive, status, edatetime
            FROM buses
            WHERE isactive = 1 AND LOWER(COALESCE(status, 'pending')) = 'approved'
            ORDER BY busid DESC";
    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to fetch buses',
            'data' => []
        ]);
        exit;
    }

    $buses = [];
    while ($row = $result->fetch_assoc()) {
        $buses[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'data' => $buses
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => []
    ]);
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/config/db.php';

try {
    $conn->query("ALTER TABLE buses ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending'");

    $sql = "SELECT busid, operator, source, destination, departure, arrival, seats, fare, isactive, status, edatetime
            FROM buses
            WHERE isactive = 1 AND LOWER(COALESCE(status, 'pending')) = 'approved'
            ORDER BY busid DESC";
    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to fetch buses',
            'data' => []
        ]);
        exit;
    }

    $buses = [];
    while ($row = $result->fetch_assoc()) {
        $buses[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'data' => $buses
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => []
    ]);
}
?>

