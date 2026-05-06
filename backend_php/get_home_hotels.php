<?php
require_once __DIR__ . '/db.php';

try {
    $sql = "SELECT h.*, c.cityname
            FROM hotels h
            LEFT JOIN cities c ON h.cityid = c.cityid
            WHERE h.status = 'approved'
            AND h.isactive = 1
            ORDER BY h.hotelid DESC";
            
    $result = $conn->query($sql);

    if (!$result) {
        // If query fails, it might be because cities table is missing
        $sql_alt = "SELECT * FROM hotels WHERE status = 'approved' AND isactive = 1 ORDER BY hotelid DESC";
        $result = $conn->query($sql_alt);
    }

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
        'message' => $e->getMessage(),
        'data' => []
    ]);
}
?>
