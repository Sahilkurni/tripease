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
    $id = intval($_POST['id'] ?? 0);
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if ($id > 0) {
        $stmt = $conn->prepare("DELETE FROM wishlist WHERE id = ? AND userid = ?");
        $stmt->bind_param('ii', $id, $userid);
    } elseif (in_array($itemType, ['hotel', 'package']) && $itemId > 0) {
        $stmt = $conn->prepare("DELETE FROM wishlist WHERE userid = ? AND item_type = ? AND item_id = ?");
        $stmt->bind_param('isi', $userid, $itemType, $itemId);
    } else {
        customer_error('Wishlist id or item reference is required');
    }

    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        customer_error('Failed to remove wishlist item');
    }

    customer_success([], 'Wishlist item removed');
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
    $id = intval($_POST['id'] ?? 0);
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if ($id > 0) {
        $stmt = $conn->prepare("DELETE FROM wishlist WHERE id = ? AND userid = ?");
        $stmt->bind_param('ii', $id, $userid);
    } elseif (in_array($itemType, ['hotel', 'package']) && $itemId > 0) {
        $stmt = $conn->prepare("DELETE FROM wishlist WHERE userid = ? AND item_type = ? AND item_id = ?");
        $stmt->bind_param('isi', $userid, $itemType, $itemId);
    } else {
        customer_error('Wishlist id or item reference is required');
    }

    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        customer_error('Failed to remove wishlist item');
    }

    customer_success([], 'Wishlist item removed');
} catch (Exception $e) {
    customer_error($e->getMessage());
}
?>

