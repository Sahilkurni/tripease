<?php
require_once 'C:/xampp/htdocs/tripease_api/config/db.php';

$stmt = $pdo->prepare("SELECT * FROM buses WHERE busname LIKE '%New Bus%' OR bus_name LIKE '%New Bus%'");
$stmt->execute();
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
