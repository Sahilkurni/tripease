<?php
// backend_php/get_wishlist.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config/db.php';

$userid = $_GET['userid'] ?? '';

if (empty($userid)) {
    sendResponse("error", [], "User ID required.");
}

try {
    $wishlist = [];
    
    $sql = "SELECT w.id, w.item_type, w.item_id, 
            CASE 
                WHEN w.item_type = 'hotel' THEN h.hotelname 
                WHEN w.item_type = 'package' THEN p.packagename 
                WHEN w.item_type = 'bus' THEN b.bus_name
            END as name,
            CASE 
                WHEN w.item_type = 'hotel' THEN COALESCE((SELECT MIN(price) FROM hotel_rooms WHERE hotelid = h.hotelid), 0)
                WHEN w.item_type = 'package' THEN p.price 
                WHEN w.item_type = 'bus' THEN b.base_fare
            END as price,
            CASE 
                WHEN w.item_type = 'hotel' THEN h.star_rating 
                WHEN w.item_type = 'package' THEN 0 
                WHEN w.item_type = 'bus' THEN 0
            END as rating,
            (SELECT image FROM image_master im WHERE im.entity_type = w.item_type AND im.entity_id = w.item_id AND im.isactive = 1 ORDER BY im.is_primary DESC, im.imageid ASC LIMIT 1) as imageUrl
            FROM wishlist w
            LEFT JOIN hotels h ON w.item_id = h.hotelid AND w.item_type = 'hotel'
            LEFT JOIN packages p ON w.item_id = p.packageid AND w.item_type = 'package'
            LEFT JOIN buses b ON w.item_id = b.busid AND w.item_type = 'bus'
            WHERE w.userid = ? AND w.isactive = 1";
             
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        sendResponse("error", [], "Database error: " . $conn->error);
    }
    
    $stmt->bind_param("i", $userid);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        $row['id'] = intval($row['id']);
        $row['item_id'] = intval($row['item_id']);
        $row['price'] = floatval($row['price'] ?? 0);
        $row['rating'] = floatval($row['rating'] ?? 0);
        $wishlist[] = $row;
    }
    $stmt->close();

    sendResponse("success", $wishlist);
} catch (Exception $e) {
    sendResponse("error", [], $e->getMessage());
}
?>
