<?php
// backend_php/init_mysql.php
require_once __DIR__ . '/db.php';

echo "<h1>TripEase MySQL Initialization</h1>";

$queries = [
    "CREATE TABLE IF NOT EXISTS roles (
        roleid INT AUTO_INCREMENT PRIMARY KEY,
        rolename VARCHAR(50) NOT NULL UNIQUE
    )",
    "INSERT IGNORE INTO roles(rolename) VALUES ('CUSTOMER'), ('HOTEL_OWNER'), ('TRAVEL_AGENT'), ('ADMIN')",
    "CREATE TABLE IF NOT EXISTS users (
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
    )",
    "CREATE TABLE IF NOT EXISTS cities (
        cityid INT AUTO_INCREMENT PRIMARY KEY,
        cityname VARCHAR(100) NOT NULL UNIQUE
    )",
    "INSERT IGNORE INTO cities(cityname) VALUES ('Mumbai'), ('Goa'), ('Manali'), ('Bengaluru'), ('Delhi')",
    "CREATE TABLE IF NOT EXISTS hotels (
        hotelid INT AUTO_INCREMENT PRIMARY KEY,
        hotelname VARCHAR(100) NOT NULL,
        description TEXT,
        address TEXT,
        cityid INT,
        partnerid INT,
        star_rating DECIMAL(2,1) DEFAULT 0.0,
        starting_price DECIMAL(10,2) DEFAULT 0.0,
        status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
        isactive TINYINT DEFAULT 1,
        edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cityid) REFERENCES cities(cityid)
    )",
    "CREATE TABLE IF NOT EXISTS hotel_rooms (
        roomid INT AUTO_INCREMENT PRIMARY KEY,
        hotelid INT,
        roomtype VARCHAR(50),
        price DECIMAL(10,2),
        capacity INT,
        total_rooms INT,
        isactive TINYINT DEFAULT 1,
        FOREIGN KEY (hotelid) REFERENCES hotels(hotelid)
    )",
    "CREATE TABLE IF NOT EXISTS hotel_room_inventory (
        inventoryid INT AUTO_INCREMENT PRIMARY KEY,
        roomid INT,
        date DATE,
        available_rooms INT,
        FOREIGN KEY (roomid) REFERENCES hotel_rooms(roomid)
    )",
    "CREATE TABLE IF NOT EXISTS packages (
        packageid INT AUTO_INCREMENT PRIMARY KEY,
        packagename VARCHAR(100) NOT NULL,
        description TEXT,
        cityid INT,
        days INT,
        nights INT,
        price DECIMAL(10,2),
        status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
        isactive TINYINT DEFAULT 1,
        edatetime DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cityid) REFERENCES cities(cityid)
    )",
    "CREATE TABLE IF NOT EXISTS buses (
        busid INT AUTO_INCREMENT PRIMARY KEY,
        bus_name VARCHAR(100),
        bus_type VARCHAR(50),
        source_city_id INT,
        destination_city_id INT,
        departure_time TIME,
        arrival_time TIME,
        base_fare DECIMAL(10,2),
        status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
        isactive TINYINT DEFAULT 1,
        FOREIGN KEY (source_city_id) REFERENCES cities(cityid),
        FOREIGN KEY (destination_city_id) REFERENCES cities(cityid)
    )",
    "CREATE TABLE IF NOT EXISTS bus_seats (
        seatid INT AUTO_INCREMENT PRIMARY KEY,
        busid INT,
        seat_no VARCHAR(10),
        row_no INT,
        col_no INT,
        is_sleeper TINYINT DEFAULT 0,
        FOREIGN KEY (busid) REFERENCES buses(busid)
    )",
    "CREATE TABLE IF NOT EXISTS bookings (
        bookingid INT AUTO_INCREMENT PRIMARY KEY,
        userid INT,
        service_type ENUM('hotel', 'bus', 'package'),
        service_id INT,
        room_id INT,
        amount DECIMAL(10,2),
        booking_date DATE,
        status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending',
        FOREIGN KEY (userid) REFERENCES users(userid)
    )"
];

foreach ($queries as $sql) {
    if ($conn->query($sql)) {
        echo "<p style='color: green;'>Success: " . substr($sql, 0, 50) . "...</p>";
    } else {
        echo "<p style='color: red;'>Error: " . $conn->error . "<br>Query: $sql</p>";
    }
}

// Seed some data if empty
$res = $conn->query("SELECT COUNT(*) as count FROM hotels");
$row = $res->fetch_assoc();
if ($row['count'] == 0) {
    $conn->query("INSERT INTO hotels (hotelname, description, address, cityid, star_rating, starting_price, status) VALUES 
        ('The Grand Tripease', 'Luxury stay', 'Marine Drive', 1, 5.0, 4999.00, 'approved'),
        ('BCA hotel', 'Budget stay', 'College Road', 4, 4.5, 1200.00, 'approved')");
        
    $h1 = $conn->insert_id;
    $conn->query("INSERT INTO hotel_rooms (hotelid, roomtype, price, capacity, total_rooms) VALUES 
        ($h1, 'Deluxe Suite', 4999.00, 2, 10),
        ($h1, 'Standard Room', 2999.00, 2, 20)");
    
    // Get room ids for inventory
    $res_rooms = $conn->query("SELECT roomid FROM hotel_rooms WHERE hotelid = $h1");
    while($r = $res_rooms->fetch_assoc()) {
        $rid = $r['roomid'];
        $conn->query("INSERT INTO hotel_room_inventory (roomid, date, available_rooms) VALUES ($rid, CURDATE(), 5)");
    }
        
    echo "<p>Sample data seeded.</p>";
}

echo "<h3>Initialization Complete!</h3>";
?>
