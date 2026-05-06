<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

function admin_count_table($conn, $table) {
    if (!admin_table_exists($conn, $table)) {
        return 0;
    }
    $result = $conn->query("SELECT COUNT(*) AS total FROM `$table`");
    $row = $result ? $result->fetch_assoc() : null;
    return intval($row['total'] ?? 0);
}

function admin_total_revenue($conn) {
    if (admin_table_exists($conn, 'payments')) {
        $columns = admin_columns($conn, 'payments');
        $amountCol = admin_col($columns, ['amount', 'paidamount']);
        $statusCol = admin_col($columns, ['paymentstatus', 'status']);
        if ($amountCol !== null) {
            $where = $statusCol !== null ? "WHERE UPPER(COALESCE(`$statusCol`, '')) IN ('SUCCESS', 'COMPLETED', 'PAID')" : '';
            $result = $conn->query("SELECT COALESCE(SUM(`$amountCol`), 0) AS total FROM payments $where");
            $row = $result ? $result->fetch_assoc() : null;
            return floatval($row['total'] ?? 0);
        }
    }

    if (admin_table_exists($conn, 'bookings')) {
        $columns = admin_columns($conn, 'bookings');
        $amountCol = admin_col($columns, ['totalamount', 'finalamount', 'amount']);
        if ($amountCol !== null) {
            $result = $conn->query("SELECT COALESCE(SUM(`$amountCol`), 0) AS total FROM bookings");
            $row = $result ? $result->fetch_assoc() : null;
            return floatval($row['total'] ?? 0);
        }
    }
    return 0;
}

admin_success([
    'total_users' => admin_count_table($conn, 'users'),
    'total_partners' => admin_count_table($conn, 'partners'),
    'total_bookings' => admin_count_table($conn, 'bookings'),
    'total_revenue' => admin_total_revenue($conn)
]);
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

function admin_count_table($conn, $table) {
    if (!admin_table_exists($conn, $table)) {
        return 0;
    }
    $result = $conn->query("SELECT COUNT(*) AS total FROM `$table`");
    $row = $result ? $result->fetch_assoc() : null;
    return intval($row['total'] ?? 0);
}

function admin_total_revenue($conn) {
    if (admin_table_exists($conn, 'payments')) {
        $columns = admin_columns($conn, 'payments');
        $amountCol = admin_col($columns, ['amount', 'paidamount']);
        $statusCol = admin_col($columns, ['paymentstatus', 'status']);
        if ($amountCol !== null) {
            $where = $statusCol !== null ? "WHERE UPPER(COALESCE(`$statusCol`, '')) IN ('SUCCESS', 'COMPLETED', 'PAID')" : '';
            $result = $conn->query("SELECT COALESCE(SUM(`$amountCol`), 0) AS total FROM payments $where");
            $row = $result ? $result->fetch_assoc() : null;
            return floatval($row['total'] ?? 0);
        }
    }

    if (admin_table_exists($conn, 'bookings')) {
        $columns = admin_columns($conn, 'bookings');
        $amountCol = admin_col($columns, ['totalamount', 'finalamount', 'amount']);
        if ($amountCol !== null) {
            $result = $conn->query("SELECT COALESCE(SUM(`$amountCol`), 0) AS total FROM bookings");
            $row = $result ? $result->fetch_assoc() : null;
            return floatval($row['total'] ?? 0);
        }
    }
    return 0;
}

admin_success([
    'total_users' => admin_count_table($conn, 'users'),
    'total_partners' => admin_count_table($conn, 'partners'),
    'total_bookings' => admin_count_table($conn, 'bookings'),
    'total_revenue' => admin_total_revenue($conn)
]);
?>

