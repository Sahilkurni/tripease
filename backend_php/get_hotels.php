<?php
require_once __DIR__ . '/db.php';

try {
    $sql = "SELECT * FROM hotels WHERE isactive = 1 AND status = 'approved' ORDER BY hotelid DESC";
    $result = $conn->query($sql);
    
    $hotels = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $hotels[] = $row;
        }
    }
    
    echo json_encode([
        'status' => 'success',
        'data' => $hotels
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
