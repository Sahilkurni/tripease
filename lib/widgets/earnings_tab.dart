import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsTab extends StatefulWidget {
  final Map<String, dynamic> earningsData;
  final bool isLoading;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const EarningsTab({
    super.key,
    required this.earningsData,
    required this.isLoading,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get ink => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B);
  Color get muted => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B);
  Color get surface => Theme.of(context).cardColor;

  String _formatAmount(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0.0;
    if (d >= 100000) return '${(d / 100000).toStringAsFixed(1)}L';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}k';
    return d.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.earningsData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: muted),
            const SizedBox(height: 16),
            Text('No earnings data available.', style: GoogleFonts.poppins(color: ink, fontSize: 18)),
          ],
        ),
      );
    }

    final grossRevenue = widget.earningsData['gross_revenue'] ?? 0.0;
    final commissionPct = widget.earningsData['commission_pct'] ?? 0.0;
    final commissionAmt = widget.earningsData['commission_amt'] ?? 0.0;
    final gstOnCommission = widget.earningsData['gst_on_commission'] ?? 0.0;
    final netEarnings = widget.earningsData['net_earnings'] ?? 0.0;
    final List<dynamic> monthly = widget.earningsData['monthly_breakdown'] ?? [];
    final List<dynamic> transactions = widget.earningsData['recent_transactions'] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(w > 800 ? 40 : 24).copyWith(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings & Taxes',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'week', child: Text('This Week')),
                      DropdownMenuItem(value: 'month', child: Text('This Month')),
                      DropdownMenuItem(value: 'year', child: Text('This Year')),
                      DropdownMenuItem(value: 'all', child: Text('All Time')),
                    ],
                    onChanged: (val) {
                      if (val != null) widget.onPeriodChanged(val);
                    },
                    style: GoogleFonts.poppins(color: ink, fontSize: 14, fontWeight: FontWeight.w500),
                    icon: Icon(Icons.arrow_drop_down, color: ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSummaryCards(grossRevenue, commissionAmt, gstOnCommission, netEarnings, w),
          const SizedBox(height: 40),
          if (monthly.isNotEmpty) ...[
            Text(
              widget.selectedPeriod == 'week' || widget.selectedPeriod == 'month'
                  ? 'Daily Breakdown'
                  : 'Monthly Breakdown',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: ink),
            ),
            const SizedBox(height: 16),
            _buildChart(monthly, w),
            const SizedBox(height: 40),
          ],
          if (transactions.isNotEmpty) ...[
            Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 16),
            _buildTransactionsTable(transactions, w),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double gross, double comm, double gst, double net, double w) {
    int crossAxisCount = w > 1200 ? 4 : (w > 600 ? 2 : 1);
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: [
        _EarningStatCard(
          title: 'Gross Revenue',
          amount: gross,
          icon: Icons.account_balance_rounded,
          colors: const [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
        ),
        _EarningStatCard(
          title: 'Platform Commission',
          amount: comm,
          icon: Icons.pie_chart_rounded,
          colors: const [Color(0xFFF43F5E), Color(0xFFE11D48)], // Red
          subtitle: '-${widget.earningsData['commission_pct']}%',
        ),
        _EarningStatCard(
          title: 'GST (18% on Comm.)',
          amount: gst,
          icon: Icons.receipt_long_rounded,
          colors: const [Color(0xFFF59E0B), Color(0xFFD97706)], // Orange
          subtitle: 'Deducted',
        ),
        _EarningStatCard(
          title: 'Net Earnings',
          amount: net,
          icon: Icons.monetization_on_rounded,
          colors: const [Color(0xFF10B981), Color(0xFF059669)], // Green
        ),
      ],
    );
  }

  Widget _buildChart(List<dynamic> monthly, double w) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(monthly) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthly.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(monthly[value.toInt()]['month_label'] ?? '', style: TextStyle(color: muted, fontSize: 12)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(_formatAmount(value), style: TextStyle(color: muted, fontSize: 12));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (_getMaxY(monthly) / 4) > 0 ? (_getMaxY(monthly) / 4) : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [5, 5]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: monthly.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            double gross = double.tryParse(item['gross'].toString()) ?? 0;
            double net = double.tryParse(item['net'].toString()) ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: gross,
                  color: Colors.blue[300],
                  width: w > 600 ? 16 : 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: net,
                  color: Colors.green[400],
                  width: w > 600 ? 16 : 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxY(List<dynamic> monthly) {
    double max = 0;
    for (var item in monthly) {
      double gross = double.tryParse(item['gross'].toString()) ?? 0;
      if (gross > max) max = gross;
    }
    return max == 0 ? 100 : max;
  }

  Widget _buildTransactionsTable(List<dynamic> transactions, double w) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: ink),
            dataTextStyle: GoogleFonts.poppins(color: ink),
            columns: const [
              DataColumn(label: Text('Booking ID')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Service')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
            ],
            rows: transactions.map((t) {
              return DataRow(
                cells: [
                  DataCell(Text(t['bookingno']?.toString() ?? '-')),
                  DataCell(Text(t['bookingdate']?.toString().split(' ')[0] ?? '-')),
                  DataCell(Text(t['service_name']?.toString() ?? '-')),
                  DataCell(
                    Text(
                      '₹${_formatAmount(t['finalamount'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t['bookingstatus']?.toString() ?? 'PAID',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _EarningStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final List<Color> colors;
  final String? subtitle;

  const _EarningStatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.colors,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              Text(
                '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (subtitle != null)
                Text(subtitle!, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
