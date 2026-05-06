<?php
require_once __DIR__ . '/db.php';

if (!isset($_GET['hotelid'])) {
    echo json_encode(['status' => 'error', 'message' => 'hotelid is required']);
    exit;
}

$hotelid = intval($_GET['hotelid']);

try {
    // Check if table exists
    $table_check = $conn->query("SHOW TABLES LIKE 'hotel_rooms'");
    if ($table_check->num_rows == 0) {
        throw new Exception("Table 'hotel_rooms' not found. Please run init_mysql.php");
    }

    $sql = "SELECT 
              r.roomid,
              r.roomtype,
              r.price,
              r.capacity,
              r.total_rooms,
              IFNULL(i.available_rooms, r.total_rooms) as available_rooms
            FROM hotel_rooms r
            LEFT JOIN hotel_room_inventory i ON r.roomid = i.roomid AND (i.date = CURDATE() OR i.date IS NULL)
            WHERE r.hotelid = ? AND r.isactive = 1";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("i", $hotelid);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $rooms = [];
    while ($row = $result->fetch_assoc()) {
        $rooms[] = $row;
    }
    
    echo json_encode([
        'status' => 'success',
        'data' => $rooms
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => []
    ]);
}
?>
