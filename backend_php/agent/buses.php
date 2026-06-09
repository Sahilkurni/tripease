<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") { exit(0); }

require_once __DIR__ . '/../config/db.php';

// ─── GET: list buses for partner or public search ──────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $partnerid   = isset($_GET['partnerid'])   ? intval($_GET['partnerid'])   : null;
    $source      = isset($_GET['source'])      ? trim($_GET['source'])        : null;
    $destination = isset($_GET['destination']) ? trim($_GET['destination'])   : null;

    try {
        $sql = "SELECT 
                    b.busid,
                    b.partnerid,
                    COALESCE(NULLIF(b.bus_name,''), b.busname)       AS busname,
                    COALESCE(NULLIF(b.bus_type,''), b.bustype)       AS bustype,
                    COALESCE(b.busnumber, '')                        AS busnumber,
                    COALESCE(b.total_seats, b.totalseats, 0)         AS totalseats,
                    COALESCE(b.amenities, '')                        AS amenities,
                    b.base_fare,
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
                WHERE b.isactive = 1";

        $params = [];
        $types  = '';

        if ($partnerid) {
            $sql .= " AND b.partnerid = ?";
            $params[] = $partnerid;
            $types   .= 'i';
        } else {
            $sql .= " AND b.status = 'approved'";
        }

        if ($source) {
            $sql .= " AND sc.cityname LIKE ?";
            $params[] = "%$source%";
            $types   .= 's';
        }
        if ($destination) {
            $sql .= " AND dc.cityname LIKE ?";
            $params[] = "%$destination%";
            $types   .= 's';
        }

        $sql .= " ORDER BY b.busid DESC";

        $stmt = $conn->prepare($sql);
        if ($params) {
            $stmt->bind_param($types, ...$params);
        }
        $stmt->execute();
        $result = $stmt->get_result();

        $buses = [];
        while ($row = $result->fetch_assoc()) {
            $buses[] = [
                'busid'               => intval($row['busid']),
                'tripid'              => intval($row['busid']),
                'partnerid'           => intval($row['partnerid']),
                'busname'             => $row['busname']  ?? '',
                'bustype'             => $row['bustype']  ?? '',
                'busnumber'           => $row['busnumber']?? '',
                'totalseats'          => intval($row['totalseats']),
                'amenities'           => $row['amenities']?? '',
                'base_fare'           => floatval($row['base_fare']),
                'price'               => floatval($row['base_fare']),
                'departure_time'      => $row['departure_time'] ?? '',
                'arrival_time'        => $row['arrival_time']   ?? '',
                'layout_type'         => $row['layout_type']    ?? '2x2',
                'source_city_id'      => intval($row['source_city_id']      ?? 0),
                'destination_city_id' => intval($row['destination_city_id'] ?? 0),
                'latitude'            => $row['latitude']  !== null ? floatval($row['latitude'])  : null,
                'longitude'           => $row['longitude'] !== null ? floatval($row['longitude']) : null,
                'status'              => $row['status']   ?? 'pending',
                'isactive'            => intval($row['isactive']),
                'uid'                 => isset($row['uid']) ? intval($row['uid']) : null,
                'edatetime'           => $row['edatetime'] ?? null,
                'source_city_name'    => $row['source_city_name']     ?? '',
                'destination_city_name'=> $row['destination_city_name']?? '',
            ];
        }

        echo json_encode(['status' => 'success', 'data' => $buses]);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
    exit;
}

// ─── POST: create / update / delete bus ───────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body   = json_decode(file_get_contents('php://input'), true) ?? [];
    $action = $body['action'] ?? 'create';

    try {
        // ── DELETE ────────────────────────────────────────────────────────
        if ($action === 'delete') {
            $busid     = intval($body['busid']     ?? 0);
            $partnerid = intval($body['partnerid'] ?? 0);
            $stmt = $conn->prepare("UPDATE buses SET isactive = 0 WHERE busid = ? AND partnerid = ?");
            $stmt->bind_param("ii", $busid, $partnerid);
            $stmt->execute();
            echo json_encode(['status' => 'success', 'message' => 'Bus deleted']);
            exit;
        }

        // ── Shared fields ─────────────────────────────────────────────────
        $partnerid           = intval($body['partnerid']          ?? 0);
        $bus_name            = trim($body['bus_name']             ?? '');
        $bus_type            = trim($body['bus_type']             ?? 'AC');
        $bus_number          = trim($body['bus_number']           ?? '');
        $layout_type         = trim($body['layout_type']          ?? '2x2');
        $source_city_id      = intval($body['source_city_id']     ?? 0);
        $destination_city_id = intval($body['destination_city_id']?? 0);
        $departure_time      = trim($body['departure_time']       ?? '');
        $arrival_time        = trim($body['arrival_time']         ?? '');
        $base_fare           = floatval($body['base_fare']        ?? 0);
        $total_seats         = intval($body['total_seats']        ?? 0);
        $amenities           = trim($body['amenities']            ?? '');
        $latitude            = isset($body['latitude'])  && $body['latitude']  !== null ? floatval($body['latitude'])  : null;
        $longitude           = isset($body['longitude']) && $body['longitude'] !== null ? floatval($body['longitude']) : null;
        $uid                 = isset($body['uid'])        && $body['uid']       !== null ? intval($body['uid'])         : null;

        // ── CREATE ────────────────────────────────────────────────────────
        if ($action === 'create') {
            $stmt = $conn->prepare("
                INSERT INTO buses 
                    (partnerid, bus_name, busname, bus_type, bustype, busnumber,
                     layout_type, source_city_id, destination_city_id,
                     departure_time, arrival_time, base_fare,
                     total_seats, totalseats, amenities,
                     latitude, longitude, uid, status, isactive)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 1)
            ");
            // i s s s s s s i i s s d i i s d d i  = 18 params
            $stmt->bind_param(
                "issssssiissdiisddi",
                $partnerid,
                $bus_name, $bus_name,       // bus_name + busname (both columns)
                $bus_type, $bus_type,        // bus_type + bustype
                $bus_number,
                $layout_type,
                $source_city_id, $destination_city_id,
                $departure_time, $arrival_time,
                $base_fare,
                $total_seats, $total_seats,  // total_seats + totalseats
                $amenities,
                $latitude, $longitude,
                $uid
            );
            $stmt->execute();
            $busid = $conn->insert_id;

            // Auto-generate seats
            _generateSeats($conn, $busid, $total_seats, $layout_type);

            echo json_encode(['status' => 'success', 'data' => ['busid' => $busid]]);
            exit;
        }

        // ── UPDATE ────────────────────────────────────────────────────────
        if ($action === 'update') {
            $busid = intval($body['busid'] ?? 0);
            $stmt = $conn->prepare("
                UPDATE buses SET
                    bus_name = ?, busname = ?,
                    bus_type = ?, bustype = ?,
                    busnumber  = ?,
                    layout_type = ?,
                    source_city_id = ?, destination_city_id = ?,
                    departure_time = ?, arrival_time = ?,
                    base_fare = ?,
                    total_seats = ?, totalseats = ?,
                    amenities = ?,
                    latitude = ?, longitude = ?
                WHERE busid = ? AND partnerid = ?
            ");
            // s s s s s s i i s s d i i s d d i i = 18 params
            $stmt->bind_param(
                "ssssssiiissddsddii",
                $bus_name, $bus_name,
                $bus_type, $bus_type,
                $bus_number,
                $layout_type,
                $source_city_id, $destination_city_id,
                $departure_time, $arrival_time,
                $base_fare,
                $total_seats, $total_seats,
                $amenities,
                $latitude, $longitude,
                $busid, $partnerid
            );
            $stmt->execute();

            echo json_encode(['status' => 'success', 'data' => ['busid' => $busid]]);
            exit;
        }

        echo json_encode(['status' => 'error', 'message' => 'Unknown action: ' . $action]);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
    exit;
}

echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);

// ─── Helper: auto-generate seats for a bus ─────────────────────────────────
function _generateSeats($conn, $busid, $total_seats, $layout_type) {
    // Delete existing seats first to avoid duplicates
    $del = $conn->prepare("DELETE FROM bus_seats WHERE busid = ?");
    $del->bind_param("i", $busid);
    $del->execute();

    // Cols per row based on layout
    $cols = 4; // default 2x2
    if ($layout_type === '3x2') $cols = 5;
    if ($layout_type === '2x1') $cols = 3;

    $seat_labels = ['A', 'B', 'C', 'D', 'E'];
    $seatCount   = 0;
    $rowNum      = 1;

    $ins = $conn->prepare("
        INSERT INTO bus_seats (busid, tripid, seat_no, seatno, row_no, col_no, is_sleeper, extra_fare, status, isactive)
        VALUES (?, ?, ?, ?, ?, ?, 0, 0.00, 'AVAILABLE', 1)
    ");

    while ($seatCount < $total_seats) {
        for ($col = 1; $col <= $cols && $seatCount < $total_seats; $col++) {
            $label  = $seat_labels[$col - 1] ?? chr(64 + $col);
            $seatNo = $label . $rowNum;
            $ins->bind_param("iissii", $busid, $busid, $seatNo, $seatNo, $rowNum, $col);
            $ins->execute();
            $seatCount++;
        }
        $rowNum++;
    }
}
?>
