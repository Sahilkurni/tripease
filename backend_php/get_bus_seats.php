<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

if (!isset($_GET['tripid'])) {
    echo json_encode(['status' => 'error', 'message' => 'tripid is required']);
    exit;
}

$tripid = intval($_GET['tripid']);

try {
    $sql = "SELECT seatid, seat_number, is_booked 
            FROM bus_seats 
            WHERE tripid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $tripid);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $seats = [];
    while ($row = $result->fetch_assoc()) {
        $seats[] = $row;
    }
    
    echo json_encode(['status' => 'success', 'data' => $seats]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
