<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

try {
    $sql = "SELECT bt.tripid, bt.busid, b.busname, b.bustype, 
            bt.source, bt.destination, bt.departure_time, bt.arrival_time, bt.price
            FROM bus_trips bt
            JOIN buses b ON bt.busid = b.busid
            WHERE b.status = 'approved' AND b.isactive = 1";
    
    $result = $conn->query($sql);
    $trips = [];
    while ($row = $result->fetch_assoc()) {
        $trips[] = $row;
    }
    
    echo json_encode(['status' => 'success', 'data' => $trips]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
