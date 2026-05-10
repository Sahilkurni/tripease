<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

$flightid = $_POST['flightid'] ?? 0;
$airline = $_POST['airline'] ?? '';
$flight_number = $_POST['flight_number'] ?? '';
$from_city = $_POST['from_city'] ?? 0;
$to_city = $_POST['to_city'] ?? 0;
$departure_time = $_POST['departure_time'] ?? '';
$arrival_time = $_POST['arrival_time'] ?? '';
$duration = $_POST['duration'] ?? '';
$price = $_POST['price'] ?? 0;
$total_seats = $_POST['total_seats'] ?? 0;
$latitude = $_POST['latitude'] ?? null;
$longitude = $_POST['longitude'] ?? null;

if (empty($flightid) || empty($airline)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

try {
    $sql = "UPDATE flights SET 
            airline = ?, 
            flight_number = ?, 
            from_city = ?, 
            to_city = ?, 
            departure_time = ?, 
            arrival_time = ?, 
            duration = ?, 
            price = ?, 
            total_seats = ?, 
            latitude = ?, 
            longitude = ? 
            WHERE flightid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssiisssdiidd", $airline, $flight_number, $from_city, $to_city, $departure_time, $arrival_time, $duration, $price, $total_seats, $latitude, $longitude, $flightid);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Flight updated successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update flight: ' . $stmt->error]);
    }
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
