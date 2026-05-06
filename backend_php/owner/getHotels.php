<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php
include '../db.php';


if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$partnerid = intval($_GET['partnerid'] ?? 0);

if ($partnerid <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'partnerid is required',
        'data' => []
    ]);
    exit;
}

try {
    $stmt = $conn->prepare(
        "SELECT hotelid, partnerid, hotelname, description, address, cityid,
                star_rating, latitude, longitude, checkintime, checkouttime,
                uid, edatetime, isactive
         FROM hotels
         WHERE partnerid = ?
         ORDER BY hotelid DESC"
    );
    $stmt->bind_param('i', $partnerid);
    $stmt->execute();
    $result = $stmt->get_result();

    $hotels = [];
    while ($row = $result->fetch_assoc()) {
        $hotels[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'Hotels fetched',
        'data' => $hotels
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'getHotels failed: ' . $e->getMessage(),
        'data' => []
    ]);
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

include '../db.php';


if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$partnerid = intval($_GET['partnerid'] ?? 0);

if ($partnerid <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'partnerid is required',
        'data' => []
    ]);
    exit;
}

try {
    $stmt = $conn->prepare(
        "SELECT hotelid, partnerid, hotelname, description, address, cityid,
                star_rating, latitude, longitude, checkintime, checkouttime,
                uid, edatetime, isactive
         FROM hotels
         WHERE partnerid = ?
         ORDER BY hotelid DESC"
    );
    $stmt->bind_param('i', $partnerid);
    $stmt->execute();
    $result = $stmt->get_result();

    $hotels = [];
    while ($row = $result->fetch_assoc()) {
        $hotels[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'Hotels fetched',
        'data' => $hotels
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'getHotels failed: ' . $e->getMessage(),
        'data' => []
    ]);
}
?>

