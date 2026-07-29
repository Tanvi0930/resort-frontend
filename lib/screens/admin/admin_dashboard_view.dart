import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardView extends StatelessWidget {
  final List<Map<String, dynamic>> resorts;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> activities;
  final ValueChanged<int> onNavigate;

  const AdminDashboardView({
    super.key,
    required this.resorts,
    required this.users,
    required this.bookings,
    required this.activities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1200;
    final isTablet = width >= 768 && width < 1200;

    // Calculate Dynamic Stats
    final totalResorts = resorts.length;
    int totalRooms = 0;
    for (var r in resorts) {
      totalRooms += (r['rooms'] as num).toInt();
    }
    final totalBookingsCount = bookings.length;
    
    // Earnings calculation
    double totalEarningsVal = 0.0;
    for (var b in bookings) {
      if (b['status'] == 'Confirmed' || b['status'] == 'Completed') {
        totalEarningsVal += (b['amount'] as num).toDouble();
      }
    }
    final displayEarnings = "₹${totalEarningsVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle / Date Range
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview of your resort management system',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '20 May 2025 - 26 May 2025',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // --- 1. Stat Cards Row/Grid ---
          _buildStatsGrid(isDesktop, isTablet, totalResorts, totalRooms, totalBookingsCount, displayEarnings),

          const SizedBox(height: 24),

          // --- 2. Charts & Tables Section ---
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
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildTopPerformingResortsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildEarningsOverviewCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildRecentActivitiesCard()),
              ],
            ),
          ] else if (isTablet) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildBookingsOverviewCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildBookingsByStatusCard()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildRecentBookingsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildTopPerformingResortsCard()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildEarningsOverviewCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildRecentActivitiesCard()),
              ],
            ),
          ] else ...[
            // Mobile (vertical stack)
            _buildBookingsOverviewCard(),
            const SizedBox(height: 20),
            _buildBookingsByStatusCard(),
            const SizedBox(height: 20),
            _buildRecentBookingsCard(),
            const SizedBox(height: 20),
            _buildTopPerformingResortsCard(),
            const SizedBox(height: 20),
            _buildEarningsOverviewCard(),
            const SizedBox(height: 20),
            _buildRecentActivitiesCard(),
          ],

          const SizedBox(height: 24),

          // --- 3. Quick Actions Panel ---
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  // --- STATS GRID BUILDER ---
  Widget _buildStatsGrid(bool isDesktop, bool isTablet, int totalResorts, int totalRooms, int totalBookingsCount, String displayEarnings) {
    final cards = [
      _buildStatCard(
        title: 'Total Resorts',
        value: totalResorts.toString(),
        change: '+ 12% from last week',
        icon: Icons.business,
        iconColor: const Color(0xFF3E7C59),
        bgColor: const Color(0xFFE8F3EB),
      ),
      _buildStatCard(
        title: 'Total Rooms',
        value: totalRooms.toString(),
        change: '+ 8% from last week',
        icon: Icons.hotel_outlined,
        iconColor: const Color(0xFFE5A93C),
        bgColor: const Color(0xFFFDF5E6),
      ),
      _buildStatCard(
        title: 'Total Bookings',
        value: totalBookingsCount.toString(),
        change: '+ 15% from last week',
        icon: Icons.check_box_outlined,
        iconColor: const Color(0xFF5A93E5),
        bgColor: const Color(0xFFEEF4FC),
      ),
      _buildStatCard(
        title: 'Total Earnings',
        value: displayEarnings,
        change: '+ 18% from last week',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFFE57373),
        bgColor: const Color(0xFFFDECEA),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
      );
    } else if (isTablet) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: cards,
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => cards[index],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 10, color: Colors.green),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CHART 1: BOOKINGS OVERVIEW (LINE CHART) ---
  Widget _buildBookingsOverviewCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bookings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              Row(
                children: [
                  _buildLegendIndicator(const Color(0xFF3E7C59), 'This Week'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(const Color(0xFFE5A93C), 'Last Week'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 30 || value == 60 || value == 90 || value == 120) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['20 May', '21 May', '22 May', '23 May', '24 May', '25 May', '26 May'];
                        if (value >= 0 && value < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 120,
                lineBarsData: [
                  // This Week (Green)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 50),
                      FlSpot(1, 85),
                      FlSpot(2, 75),
                      FlSpot(3, 65),
                      FlSpot(4, 85),
                      FlSpot(5, 78),
                      FlSpot(6, 85),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3E7C59),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3E7C59).withValues(alpha: 0.08),
                    ),
                  ),
                  // Last Week (Orange)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 30),
                      FlSpot(1, 50),
                      FlSpot(2, 45),
                      FlSpot(3, 35),
                      FlSpot(4, 48),
                      FlSpot(5, 38),
                      FlSpot(6, 40),
                    ],
                    isCurved: true,
                    color: const Color(0xFFE5A93C),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.08),
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

  // --- CHART 2: BOOKINGS BY STATUS (DONUT CHART) ---
  Widget _buildBookingsByStatusCard() {
    final confirmed = bookings.where((b) => b['status'] == 'Confirmed').length;
    final pending = bookings.where((b) => b['status'] == 'Pending').length;
    final cancelled = bookings.where((b) => b['status'] == 'Cancelled').length;
    final completed = bookings.where((b) => b['status'] == 'Completed').length;
    final total = bookings.length;

    final pctConfirmed = total > 0 ? (confirmed / total) * 100 : 0.0;
    final pctPending = total > 0 ? (pending / total) * 100 : 0.0;
    final pctCancelled = total > 0 ? (cancelled / total) * 100 : 0.0;
    final pctCompleted = total > 0 ? (completed / total) * 100 : 0.0;

    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bookings by Status',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              value: pctConfirmed > 0 ? pctConfirmed : 1,
                              color: const Color(0xFF3E7C59),
                              radius: 18,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: pctPending > 0 ? pctPending : 1,
                              color: const Color(0xFFE5A93C),
                              radius: 18,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: pctCancelled > 0 ? pctCancelled : 1,
                              color: Colors.grey.shade400,
                              radius: 18,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: pctCompleted > 0 ? pctCompleted : 1,
                              color: const Color(0xFF5A93E5),
                              radius: 18,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            total.toString(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusLegend(const Color(0xFF3E7C59), 'Confirmed', '$confirmed (${pctConfirmed.toStringAsFixed(1)}%)'),
                      const SizedBox(height: 8),
                      _buildStatusLegend(const Color(0xFFE5A93C), 'Pending', '$pending (${pctPending.toStringAsFixed(1)}%)'),
                      const SizedBox(height: 8),
                      _buildStatusLegend(Colors.grey.shade400, 'Cancelled', '$cancelled (${pctCancelled.toStringAsFixed(1)}%)'),
                      const SizedBox(height: 8),
                      _buildStatusLegend(const Color(0xFF5A93E5), 'Completed', '$completed (${pctCompleted.toStringAsFixed(1)}%)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LIST 1: RECENT BOOKINGS LIST ---
  Widget _buildRecentBookingsCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              TextButton(
                onPressed: () => onNavigate(2), // Navigate to Bookings view
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3E7C59), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: bookings.length > 4 ? 4 : bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final b = bookings[bookings.length - 1 - index]; // Show newest first
                final status = b['status'];
                Color badgeColor = Colors.grey;
                Color textColor = Colors.white;

                if (status == 'Confirmed') {
                  badgeColor = const Color(0xFFE8F3EB);
                  textColor = const Color(0xFF3E7C59);
                } else if (status == 'Pending') {
                  badgeColor = const Color(0xFFFDF5E6);
                  textColor = const Color(0xFFE5A93C);
                } else if (status == 'Cancelled') {
                  badgeColor = const Color(0xFFFDECEA);
                  textColor = const Color(0xFFE57373);
                } else if (status == 'Completed') {
                  badgeColor = const Color(0xFFEEF4FC);
                  textColor = const Color(0xFF5A93E5);
                }

                return Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=150&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['resortName'] ?? 'Resort',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b['guestName']} • ${b['date']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- LIST 2: TOP PERFORMING RESORTS ---
  Widget _buildTopPerformingResortsCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performing Resorts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              TextButton(
                onPressed: () => onNavigate(1), // Navigate to Resorts view
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3E7C59), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: resorts.length > 4 ? 4 : resorts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = resorts[index];
                final priceString = "₹${(r['price'] as num).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

                return Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(r['imageUrl'] ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r['location'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      priceString,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF3E7C59);
      case 1:
        return const Color(0xFF5A93E5);
      case 2:
        return const Color(0xFFE5A93C);
      default:
        return Colors.grey.shade400;
    }
  }

  // --- CHART 3: EARNINGS OVERVIEW (BAR CHART) ---
  Widget _buildEarningsOverviewCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                  SizedBox(width: 2),
                  Text('18% vs last week', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100 || value == 150 || value == 200) {
                          return Text(
                            '${value.toInt()}K',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['20 May', '21 May', '22 May', '23 May', '24 May', '25 May', '26 May'];
                        if (value >= 0 && value < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, 70),
                  _makeBarGroup(1, 100),
                  _makeBarGroup(2, 90),
                  _makeBarGroup(3, 170),
                  _makeBarGroup(4, 105),
                  _makeBarGroup(5, 100),
                  _makeBarGroup(6, 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF3E7C59),
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  // --- LIST 3: RECENT ACTIVITIES LOG ---
  Widget _buildRecentActivitiesCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final act = activities[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (act['color'] as Color).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(act['icon'] as IconData, size: 14, color: act['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A2B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            act['time'] ?? '',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTIONS ---
  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 5 * 12) / 6;
              final isNarrow = constraints.maxWidth < 600;

              if (isNarrow) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickActionButton(Icons.add_business_outlined, 'Add Resort', () => onNavigate(1)),
                    _buildQuickActionButton(Icons.bed_outlined, 'Add Room', () => onNavigate(4)),
                    _buildQuickActionButton(Icons.add_box_outlined, 'New Booking', () => onNavigate(2)),
                    _buildQuickActionButton(Icons.calendar_month_outlined, 'View Bookings', () => onNavigate(2)),
                    _buildQuickActionButton(Icons.local_offer_outlined, 'Add Offer', () => {}),
                    _buildQuickActionButton(Icons.assessment_outlined, 'Report', () => onNavigate(10)),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.add_business_outlined, 'Add Resort', () => onNavigate(1))),
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.bed_outlined, 'Add Room', () => onNavigate(4))),
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.add_box_outlined, 'New Booking', () => onNavigate(2))),
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.calendar_month_outlined, 'View Bookings', () => onNavigate(2))),
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.local_offer_outlined, 'Add Offer', () => {})),
                  SizedBox(width: buttonWidth, child: _buildQuickActionButton(Icons.assessment_outlined, 'Report', () => onNavigate(10))),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF7F9F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF3E7C59), size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legend helpers
  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
