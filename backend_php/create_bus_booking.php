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
$tripid = $_POST['tripid'] ?? null;
$seatid = $_POST['seatid'] ?? null;
$amount = $_POST['amount'] ?? 0;
$booking_date = date('Y-m-d');

if (!$userid || !$tripid || !$seatid) {
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
        FROM buses b 
        JOIN partners p ON b.partnerid = p.partnerid 
        WHERE b.busid = ?
    ");
    $c_stmt->bind_param("i", $tripid);
    $c_stmt->execute();
    $c_res = $c_stmt->get_result();
    if ($c_row = $c_res->fetch_assoc()) {
        $commission_pct = floatval($c_row['commission']);
        $commission_amt = ($amount * $commission_pct) / 100.0;
    }

    // 1. Create booking
    $sql = "INSERT INTO bookings (userid, serviceid, amount, commission_pct, commission_amt, status, booking_date, bookingtype) 
            VALUES (?, ?, ?, ?, ?, 'confirmed', ?, 'bus')";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iiddds", $userid, $tripid, $amount, $commission_pct, $commission_amt, $booking_date);
    $stmt->execute();
    
    // 2. Mark seat as booked
    $sql_seat = "UPDATE bus_seats SET is_booked = 1 WHERE seatid = ? AND tripid = ?";
    $stmt_seat = $conn->prepare($sql_seat);
    $stmt_seat->bind_param("ii", $seatid, $tripid);
    $stmt_seat->execute();

    $conn->commit();
    echo json_encode(['status' => 'success', 'message' => 'Bus booking confirmed']);
} catch (Exception $e) {
    if ($conn->connect_errno == 0) {
        $conn->rollback();
    }
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
