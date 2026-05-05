<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT t.ticketid, t.subject, t.status, t.edatetime as created_at,
               u.fullname as username, u.email 
        FROM support_tickets t 
        LEFT JOIN users u ON t.userid = u.userid 
        ORDER BY t.ticketid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
