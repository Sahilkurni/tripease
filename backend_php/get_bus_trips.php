<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") { exit(0); }

require_once __DIR__ . '/config/db.php';

try {
    // buses table has both old (busname/bustype/totalseats) and new (bus_name/bus_type/total_seats/base_fare) columns.
    // Use COALESCE to prefer the new columns but fall back to old ones.
    $sql = "SELECT 
                b.busid,
                b.partnerid,
                COALESCE(NULLIF(b.bus_name,''), b.busname)       AS busname,
                COALESCE(NULLIF(b.bus_type,''), b.bustype)       AS bustype,
                COALESCE(b.busnumber, '')                        AS busnumber,
                COALESCE(b.total_seats, b.totalseats, 0)         AS totalseats,
                COALESCE(b.amenities, '')                        AS amenities,
                b.base_fare,
                b.base_fare                                      AS price,
                b.departure_time,
                b.arrival_time,
                b.layout_type,
                b.source_city_id,
                b.destination_city_id,
                b.latitude,
                b.longitude,
                b.status,
                b.isactive,
                b.uid,
                b.edatetime,
                sc.cityname  AS source_city_name,
                dc.cityname  AS destination_city_name
            FROM buses b
            LEFT JOIN cities sc ON b.source_city_id = sc.cityid
            LEFT JOIN cities dc ON b.destination_city_id = dc.cityid
            WHERE b.status = 'approved' AND b.isactive = 1
            ORDER BY b.busid DESC";

    $result = $conn->query($sql);
    $trips  = [];
    while ($row = $result->fetch_assoc()) {
        $trips[] = [
            'busid'               => intval($row['busid']),
            'tripid'              => intval($row['busid']),   // alias for Flutter BusModel
            'partnerid'           => intval($row['partnerid']),
            'busname'             => $row['busname'] ?? '',
            'bustype'             => $row['bustype'] ?? '',
            'busnumber'           => $row['busnumber'] ?? '',
            'totalseats'          => intval($row['totalseats']),
            'amenities'           => $row['amenities'] ?? '',
            'base_fare'           => floatval($row['base_fare']),
            'price'               => floatval($row['base_fare']),
            'departure_time'      => $row['departure_time']    ?? '',
            'arrival_time'        => $row['arrival_time']      ?? '',
            'layout_type'         => $row['layout_type']       ?? '2x2',
            'source_city_id'      => intval($row['source_city_id']      ?? 0),
            'destination_city_id' => intval($row['destination_city_id'] ?? 0),
            'latitude'            => $row['latitude']  !== null ? floatval($row['latitude'])  : null,
            'longitude'           => $row['longitude'] !== null ? floatval($row['longitude']) : null,
            'status'              => $row['status']    ?? 'approved',
            'isactive'            => intval($row['isactive']),
            'source_city_name'    => $row['source_city_name']    ?? '',
            'destination_city_name'=> $row['destination_city_name'] ?? '',
        ];
    }

    echo json_encode(['status' => 'success', 'data' => $trips]);
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
