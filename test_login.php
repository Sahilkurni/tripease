<?php
require 'C:\xampp\htdocs\tripease_api\config\db.php';
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute(['btest@gmail.com']);
print_r($stmt->fetch());
?>
