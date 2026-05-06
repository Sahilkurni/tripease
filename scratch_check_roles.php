<?php
require_once 'c:/xampp/htdocs/tripease_api/config/db.php';
$res = $conn->query('SELECT * FROM roles');
while($row = $res->fetch_assoc()) {
    echo "ID: " . $row['roleid'] . " - Name: " . $row['rolename'] . "\n";
}
?>
