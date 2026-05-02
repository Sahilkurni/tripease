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

    // Create hotels table
    $db->exec(
        "CREATE TABLE IF NOT EXISTS hotels (
            hotelid INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            city TEXT,
            address TEXT,
            rooms INTEGER DEFAULT 0,
            price REAL DEFAULT 0,
            isactive INTEGER DEFAULT 1,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP
        )"
    );

    // Seed hotels if empty
    $checkHotels = $db->query("SELECT COUNT(*) FROM hotels");
    if ($checkHotels->fetchColumn() == 0) {
        $db->exec(
            "INSERT INTO hotels(name, city, address, rooms, price) VALUES
            ('The Grand Tripease', 'Mumbai', 'Marine Drive, Mumbai', 50, 4999.00),
            ('Seaside Resort', 'Goa', 'Calangute Beach Road', 30, 3499.50),
            ('Hillview Inn', 'Manali', 'Mall Road', 20, 2999.00)"
        );
    }

    // Create buses table
    $db->exec(
        "CREATE TABLE IF NOT EXISTS buses (
            busid INTEGER PRIMARY KEY AUTOINCREMENT,
            operator TEXT NOT NULL,
            source TEXT,
            destination TEXT,
            departure TEXT,
            arrival TEXT,
            seats INTEGER DEFAULT 0,
            fare REAL DEFAULT 0,
            isactive INTEGER DEFAULT 1,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP
        )"
    );

    // Seed buses if empty
    $checkBuses = $db->query("SELECT COUNT(*) FROM buses");
    if ($checkBuses->fetchColumn() == 0) {
        $db->exec(
            "INSERT INTO buses(operator, source, destination, departure, arrival, seats, fare) VALUES
            ('VRL Travels', 'Pune', 'Mumbai', '21:00', '23:30', 40, 450.00),
            ('Zingbus', 'Bangalore', 'Hyderabad', '20:00', '05:00', 30, 1250.50),
            ('Orange Tours', 'Delhi', 'Jaipur', '19:30', '22:30', 45, 550.00)"
        );
    }

    // Create bookings table
    $db->exec(
        "CREATE TABLE IF NOT EXISTS bookings (
            bookingid INTEGER PRIMARY KEY AUTOINCREMENT,
            userid INTEGER,
            service TEXT,
            serviceid INTEGER,
            amount REAL DEFAULT 0,
            status TEXT DEFAULT 'CONFIRMED',
            bookdate DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(userid) REFERENCES users(userid)
        )"
    );

    // Seed bookings if empty (creates sample bookings without user linkage)
    $checkBookings = $db->query("SELECT COUNT(*) FROM bookings");
    if ($checkBookings->fetchColumn() == 0) {
        $db->exec(
            "INSERT INTO bookings(userid, service, serviceid, amount, status) VALUES
            (NULL, 'hotel', 1, 4999.00, 'CONFIRMED'),
            (NULL, 'bus', 2, 1250.50, 'CONFIRMED'),
            (NULL, 'hotel', 3, 2999.00, 'CANCELLED')"
        );
    }

    echo json_encode(["status" => "success", "message" => "Database initialized successfully"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
