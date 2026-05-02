<?php
require 'c:/xampp/htdocs/tripease_api/config/db.php';
$stmt = $pdo->query('SHOW COLUMNS FROM partners');
print_r($stmt->fetchAll());
?>
