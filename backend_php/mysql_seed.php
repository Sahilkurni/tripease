<?php
// Seed sample data into MySQL `tripease_db` tables (hotels, buses, bookings).
// Usage (CLI): php mysql_seed.php
// Or open in browser: http://localhost/tripease_api/mysql_seed.php

// Load DB connection from db.php (defines $conn)
require_once __DIR__ . '/db.php';

function table_columns($conn, $table) {
    $cols = [];
    $res = $conn->query("SHOW COLUMNS FROM `" . $conn->real_escape_string($table) . "`");
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $cols[] = $row['Field'];
        }
    }
    return $cols;
}

function insert_compatible($conn, $table, $row) {
    $cols = table_columns($conn, $table);
    $use = [];
    $vals = [];
    foreach ($row as $k => $v) {
        if (in_array($k, $cols)) {
            $use[] = "`$k`";
            $vals[] = $conn->real_escape_string($v);
        }
    }
    if (empty($use)) return false;
    $sql = "INSERT INTO `$table` (" . implode(',', $use) . ") VALUES ('" . implode("','", $vals) . "')";
    return $conn->query($sql);
}

$inserted = [];

// Sample hotels (many keys to cover different schemas)
$hotels = [
    [
        'hotelname' => 'The Grand Tripease',
        'name' => 'The Grand Tripease',
        'description' => 'Premium hotel with sea view',
        'address' => 'Marine Drive, Mumbai',
        'city' => 'Mumbai',
        'cityid' => 1,
        'partnerid' => NULL,
        'star_rating' => 5,
        'latitude' => '18.9400',
        'longitude' => '72.8200',
        'checkintime' => '14:00',
        'checkouttime' => '11:00',
        'isactive' => 1
    ],
    [
        'hotelname' => 'Seaside Resort',
        'name' => 'Seaside Resort',
        'description' => 'Beachfront resort in Goa',
        'address' => 'Calangute Beach Road',
        'city' => 'Goa',
        'cityid' => 2,
        'star_rating' => 4,
        'isactive' => 1
    ],
    [
        'hotelname' => 'Hillview Inn',
        'name' => 'Hillview Inn',
        'description' => 'Cozy mountain hotel in Manali',
        'address' => 'Mall Road, Manali',
        'city' => 'Manali',
        'cityid' => 3,
        'star_rating' => 3,
        'isactive' => 1
    ],
];

foreach ($hotels as $h) {
    if (insert_compatible($conn, 'hotels', $h)) $inserted[] = ['hotels', $h['hotelname']];
}

// Sample buses
$buses = [
    [
        'operator' => 'VRL Travels',
        'operator_name' => 'VRL Travels',
        'source' => 'Pune',
        'destination' => 'Mumbai',
        'departure' => '21:00',
        'arrival' => '23:30',
        'seats' => 40,
        'fare' => 450.00,
        'isactive' => 1
    ],
    [
        'operator' => 'Zingbus',
        'operator_name' => 'Zingbus',
        'source' => 'Bangalore',
        'destination' => 'Hyderabad',
        'departure' => '20:00',
        'arrival' => '05:00',
        'seats' => 30,
        'fare' => 1250.50,
        'isactive' => 1
    ],
    [
        'operator' => 'Orange Tours',
        'operator_name' => 'Orange Tours',
        'source' => 'Delhi',
        'destination' => 'Jaipur',
        'departure' => '19:30',
        'arrival' => '22:30',
        'seats' => 45,
        'fare' => 550.00,
        'isactive' => 1
    ],
];

foreach ($buses as $b) {
    if (insert_compatible($conn, 'buses', $b)) $inserted[] = ['buses', $b['operator']];
}

// Sample bookings
$bookings = [
    [
        'userid' => NULL,
        'service' => 'hotel',
        'serviceid' => 1,
        'hotelid' => 1,
        'amount' => 4999.00,
        'status' => 'CONFIRMED'
    ],
    [
        'userid' => NULL,
        'service' => 'bus',
        'serviceid' => 2,
        'busid' => 2,
        'amount' => 1250.50,
        'status' => 'CONFIRMED'
    ],
    [
        'userid' => NULL,
        'service' => 'hotel',
        'serviceid' => 3,
        'hotelid' => 3,
        'amount' => 2999.00,
        'status' => 'CANCELLED'
    ],
];

foreach ($bookings as $bk) {
    if (insert_compatible($conn, 'bookings', $bk)) $inserted[] = ['bookings', $bk['service'] . ' ' . ($bk['serviceid'] ?? '')];
}

// Output result
header('Content-Type: application/json');
echo json_encode(['status' => 'done', 'inserted' => $inserted]);

?>
