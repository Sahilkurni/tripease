<?php
// backend_php/db.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

$host = 'localhost';
$db_user = 'root';
$db_pass = 'Sahil@123';
$db_name = 'tripease_db';

$conn = new mysqli($host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// NOTE: Pre-requisite database tables:
/*
CREATE TABLE IF NOT EXISTS roles (
    roleid INT AUTO_INCREMENT PRIMARY KEY,
    rolename VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO roles(rolename) VALUES ('CUSTOMER'), ('HOTEL_OWNER'), ('TRAVEL_AGENT'), ('ADMIN');

CREATE TABLE IF NOT EXISTS users (
    userid INT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(100),
    firebase_uid VARCHAR(100),
    fullname VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    photo VARCHAR(255),
    roleid INT,
    isactive TINYINT DEFAULT 1,
    edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (roleid) REFERENCES roles(roleid)
);
*/
?>
