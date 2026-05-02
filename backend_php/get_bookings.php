<?php
header('Content-Type: application/json');
$dbPath = __DIR__ . '/tripease.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $db->query('SELECT bookingid, userid, service, serviceid, amount, status, bookdate FROM bookings ORDER BY bookingid DESC');
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>