<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if (<?php

require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

function admin_monthly_rows($conn, $table, $dateCandidates, $valueExpression, $alias) {
    if (!admin_table_exists($conn, $table)) {
        return [];
    }

    $columns = admin_columns($conn, $table);
    $dateCol = admin_col($columns, $dateCandidates);
    if ($dateCol === null) {
        return [];
    }

    $sql = "SELECT MONTH(`$dateCol`) AS month, $valueExpression AS `$alias`
            FROM `$table`
            WHERE `$dateCol` IS NOT NULL
            GROUP BY MONTH(`$dateCol`)
            ORDER BY MONTH(`$dateCol`)";
    $result = $conn->query($sql);
    return admin_rows($result);
}

$monthlyRevenue = [];
if (admin_table_exists($conn, 'payments')) {
    $paymentColumns = admin_columns($conn, 'payments');
    $amountCol = admin_col($paymentColumns, ['amount', 'paidamount']);
    if ($amountCol !== null) {
        $monthlyRevenue = admin_monthly_rows(
            $conn,
            'payments',
            ['paiddate', 'paymentdate', 'edatetime', 'created_at'],
            "COALESCE(SUM(`$amountCol`), 0)",
            'revenue'
        );
    }
}

if (empty($monthlyRevenue) && admin_table_exists($conn, 'bookings')) {
    $bookingColumns = admin_columns($conn, 'bookings');
    $amountCol = admin_col($bookingColumns, ['totalamount', 'finalamount', 'amount']);
    if ($amountCol !== null) {
        $monthlyRevenue = admin_monthly_rows(
            $conn,
            'bookings',
            ['bookdate', 'edatetime', 'created_at'],
            "COALESCE(SUM(`$amountCol`), 0)",
            'revenue'
        );
    }
}

$bookingTrends = admin_monthly_rows(
    $conn,
    'bookings',
    ['bookdate', 'edatetime', 'created_at'],
    'COUNT(*)',
    'bookings'
);

admin_success([
    'monthly_revenue' => $monthlyRevenue,
    'booking_trends' => $bookingTrends
]);
?>
SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}


require_once __DIR__ . '/admin_helpers.php';

admin_require_method('GET');
admin_require_user($conn, $_GET);

function admin_monthly_rows($conn, $table, $dateCandidates, $valueExpression, $alias) {
    if (!admin_table_exists($conn, $table)) {
        return [];
    }

    $columns = admin_columns($conn, $table);
    $dateCol = admin_col($columns, $dateCandidates);
    if ($dateCol === null) {
        return [];
    }

    $sql = "SELECT MONTH(`$dateCol`) AS month, $valueExpression AS `$alias`
            FROM `$table`
            WHERE `$dateCol` IS NOT NULL
            GROUP BY MONTH(`$dateCol`)
            ORDER BY MONTH(`$dateCol`)";
    $result = $conn->query($sql);
    return admin_rows($result);
}

$monthlyRevenue = [];
if (admin_table_exists($conn, 'payments')) {
    $paymentColumns = admin_columns($conn, 'payments');
    $amountCol = admin_col($paymentColumns, ['amount', 'paidamount']);
    if ($amountCol !== null) {
        $monthlyRevenue = admin_monthly_rows(
            $conn,
            'payments',
            ['paiddate', 'paymentdate', 'edatetime', 'created_at'],
            "COALESCE(SUM(`$amountCol`), 0)",
            'revenue'
        );
    }
}

if (empty($monthlyRevenue) && admin_table_exists($conn, 'bookings')) {
    $bookingColumns = admin_columns($conn, 'bookings');
    $amountCol = admin_col($bookingColumns, ['totalamount', 'finalamount', 'amount']);
    if ($amountCol !== null) {
        $monthlyRevenue = admin_monthly_rows(
            $conn,
            'bookings',
            ['bookdate', 'edatetime', 'created_at'],
            "COALESCE(SUM(`$amountCol`), 0)",
            'revenue'
        );
    }
}

$bookingTrends = admin_monthly_rows(
    $conn,
    'bookings',
    ['bookdate', 'edatetime', 'created_at'],
    'COUNT(*)',
    'bookings'
);

admin_success([
    'monthly_revenue' => $monthlyRevenue,
    'booking_trends' => $bookingTrends
]);
?>

