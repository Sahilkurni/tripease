<?php
// backend_php/add_to_wishlist.php
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
    $itemType = strtolower(trim($_POST['item_type'] ?? ''));
    $itemId = intval($_POST['item_id'] ?? 0);

    if ($userid <= 0 || !in_array($itemType, ['hotel', 'package', 'bus']) || $itemId <= 0) {
        sendResponse("error", null, "userid, item_type (hotel, package, bus), and item_id are required.");
    }

    // Check if item exists in wishlist
    $checkStmt = $conn->prepare("SELECT id, isactive FROM wishlist WHERE userid = ? AND item_type = ? AND item_id = ?");
    $checkStmt->bind_param('isi', $userid, $itemType, $itemId);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();

    if ($checkResult && $row = $checkResult->fetch_assoc()) {
        $wishlistId = intval($row['id']);
        $isactive = intval($row['isactive']);

        if ($isactive !== 1) {
            $updateStmt = $conn->prepare("UPDATE wishlist SET isactive = 1 WHERE id = ?");
            $updateStmt->bind_param('i', $wishlistId);
            $updateStmt->execute();
            $updateStmt->close();
        }
        $checkStmt->close();
        sendResponse("success", [
            'id' => $wishlistId,
            'userid' => $userid,
            'item_type' => $itemType,
            'item_id' => $itemId
        ], "Wishlist item saved");
    }
    $checkStmt->close();

    // Insert new record
    $stmt = $conn->prepare("INSERT INTO wishlist (userid, item_type, item_id, isactive) VALUES (?, ?, ?, 1)");
    $stmt->bind_param('isi', $userid, $itemType, $itemId);
    $ok = $stmt->execute();
    $id = $stmt->insert_id;
    $stmt->close();

    if (!$ok) {
        sendResponse("error", null, "Failed to add wishlist item");
    }

    sendResponse("success", [
        'id' => $id,
        'userid' => $userid,
        'item_type' => $itemType,
        'item_id' => $itemId
    ], "Wishlist item saved");
} catch (Exception $e) {
    sendResponse("error", null, $e->getMessage());
}
?>
