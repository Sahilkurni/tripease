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

    // Fetch commission
    $commission_pct = 0;
    $commission_amt = 0;
    $c_stmt = $conn->prepare("
        SELECT p.commission 
        FROM hotels h 
        JOIN partners p ON h.partnerid = p.partnerid 
        WHERE h.hotelid = ?
    ");
    $c_stmt->bind_param("i", $hotelid);
    $c_stmt->execute();
    $c_res = $c_stmt->get_result();
    if ($c_row = $c_res->fetch_assoc()) {
        $commission_pct = floatval($c_row['commission']);
        $commission_amt = ($amount * $commission_pct) / 100.0;
    }
    
    $sql = "INSERT INTO bookings (userid, serviceid, amount, commission_pct, commission_amt, status, booking_date, bookingtype) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iidddsss", $userid, $hotelid, $amount, $commission_pct, $commission_amt, $status, $booking_date, $booking_type);
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
