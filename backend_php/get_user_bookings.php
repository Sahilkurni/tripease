<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/customer_helpers.php';

try {
    $userid = customer_require_userid($_GET);
    if (!customer_table_exists($conn, 'bookings')) {
        customer_success([]);
    }

    $columns = customer_columns($conn, 'bookings');
    $bookingIdCol = customer_col($columns, ['bookingid', 'id']);
    $userIdCol = customer_col($columns, ['userid']);
    $typeCol = customer_col($columns, ['bookingtype', 'service', 'type', 'item_type']);
    $serviceIdCol = customer_col($columns, ['serviceid', 'item_id']);
    $hotelIdCol = customer_col($columns, ['hotelid']);
    $packageIdCol = customer_col($columns, ['packageid']);
    $amountCol = customer_col($columns, ['finalamount', 'totalamount', 'amount']);
    $statusCol = customer_col($columns, ['bookingstatus', 'status']);
    $dateCol = customer_col($columns, ['bookdate', 'bookingdate', 'created_at', 'edatetime']);

    if ($userIdCol === null) {
        customer_success([]);
    }

    $bookingId = $bookingIdCol ? "b.`$bookingIdCol`" : "0";
    $typeExpr = $typeCol ? "LOWER(COALESCE(b.`$typeCol`, 'booking'))" : "'booking'";
    $serviceIdExpr = $serviceIdCol ? "b.`$serviceIdCol`" : "0";
    $hotelJoinId = $hotelIdCol ? "b.`$hotelIdCol`" : $serviceIdExpr;
    $packageJoinId = $packageIdCol ? "b.`$packageIdCol`" : $serviceIdExpr;
    $hotelJoinCondition = $hotelIdCol
        ? "h.hotelid = $hotelJoinId"
        : "(($typeExpr LIKE '%hotel%') AND h.hotelid = $hotelJoinId)";
    $packageJoinCondition = $packageIdCol
        ? "p.packageid = $packageJoinId"
        : "(($typeExpr LIKE '%package%') AND p.packageid = $packageJoinId)";
    $amountExpr = $amountCol ? "COALESCE(b.`$amountCol`, 0)" : "0";
    $statusExpr = $statusCol ? "COALESCE(b.`$statusCol`, 'PENDING')" : "'PENDING'";
    $dateExpr = $dateCol ? "COALESCE(b.`$dateCol`, '')" : "''";

    $sql = "SELECT
                $bookingId AS booking_id,
                CASE
                    WHEN $typeExpr LIKE '%hotel%' THEN 'Hotel'
                    WHEN $typeExpr LIKE '%package%' THEN 'Package'
                    ELSE 'Booking'
                END AS item_type,
                COALESCE(h.hotelname, p.packagename, CONCAT('Booking #', $bookingId)) AS item_name,
                $dateExpr AS date,
                $amountExpr AS amount,
                $statusExpr AS status
            FROM bookings b
            LEFT JOIN hotels h ON $hotelJoinCondition
            LEFT JOIN packages p ON $packageJoinCondition
            WHERE b.`$userIdCol` = ?
            ORDER BY $bookingId DESC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    while ($result && $row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();

    customer_success($rows);
} catch (Exception $e) {
    customer_error($e->getMessage(), []);
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/customer_helpers.php';

try {
    $userid = customer_require_userid($_GET);
    if (!customer_table_exists($conn, 'bookings')) {
        customer_success([]);
    }

    $columns = customer_columns($conn, 'bookings');
    $bookingIdCol = customer_col($columns, ['bookingid', 'id']);
    $userIdCol = customer_col($columns, ['userid']);
    $typeCol = customer_col($columns, ['bookingtype', 'service', 'type', 'item_type']);
    $serviceIdCol = customer_col($columns, ['serviceid', 'item_id']);
    $hotelIdCol = customer_col($columns, ['hotelid']);
    $packageIdCol = customer_col($columns, ['packageid']);
    $amountCol = customer_col($columns, ['finalamount', 'totalamount', 'amount']);
    $statusCol = customer_col($columns, ['bookingstatus', 'status']);
    $dateCol = customer_col($columns, ['bookdate', 'bookingdate', 'created_at', 'edatetime']);

    if ($userIdCol === null) {
        customer_success([]);
    }

    $bookingId = $bookingIdCol ? "b.`$bookingIdCol`" : "0";
    $typeExpr = $typeCol ? "LOWER(COALESCE(b.`$typeCol`, 'booking'))" : "'booking'";
    $serviceIdExpr = $serviceIdCol ? "b.`$serviceIdCol`" : "0";
    $hotelJoinId = $hotelIdCol ? "b.`$hotelIdCol`" : $serviceIdExpr;
    $packageJoinId = $packageIdCol ? "b.`$packageIdCol`" : $serviceIdExpr;
    $hotelJoinCondition = $hotelIdCol
        ? "h.hotelid = $hotelJoinId"
        : "(($typeExpr LIKE '%hotel%') AND h.hotelid = $hotelJoinId)";
    $packageJoinCondition = $packageIdCol
        ? "p.packageid = $packageJoinId"
        : "(($typeExpr LIKE '%package%') AND p.packageid = $packageJoinId)";
    $amountExpr = $amountCol ? "COALESCE(b.`$amountCol`, 0)" : "0";
    $statusExpr = $statusCol ? "COALESCE(b.`$statusCol`, 'PENDING')" : "'PENDING'";
    $dateExpr = $dateCol ? "COALESCE(b.`$dateCol`, '')" : "''";

    $sql = "SELECT
                $bookingId AS booking_id,
                CASE
                    WHEN $typeExpr LIKE '%hotel%' THEN 'Hotel'
                    WHEN $typeExpr LIKE '%package%' THEN 'Package'
                    ELSE 'Booking'
                END AS item_type,
                COALESCE(h.hotelname, p.packagename, CONCAT('Booking #', $bookingId)) AS item_name,
                $dateExpr AS date,
                $amountExpr AS amount,
                $statusExpr AS status
            FROM bookings b
            LEFT JOIN hotels h ON $hotelJoinCondition
            LEFT JOIN packages p ON $packageJoinCondition
            WHERE b.`$userIdCol` = ?
            ORDER BY $bookingId DESC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    while ($result && $row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();

    customer_success($rows);
} catch (Exception $e) {
    customer_error($e->getMessage(), []);
}
?>

