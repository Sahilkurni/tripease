<?php
require_once 'c:/xampp/htdocs/tripease_api/config/db.php';

$sql = "CREATE TABLE IF NOT EXISTS wishlist (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    userid INT(11) NOT NULL,
    item_type ENUM('hotel', 'package', 'bus') NOT NULL,
    item_id INT(11) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    isactive TINYINT(1) DEFAULT 1,
    UNIQUE KEY (userid, item_type, item_id)
)";

if ($conn->query($sql)) {
    echo json_encode(["status" => "success", "message" => "Wishlist table created or already exists."]);
} else {
    echo json_encode(["status" => "error", "message" => "Error creating table: " . $conn->error]);
}
?>
