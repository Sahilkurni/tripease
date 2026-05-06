<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$userid = $_POST['userid'] ?? null;
$hotelid = $_POST['hotelid'] ?? null;
$roomid = $_POST['roomid'] ?? null;
$booking_date = $_POST['booking_date'] ?? date('Y-m-d');
$amount = $_POST['amount'] ?? 0;
$status = 'confirmed';
$booking_type = 'hotel';

if (!$userid || !$hotelid || !$roomid) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

try {
    $conn->begin_transaction();

    // 1. Create booking
    // Using serviceid for hotelid to keep consistency with other bookings if needed,
    // but the schema might have specific columns. Let's check consistency.
    // In create_bus_booking, it used serviceid for tripid.
    // Let's use specific columns if they exist, or serviceid.
    // Based on previous code, it used hotelid and roomid.
    
    $sql = "INSERT INTO bookings (userid, serviceid, amount, status, booking_date, bookingtype) 
            VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iidsss", $userid, $hotelid, $amount, $status, $booking_date, $booking_type);
    $stmt->execute();
    
    // 2. Update inventory
    $sql_inv = "UPDATE hotel_room_inventory SET available_rooms = available_rooms - 1 WHERE roomid = ? AND available_rooms > 0";
    $stmt_inv = $conn->prepare($sql_inv);
    $stmt_inv->bind_param("i", $roomid);
    $stmt_inv->execute();

    if ($conn->affected_rows === 0) {
        throw new Exception("No rooms available or invalid roomid");
    }

    $conn->commit();
    echo json_encode(['status' => 'success', 'message' => 'Hotel booking confirmed']);
} catch (Exception $e) {
    if ($conn->connect_errno == 0) {
        $conn->rollback();
    }
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
