<?php
// Initialize SQLite database
$dbPath = __DIR__ . '/tripease.db';

// Create or open database
$db = new PDO("sqlite:" . $dbPath);
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Create tables
try {
    // Create roles table
    $db->exec("
        CREATE TABLE IF NOT EXISTS roles (
            roleid INTEGER PRIMARY KEY AUTOINCREMENT,
            rolename TEXT NOT NULL UNIQUE
        )
    ");

    // Create users table
    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            userid INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT,
            firebase_uid TEXT,
            fullname TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT,
            photo TEXT,
            roleid INTEGER,
            isactive INTEGER DEFAULT 1,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (roleid) REFERENCES roles(roleid)
        )
    ");

    // Insert default roles if they don't exist
    $checkRoles = $db->query("SELECT COUNT(*) FROM roles");
    if ($checkRoles->fetchColumn() == 0) {
        $db->exec("
            INSERT INTO roles(rolename) VALUES 
            ('CUSTOMER'), 
            ('HOTEL_OWNER'), 
            ('TRAVEL_AGENT'), 
            ('ADMIN')
        ");
    }

    echo json_encode(["status" => "success", "message" => "Database initialized successfully"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
