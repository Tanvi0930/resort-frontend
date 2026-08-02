import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OwnerDashboardView extends StatelessWidget {
  final List<Map<String, dynamic>> resorts;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> activities;
  final ValueChanged<int> onNavigate;

  const OwnerDashboardView({
    super.key,
    required this.resorts,
    required this.bookings,
    required this.activities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1200;
    final isTablet = width >= 768 && width < 1200;

    final totalResorts = resorts.length;
    int totalRooms = 0;
    for (var r in resorts) {
      totalRooms += (r['rooms'] as num? ?? 0).toInt();
    }
    final totalBookingsCount = bookings.length;

    double totalEarningsVal = 0.0;
    for (var b in bookings) {
      if (b['status'] == 'Confirmed' || b['status'] == 'Completed') {
        totalEarningsVal += (b['amount'] as num? ?? 0).toDouble();
      }
    }
    final displayEarnings =
        "₹${totalEarningsVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Overview of your resort performance',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '20 May 2025 - 26 May 2025',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2D27)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsGrid(isDesktop, isTablet, totalResorts, totalRooms,
              totalBookingsCount, displayEarnings),
          const SizedBox(height: 24),
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildBookingsOverviewCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildBookingsByStatusCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildRecentBookingsCard()),
              ],
            ),
          ] else ...[
            _buildBookingsOverviewCard(),
            const SizedBox(height: 20),
            if (isTablet) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBookingsByStatusCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildRecentBookingsCard()),
                ],
              ),
            ] else ...[
              _buildBookingsByStatusCard(),
              const SizedBox(height: 20),
              _buildRecentBookingsCard(),
            ],
          ],
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildQuickActionsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildActivityLogCard()),
              ],
            )
          else ...[
            _buildQuickActionsCard(),
            const SizedBox(height: 20),
            _buildActivityLogCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDesktop, bool isTablet, int totalResorts,
      int totalRooms, int totalBookings, String totalEarnings) {
    final cards = [
      _StatCardData(
        title: 'My Resorts',
        value: '$totalResorts',
        icon: Icons.villa_outlined,
        color: const Color(0xFF0F4C43),
        bgColor: const Color(0xFFF0F4F2),
        subtitle: 'Total managed resorts',
      ),
      _StatCardData(
        title: 'Total Rooms',
        value: '$totalRooms',
        icon: Icons.bed_outlined,
        color: const Color(0xFF5A93E5),
        bgColor: const Color(0xFFEBF1FC),
        subtitle: 'Across all resorts',
      ),
      _StatCardData(
        title: 'Bookings',
        value: '$totalBookings',
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFFE5A93C),
        bgColor: const Color(0xFFFDF3E3),
        subtitle: 'Total bookings received',
      ),
      _StatCardData(
        title: 'Revenue',
        value: totalEarnings,
        icon: Icons.currency_rupee_outlined,
        color: const Color(0xFF9C6FDE),
        bgColor: const Color(0xFFF3EDFB),
        subtitle: 'From confirmed bookings',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatCard(c),
                )))
            .toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatCard(cards[0]))),
            Expanded(child: _buildStatCard(cards[1])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatCard(cards[2]))),
            Expanded(child: _buildStatCard(cards[3])),
          ]),
        ],
      );
    } else {
      return Column(
        children: cards
            .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStatCard(c)))
            .toList(),
      );
    }
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 12, color: Color(0xFF0F4C43)),
                    SizedBox(width: 3),
                    Text('+12%',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0F4C43),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 4),
          Text(data.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 2),
          Text(data.subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBookingsOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Overview',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 4),
          const Text('Monthly booking trends',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Text(months[value.toInt()],
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 12),
                      FlSpot(1, 20),
                      FlSpot(2, 15),
                      FlSpot(3, 30),
                      FlSpot(4, 25),
                      FlSpot(5, 38),
                    ],
                    isCurved: true,
                    color: const Color(0xFF0F4C43),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0F4C43).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsByStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Breakdown',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 4),
          const Text('Bookings by status',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      value: 45,
                      title: '45%',
                      color: const Color(0xFF0F4C43),
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  PieChartSectionData(
                      value: 30,
                      title: '30%',
                      color: const Color(0xFFE5A93C),
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  PieChartSectionData(
                      value: 25,
                      title: '25%',
                      color: const Color(0xFFE57373),
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend('Confirmed', const Color(0xFF0F4C43)),
          _buildLegend('Pending', const Color(0xFFE5A93C)),
          _buildLegend('Cancelled', const Color(0xFFE57373)),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E2D27))),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsCard() {
    final mockBookings = [
      {'guest': 'Aryan Mehta', 'status': 'Confirmed', 'amount': '₹15,000'},
      {'guest': 'Priya Sharma', 'status': 'Pending', 'amount': '₹12,000'},
      {'guest': 'Rohan Das', 'status': 'Confirmed', 'amount': '₹18,000'},
      {'guest': 'Sneha Patel', 'status': 'Cancelled', 'amount': '₹9,500'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Bookings',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 4),
          const Text('Latest guest reservations',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ...mockBookings.map((b) => _buildBookingRow(b)),
        ],
      ),
    );
  }

  Widget _buildBookingRow(Map<String, dynamic> b) {
    Color statusColor;
    Color statusBg;
    switch (b['status']) {
      case 'Confirmed':
        statusColor = const Color(0xFF0F4C43);
        statusBg = const Color(0xFFF0F4F2);
        break;
      case 'Pending':
        statusColor = const Color(0xFFE5A93C);
        statusBg = const Color(0xFFFDF3E3);
        break;
      default:
        statusColor = const Color(0xFFE57373);
        statusBg = const Color(0xFFFDECEA);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFF0F4F2),
            child: Icon(Icons.person_outline,
                size: 16, color: Color(0xFF0F4C43)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['guest'],
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2D27))),
                Text(b['amount'],
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(b['status'],
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 16),
          _buildQuickActionBtn(
              Icons.villa_outlined, 'Manage Resort Details', 4),
          _buildQuickActionBtn(
              Icons.calendar_today_outlined, 'View Bookings', 2),
          _buildQuickActionBtn(
              Icons.location_on_outlined, 'Manage Locations', 1),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, int navIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => onNavigate(navIndex),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0F4C43), size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E2D27))),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Log',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2D27))),
          const SizedBox(height: 4),
          const Text('Recent actions on your account',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ...activities.take(6).map((a) => _buildActivityItem(a)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (a['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(a['icon'] as IconData,
                size: 16, color: a['color'] as Color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] as String,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2D27))),
                const SizedBox(height: 2),
                Text(a['time'] as String,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String subtitle;

  _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.subtitle,
  });
}
