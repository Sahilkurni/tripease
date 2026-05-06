<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/customer_helpers.php';

try {
    $userid = customer_require_userid($_GET);
    customer_ensure_wishlist($conn);

    $hotelColumns = customer_table_exists($conn, 'hotels') ? customer_columns($conn, 'hotels') : [];
    $packageColumns = customer_table_exists($conn, 'packages') ? customer_columns($conn, 'packages') : [];
    $hotelNameCol = customer_col($hotelColumns, ['hotelname', 'name']);
    $hotelPriceCol = customer_col($hotelColumns, ['price', 'baseprice']);
    $hotelRatingCol = customer_col($hotelColumns, ['star_rating', 'rating']);
    $hotelImageCol = customer_col($hotelColumns, ['image', 'thumbnail', 'photo']);
    $packageNameCol = customer_col($packageColumns, ['packagename', 'name']);
    $packagePriceCol = customer_col($packageColumns, ['price']);
    $packageImageCol = customer_col($packageColumns, ['thumbnail', 'image']);

    $hotelName = $hotelNameCol ? "h.`$hotelNameCol`" : "NULL";
    $hotelPrice = $hotelPriceCol ? "h.`$hotelPriceCol`" : "NULL";
    $hotelRating = $hotelRatingCol ? "h.`$hotelRatingCol`" : "NULL";
    $hotelImage = $hotelImageCol ? "h.`$hotelImageCol`" : "NULL";
    $packageName = $packageNameCol ? "p.`$packageNameCol`" : "NULL";
    $packagePrice = $packagePriceCol ? "p.`$packagePriceCol`" : "NULL";
    $packageImage = $packageImageCol ? "p.`$packageImageCol`" : "NULL";

    $sql = "SELECT
                w.id,
                w.item_type,
                w.item_id,
                COALESCE($hotelName, $packageName, 'Saved item') AS name,
                COALESCE($hotelPrice, $packagePrice, 0) AS price,
                COALESCE($hotelRating, 0) AS rating,
                COALESCE($hotelImage, $packageImage, '') AS image
            FROM wishlist w
            LEFT JOIN hotels h ON w.item_type = 'hotel' AND h.hotelid = w.item_id
            LEFT JOIN packages p ON w.item_type = 'package' AND p.packageid = w.item_id
            WHERE w.userid = ?
            ORDER BY w.id DESC";
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
    customer_ensure_wishlist($conn);

    $hotelColumns = customer_table_exists($conn, 'hotels') ? customer_columns($conn, 'hotels') : [];
    $packageColumns = customer_table_exists($conn, 'packages') ? customer_columns($conn, 'packages') : [];
    $hotelNameCol = customer_col($hotelColumns, ['hotelname', 'name']);
    $hotelPriceCol = customer_col($hotelColumns, ['price', 'baseprice']);
    $hotelRatingCol = customer_col($hotelColumns, ['star_rating', 'rating']);
    $hotelImageCol = customer_col($hotelColumns, ['image', 'thumbnail', 'photo']);
    $packageNameCol = customer_col($packageColumns, ['packagename', 'name']);
    $packagePriceCol = customer_col($packageColumns, ['price']);
    $packageImageCol = customer_col($packageColumns, ['thumbnail', 'image']);

    $hotelName = $hotelNameCol ? "h.`$hotelNameCol`" : "NULL";
    $hotelPrice = $hotelPriceCol ? "h.`$hotelPriceCol`" : "NULL";
    $hotelRating = $hotelRatingCol ? "h.`$hotelRatingCol`" : "NULL";
    $hotelImage = $hotelImageCol ? "h.`$hotelImageCol`" : "NULL";
    $packageName = $packageNameCol ? "p.`$packageNameCol`" : "NULL";
    $packagePrice = $packagePriceCol ? "p.`$packagePriceCol`" : "NULL";
    $packageImage = $packageImageCol ? "p.`$packageImageCol`" : "NULL";

    $sql = "SELECT
                w.id,
                w.item_type,
                w.item_id,
                COALESCE($hotelName, $packageName, 'Saved item') AS name,
                COALESCE($hotelPrice, $packagePrice, 0) AS price,
                COALESCE($hotelRating, 0) AS rating,
                COALESCE($hotelImage, $packageImage, '') AS image
            FROM wishlist w
            LEFT JOIN hotels h ON w.item_type = 'hotel' AND h.hotelid = w.item_id
            LEFT JOIN packages p ON w.item_type = 'package' AND p.packageid = w.item_id
            WHERE w.userid = ?
            ORDER BY w.id DESC";
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

