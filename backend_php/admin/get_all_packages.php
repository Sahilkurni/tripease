<?php
require_once '../../config/db.php';
header('Content-Type: application/json');

try {
    $stmt = $pdo->query("
        SELECT pkg.packageid, pkg.packagename, pkg.price, pkg.days, pkg.isactive,
               p.ownername, p.companyname 
        FROM packages pkg 
        LEFT JOIN partners p ON pkg.partnerid = p.partnerid 
        ORDER BY pkg.packageid DESC
    ");
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
