<?php
// backend_php/remove_from_wishlist.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config/db.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendResponse("error", null, "Invalid request method");
    }

    $userid = isset($_POST['userid']) ? intval($_POST['userid']) : 0;
    $id = intval($_POST['id'] ?? 0);
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if ($userid <= 0) {
        sendResponse("error", null, "userid is required");
    }

    if ($id > 0) {
        // Soft delete by id
        $stmt = $conn->prepare("UPDATE wishlist SET isactive = 0 WHERE id = ? AND userid = ?");
        $stmt->bind_param('ii', $id, $userid);
    } elseif (in_array($itemType, ['hotel', 'package', 'bus']) && $itemId > 0) {
        // Soft delete by item reference
        $stmt = $conn->prepare("UPDATE wishlist SET isactive = 0 WHERE userid = ? AND item_type = ? AND item_id = ?");
        $stmt->bind_param('isi', $userid, $itemType, $itemId);
    } else {
        sendResponse("error", null, "Wishlist id or item reference (item_type & item_id) is required.");
    }

    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        sendResponse("error", null, "Failed to remove wishlist item");
    }

    sendResponse("success", null, "Wishlist item removed");
} catch (Exception $e) {
    sendResponse("error", null, $e->getMessage());
}
?>
