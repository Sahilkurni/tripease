<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT p.paymentid, p.bookingid, p.amount, p.paymentstatus, p.paiddate,
               b.bookingno
        FROM payments p 
        LEFT JOIN bookings b ON p.bookingid = b.bookingid 
        ORDER BY p.paymentid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
