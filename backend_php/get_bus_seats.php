<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") { exit(0); }

require_once __DIR__ . '/config/db.php';

// Accept either tripid or busid (they overlap in the current schema)
$busid = null;
if (isset($_GET['tripid'])) {
    $busid = intval($_GET['tripid']);
} elseif (isset($_GET['busid'])) {
    $busid = intval($_GET['busid']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'busid or tripid is required']);
    exit;
}

try {
    // seat_no, row_no, col_no, extra_fare, busid all exist in the new schema
    // is_booked is derived from status ENUM('AVAILABLE','BOOKED')
    $sql = "SELECT 
                seatid,
                busid,
                seat_no,
                row_no,
                col_no,
                COALESCE(is_sleeper, 0)                      AS is_sleeper,
                (status = 'BOOKED')                           AS is_booked,
                COALESCE(extra_fare, 0.00)                   AS extra_fare
            FROM bus_seats
            WHERE busid = ? AND COALESCE(isactive, 1) = 1
            ORDER BY row_no, col_no";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $busid);
    $stmt->execute();
    $result = $stmt->get_result();

    $seats = [];
    while ($row = $result->fetch_assoc()) {
        $seats[] = [
            'seatid'     => intval($row['seatid']),
            'busid'      => intval($row['busid']),
            'seat_no'    => $row['seat_no'],
            'row_no'     => intval($row['row_no']),
            'col_no'     => intval($row['col_no']),
            'is_sleeper' => intval($row['is_sleeper']),
            'is_booked'  => intval($row['is_booked']),
            'extra_fare' => floatval($row['extra_fare']),
        ];
    }

    echo json_encode(['status' => 'success', 'data' => $seats]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
