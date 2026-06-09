<?php
/**
 * migrate_buses.php
 * Run this once to add missing columns to buses and bus_seats tables.
 * Access via browser: http://YOUR_IP/tripease_api/migrate_buses.php
 */
header("Content-Type: text/html");
require_once __DIR__ . '/db.php';

$migrations = [
    // ── buses table: add missing columns ────────────────────────────────────
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS bus_number  VARCHAR(20)      DEFAULT ''",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS total_seats INT              DEFAULT 40",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS amenities   TEXT             DEFAULT ''",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS layout_type VARCHAR(10)      DEFAULT '2x2'",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS latitude    DECIMAL(10,8)    NULL",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS longitude   DECIMAL(11,8)    NULL",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS uid         INT              NULL",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS edatetime   DATETIME         DEFAULT CURRENT_TIMESTAMP",

    // ── bus_seats table: add missing columns ────────────────────────────────
    "ALTER TABLE bus_seats ADD COLUMN IF NOT EXISTS is_booked  TINYINT    DEFAULT 0",
    "ALTER TABLE bus_seats ADD COLUMN IF NOT EXISTS extra_fare DECIMAL(10,2) DEFAULT 0.00",

    // ── bookings table: ensure correct columns ───────────────────────────────
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS serviceid    INT          NULL",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS bookingtype  VARCHAR(20)  DEFAULT 'hotel'",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS booking_date DATE         NULL",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS status       VARCHAR(20)  DEFAULT 'confirmed'",

    // ── partners table ───────────────────────────────────────────────────────
    "CREATE TABLE IF NOT EXISTS partners (
        partnerid  INT AUTO_INCREMENT PRIMARY KEY,
        userid     INT,
        commission DECIMAL(5,2) DEFAULT 10.0,
        FOREIGN KEY (userid) REFERENCES users(userid)
    )",
];

echo "<h2>TripEase Bus Schema Migration</h2><ul>";
foreach ($migrations as $sql) {
    $short = substr($sql, 0, 80);
    if ($conn->query($sql)) {
        echo "<li style='color:green'>✓ $short …</li>";
    } else {
        echo "<li style='color:orange'>⚠ $short … — {$conn->error}</li>";
    }
}
echo "</ul><h3>Migration complete. You can now delete this file.</h3>";
?>
