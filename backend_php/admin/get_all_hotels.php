<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT h.hotelid, h.hotelname, h.star_rating, h.isactive, 
               p.ownername, p.companyname, c.cityname 
        FROM hotels h 
        LEFT JOIN partners p ON h.partnerid = p.partnerid 
        LEFT JOIN cities c ON h.cityid = c.cityid 
        ORDER BY h.hotelid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
