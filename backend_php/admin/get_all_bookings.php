<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT b.bookingid, b.bookingno, b.bookingtype, b.finalamount, b.bookingstatus, b.paymentstatus,
               u.fullname as username, u.email 
        FROM bookings b 
        LEFT JOIN users u ON b.userid = u.userid 
        ORDER BY b.bookingid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
