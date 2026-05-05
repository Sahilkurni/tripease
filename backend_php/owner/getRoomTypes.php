<?php
include '../db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$defaultTypes = ['Standard', 'Deluxe', 'Suite', 'Family Room'];

try {
    $conn->query(
        "CREATE TABLE IF NOT EXISTS roomtypes (
            roomtypeid INT AUTO_INCREMENT PRIMARY KEY,
            typename VARCHAR(80) NOT NULL UNIQUE,
            isactive TINYINT DEFAULT 1,
            edatetime DATETIME DEFAULT CURRENT_TIMESTAMP
        )"
    );

    $countResult = $conn->query("SELECT COUNT(*) AS total FROM roomtypes");
    $countRow = $countResult ? $countResult->fetch_assoc() : ['total' => 0];

    if (intval($countRow['total']) === 0) {
        $stmt = $conn->prepare("INSERT INTO roomtypes (typename) VALUES (?)");
        foreach ($defaultTypes as $typeName) {
            $stmt->bind_param('s', $typeName);
            $stmt->execute();
        }
    }

    $result = $conn->query(
        "SELECT roomtypeid, typename
         FROM roomtypes
         WHERE isactive = 1
         ORDER BY roomtypeid"
    );

    $types = [];
    while ($row = $result->fetch_assoc()) {
        $types[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'Room types fetched',
        'data' => $types
    ]);
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'getRoomTypes failed: ' . $e->getMessage(),
        'data' => []
    ]);
}
?>
