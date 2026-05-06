<?php
require_once __DIR__ . '/db.php';

try {
    // Standardizing status column if it might be missing
    @$conn->query("ALTER TABLE packages ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending'");
    
    $sql = "SELECT p.*, c.cityname 
            FROM packages p 
            LEFT JOIN cities c ON p.cityid = c.cityid 
            WHERE p.isactive = 1 
            AND p.status = 'approved'
            ORDER BY p.packageid DESC 
            LIMIT 12";
            
    $result = $conn->query($sql);

    if (!$result) {
        $sql_alt = "SELECT * FROM packages WHERE isactive = 1 AND status = 'approved' ORDER BY packageid DESC LIMIT 12";
        $result = $conn->query($sql_alt);
    }

    $packages = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $packages[] = $row;
        }
    }

    echo json_encode([
        'status' => 'success',
        'data' => $packages
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => []
    ]);
}
?>
