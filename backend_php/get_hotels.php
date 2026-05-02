<?php
header('Content-Type: application/json');
$dbPath = __DIR__ . '/tripease.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $db->query('SELECT hotelid, name, city, address, rooms, price, isactive, edatetime FROM hotels ORDER BY hotelid DESC');
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>