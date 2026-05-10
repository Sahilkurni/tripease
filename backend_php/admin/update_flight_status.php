<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/../db.php';

$flightid = $_POST['flightid'] ?? 0;
$status = $_POST['status'] ?? '';

if (empty($flightid) || empty($status)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing flightid or status']);
    exit;
}

try {
    $sql = "UPDATE flights SET status = ? WHERE flightid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $status, $flightid);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Flight status updated']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update status']);
    }
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
