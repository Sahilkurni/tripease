<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/db.php';

$lat = isset($_GET['lat']) ? floatval($_GET['lat']) : null;
$lng = isset($_GET['lng']) ? floatval($_GET['lng']) : null;
$radius = isset($_GET['radius']) ? floatval($_GET['radius']) : 50; // default 50km

if ($lat === null || $lng === null) {
    echo json_encode(['status' => 'error', 'message' => 'Latitude and Longitude are required']);
    exit;
}

try {
    $results = [
        'hotels' => [],
        'buses' => [],
        'packages' => [],
        'flights' => []
    ];

    // Haversine formula part
    $haversine = "( 6371 * acos( cos( radians($lat) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians($lng) ) + sin( radians($lat) ) * sin( radians( latitude ) ) ) )";

    // 1. Nearby Hotels
    $sql_hotels = "SELECT h.*, c.cityname, $haversine AS distance 
                   FROM hotels h 
                   LEFT JOIN cities c ON h.cityid = c.cityid 
                   WHERE h.status = 'approved' AND h.isactive = 1 AND latitude IS NOT NULL 
                   HAVING distance <= $radius 
                   ORDER BY distance ASC";
    $res_hotels = $conn->query($sql_hotels);
    if ($res_hotels) {
        while ($row = $res_hotels->fetch_assoc()) {
            $row['distance'] = round($row['distance'], 2);
            $results['hotels'][] = $row;
        }
    }

    // 2. Nearby Buses
    $sql_buses = "SELECT b.*, $haversine AS distance 
                  FROM buses b 
                  WHERE b.status = 'approved' AND b.isactive = 1 AND latitude IS NOT NULL 
                  HAVING distance <= $radius 
                  ORDER BY distance ASC";
    $res_buses = $conn->query($sql_buses);
    if ($res_buses) {
        while ($row = $res_buses->fetch_assoc()) {
            $row['distance'] = round($row['distance'], 2);
            $results['buses'][] = $row;
        }
    }

    // 3. Nearby Packages
    $sql_packages = "SELECT p.*, $haversine AS distance 
                     FROM packages p 
                     WHERE p.status = 'approved' AND p.isactive = 1 AND latitude IS NOT NULL 
                     HAVING distance <= $radius 
                     ORDER BY distance ASC";
    $res_packages = $conn->query($sql_packages);
    if ($res_packages) {
        while ($row = $res_packages->fetch_assoc()) {
            $row['distance'] = round($row['distance'], 2);
            $results['packages'][] = $row;
        }
    }

    // 4. Nearby Flights
    $sql_flights = "SELECT f.*, $haversine AS distance 
                    FROM flights f 
                    WHERE f.status = 'approved' AND f.isactive = 1 AND latitude IS NOT NULL 
                    HAVING distance <= $radius 
                    ORDER BY distance ASC";
    $res_flights = $conn->query($sql_flights);
    if ($res_flights) {
        while ($row = $res_flights->fetch_assoc()) {
            $row['distance'] = round($row['distance'], 2);
            $results['flights'][] = $row;
        }
    }

    echo json_encode(['status' => 'success', 'data' => $results]);

} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
