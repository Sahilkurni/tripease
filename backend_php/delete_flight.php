<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

$flightid = $_POST['flightid'] ?? 0;
$userid = $_POST['userid'] ?? 0;

if (empty($flightid)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing flightid']);
    exit;
}

try {
    // Soft delete
    $sql = "UPDATE flights SET isactive = 0 WHERE flightid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $flightid);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Flight deleted successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to delete flight: ' . $stmt->error]);
    }
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
