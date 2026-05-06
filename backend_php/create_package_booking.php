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
$packageid = $_POST['packageid'] ?? null;
$amount = $_POST['amount'] ?? 0;
$status = 'confirmed';
$booking_date = date('Y-m-d');
$booking_type = 'package';

if (!$userid || !$packageid) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
    exit;
}

try {
    // Check if serviceid is used for package bookings in your schema
    // In create_bus_booking.php, serviceid was used for tripid.
    // For packages, we might use packageid or serviceid.
    // Let's use serviceid for consistency if that's how the table is structured,
    // but the user specifically said packageid in the payload description for hotel.
    // Wait, the user didn't specify package payload, but for hotel it was hotelid and roomid.
    // Let's stick to what's in the existing code but clean it up.
    
    $sql = "INSERT INTO bookings (userid, serviceid, amount, status, booking_date, bookingtype) 
            VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iidsss", $userid, $packageid, $amount, $status, $booking_date, $booking_type);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Package booking confirmed']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to create package booking']);
    }
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
