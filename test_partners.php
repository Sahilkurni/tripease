<?php
require_once 'C:/xampp/htdocs/tripease_api/config/db.php';
$stmt = $pdo->prepare("SELECT * FROM partners WHERE uid = 22");
$stmt->execute();
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

$stmt2 = $pdo->prepare("SELECT * FROM users WHERE userid = 22");
$stmt2->execute();
print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
?>
