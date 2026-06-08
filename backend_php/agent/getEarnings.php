<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    exit(0);
}

require_once __DIR__ . '/../db.php';

$partnerid = intval($_GET['partnerid'] ?? 0);
$period = $_GET['period'] ?? 'month'; // 'month', 'year', 'all'

if ($partnerid <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'partnerid is required']);
    exit;
}

// 1. Get partner info (for commission_pct)
$p_stmt = $conn->prepare("SELECT commission FROM partners WHERE partnerid = ?");
$p_stmt->bind_param("i", $partnerid);
$p_stmt->execute();
$p_res = $p_stmt->get_result();
$commission_pct = 0.0;
if ($p_row = $p_res->fetch_assoc()) {
    $commission_pct = floatval($p_row['commission']);
}

// 2. Compute earnings
$b_stmt = $conn->prepare("
    SELECT b.bookingid, b.amount, b.commission_amt, b.booking_date, b.status 
    FROM bookings b
    JOIN buses bus ON b.serviceid = bus.busid
    WHERE bus.partnerid = ? AND b.bookingtype = 'bus' AND b.status = 'confirmed'
    ORDER BY b.bookingid DESC
");
$b_stmt->bind_param("i", $partnerid);
$b_stmt->execute();
$b_res = $b_stmt->get_result();

$gross_revenue = 0.0;
$commission_amt = 0.0;
$recent_transactions = [];
$monthly = [];

while ($row = $b_res->fetch_assoc()) {
    $amt = floatval($row['amount']);
    $comm = floatval($row['commission_amt']);
    $gross_revenue += $amt;
    $commission_amt += $comm;

    // Monthly breakdown logic
    $month = date('M', strtotime($row['booking_date']));
    if (!isset($monthly[$month])) {
        $monthly[$month] = 0;
    }
    $monthly[$month] += $amt;

    // Just keep last 10
    if (count($recent_transactions) < 10) {
        $recent_transactions[] = [
            'transaction_id' => 'TXN' . str_pad($row['bookingid'], 6, '0', STR_PAD_LEFT),
            'amount' => $amt,
            'date' => $row['booking_date'],
            'status' => 'Completed'
        ];
    }
}

$gst_on_commission = $commission_amt * 0.18;
$net_earnings = $gross_revenue - $commission_amt - $gst_on_commission;

$monthly_breakdown = [];
foreach ($monthly as $m => $r) {
    $monthly_breakdown[] = ['month' => $m, 'revenue' => $r];
}

echo json_encode([
    'status' => 'success',
    'data' => [
        'gross_revenue' => $gross_revenue,
        'commission_pct' => $commission_pct,
        'commission_amt' => $commission_amt,
        'gst_on_commission' => $gst_on_commission,
        'net_earnings' => $net_earnings,
        'monthly_breakdown' => $monthly_breakdown,
        'recent_transactions' => $recent_transactions
    ]
]);
?>
