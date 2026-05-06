<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/customer_helpers.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        customer_error('Invalid request method');
    }

    customer_ensure_wishlist($conn);
    $userid = customer_require_userid($_POST);
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if (!in_array($itemType, ['hotel', 'package']) || $itemId <= 0) {
        customer_error('item_type and item_id are required');
    }

    $stmt = $conn->prepare("INSERT IGNORE INTO wishlist (userid, item_type, item_id) VALUES (?, ?, ?)");
    $stmt->bind_param('isi', $userid, $itemType, $itemId);
    $ok = $stmt->execute();
    $id = $stmt->insert_id;
    $stmt->close();

    if (!$ok) {
        customer_error('Failed to add wishlist item');
    }

    customer_success([
        'id' => $id,
        'userid' => $userid,
        'item_type' => $itemType,
        'item_id' => $itemId
    ], 'Wishlist item saved');
} catch (Exception $e) {
    customer_error($e->getMessage());
}
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/customer_helpers.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        customer_error('Invalid request method');
    }

    customer_ensure_wishlist($conn);
    $userid = customer_require_userid($_POST);
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if (!in_array($itemType, ['hotel', 'package']) || $itemId <= 0) {
        customer_error('item_type and item_id are required');
    }

    $stmt = $conn->prepare("INSERT IGNORE INTO wishlist (userid, item_type, item_id) VALUES (?, ?, ?)");
    $stmt->bind_param('isi', $userid, $itemType, $itemId);
    $ok = $stmt->execute();
    $id = $stmt->insert_id;
    $stmt->close();

    if (!$ok) {
        customer_error('Failed to add wishlist item');
    }

    customer_success([
        'id' => $id,
        'userid' => $userid,
        'item_type' => $itemType,
        'item_id' => $itemId
    ], 'Wishlist item saved');
} catch (Exception $e) {
    customer_error($e->getMessage());
}
?>

