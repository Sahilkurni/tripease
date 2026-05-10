<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/../db.php';

$userid = $_GET['userid'] ?? 0;
$created_by = $_GET['created_by'] ?? null;

try {
    $sql = "SELECT f.*, c1.cityname as from_city_name, c2.cityname as to_city_name 
            FROM flights f 
            JOIN cities c1 ON f.from_city = c1.cityid 
            JOIN cities c2 ON f.to_city = c2.cityid 
            WHERE f.isactive = 1";
            
    if ($created_by !== null) {
        $sql .= " AND f.created_by = " . intval($created_by);
    }
    
    $sql .= " ORDER BY f.flightid DESC";
    $result = $conn->query($sql);
    
    $flights = [];
    while ($row = $result->fetch_assoc()) {
        $flights[] = $row;
    }
    
    echo json_encode(['status' => 'success', 'data' => $flights]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
