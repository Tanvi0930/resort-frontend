import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_components.dart';

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

    // --- Parse Date Helper ---
    DateTime? parseDate(String dateStr) {
      try {
        if (dateStr.contains('-')) {
          return DateTime.parse(dateStr);
        }
        final parts = dateStr.split(' ');
        if (parts.length >= 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final monthStr = parts[1];
          final year = int.tryParse(parts[2]) ?? 2026;
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final monthIdx = months.indexOf(monthStr);
          if (monthIdx != -1) {
            return DateTime(year, monthIdx + 1, day);
          }
        }
      } catch (_) {}
      return null;
    }

    // --- Generate Last 7 Days Label lists & calculations ---
    final days = <String>[];
    final bookingCountsThisWeek = List.filled(7, 0.0);
    final bookingCountsLastWeek = List.filled(7, 0.0);
    final earningsValues = List.filled(7, 0.0);

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dates = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final lastWeekDates = List.generate(7, (i) => today.subtract(Duration(days: 13 - i)));

    for (int i = 0; i < 7; i++) {
      days.add('${dates[i].day} ${months[dates[i].month - 1]}');

      final matchingThisWeek = bookings.where((b) {
        final bDate = parseDate(b['date'] ?? '');
        return bDate != null &&
            bDate.year == dates[i].year &&
            bDate.month == dates[i].month &&
            bDate.day == dates[i].day;
      }).toList();

      final matchingLastWeek = bookings.where((b) {
        final bDate = parseDate(b['date'] ?? '');
        return bDate != null &&
            bDate.year == lastWeekDates[i].year &&
            bDate.month == lastWeekDates[i].month &&
            bDate.day == lastWeekDates[i].day;
      }).toList();

      bookingCountsThisWeek[i] = matchingThisWeek.length.toDouble();
      bookingCountsLastWeek[i] = matchingLastWeek.length.toDouble();

      final sumAmount = matchingThisWeek.fold<double>(0.0, (sum, b) => sum + ((b['amount'] as num?)?.toDouble() ?? 0.0));
      earningsValues[i] = sumAmount / 1000.0; // In Thousands 'K'
    }

    double maxBookingsCount = 10.0;
    for (final val in [...bookingCountsThisWeek, ...bookingCountsLastWeek]) {
      if (val > maxBookingsCount) maxBookingsCount = val;
    }
    maxBookingsCount = (maxBookingsCount / 5).ceil() * 5.0;
    if (maxBookingsCount == 0) maxBookingsCount = 5.0;

    double maxEarnings = 10.0;
    for (final val in earningsValues) {
      if (val > maxEarnings) maxEarnings = val;
    }
    maxEarnings = (maxEarnings / 10).ceil() * 10.0;
    if (maxEarnings == 0) maxEarnings = 10.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Overview Banner Card
          _buildLiveOverviewBanner(),
          const SizedBox(height: 20),

          // Quick Actions Grid
          _buildQuickActionsCard(),
          const SizedBox(height: 24),

          // Recent Bookings List
          if (!isDesktop && !isTablet) ...[
            _buildRecentBookingsCard(),
            const SizedBox(height: 24),
          ],

          // Bottom Mini Metrics Row
          _buildBottomMetricsRow(),
          const SizedBox(height: 28),

          // Charts & Tables Section
          Text(
            'System Charts & Reports',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E2D27),
            ),
          ),
          const SizedBox(height: 16),

          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildBookingsOverviewCard(days, bookingCountsThisWeek, bookingCountsLastWeek, maxBookingsCount)),
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
                Expanded(flex: 3, child: _buildEarningsOverviewCard(days, earningsValues, maxEarnings)),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildRecentActivitiesCard()),
              ],
            ),
          ] else if (isTablet) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildBookingsOverviewCard(days, bookingCountsThisWeek, bookingCountsLastWeek, maxBookingsCount)),
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
                Expanded(flex: 1, child: _buildEarningsOverviewCard(days, earningsValues, maxEarnings)),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildRecentActivitiesCard()),
              ],
            ),
          ] else ...[
            // Mobile (vertical stack of remaining views)
            _buildBookingsOverviewCard(days, bookingCountsThisWeek, bookingCountsLastWeek, maxBookingsCount),
            const SizedBox(height: 20),
            _buildBookingsByStatusCard(),
            const SizedBox(height: 20),
            _buildTopPerformingResortsCard(),
            const SizedBox(height: 20),
            _buildEarningsOverviewCard(days, earningsValues, maxEarnings),
            const SizedBox(height: 20),
            _buildRecentActivitiesCard(),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- STATS GRID BUILDER ---
  Widget _buildStatsGrid(bool isDesktop, bool isTablet, bool isMobile, int totalResorts, int totalRooms, int totalBookingsCount, String displayEarnings) {
    final customersCount = users.where((u) => u['role'] == '1' || u['role'] == null).length;
    final ownersCount = users.where((u) => u['role'] == '3').length;
    final pendingCount = resorts.where((r) => r['status'] == 'Pending').length;
    final activeCount = resorts.where((r) => r['status'] == 'Approved' || r['status'] == null).length;

    final cards = [
      AdminStatCard(
        title: 'Total Users',
        value: customersCount.toString(),
        subtitle: 'Registered customers',
        icon: Icons.people_alt_rounded,
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
        trendText: '+14%',
        isPositiveTrend: true,
        onTap: () => onNavigate(3),
      ),
      AdminStatCard(
        title: 'Resort Owners',
        value: ownersCount.toString(),
        subtitle: 'Verified property owners',
        icon: Icons.badge_rounded,
        iconBg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF166534),
        trendText: '+8%',
        isPositiveTrend: true,
        onTap: () => onNavigate(5),
      ),
      AdminStatCard(
        title: 'Total Resorts',
        value: totalResorts.toString(),
        subtitle: 'Listed resort properties',
        icon: Icons.holiday_village_rounded,
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        trendText: '+12%',
        isPositiveTrend: true,
        onTap: () => onNavigate(4),
      ),
      AdminStatCard(
        title: 'Total Bookings',
        value: totalBookingsCount.toString(),
        subtitle: 'Completed & active stays',
        icon: Icons.book_online_rounded,
        iconBg: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        trendText: '+19%',
        isPositiveTrend: true,
        onTap: () => onNavigate(2),
      ),
      AdminStatCard(
        title: 'Total Revenue',
        value: displayEarnings,
        subtitle: 'Gross booking revenue',
        icon: Icons.payments_rounded,
        iconBg: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
        trendText: '+24%',
        isPositiveTrend: true,
        onTap: () => onNavigate(8),
      ),
      AdminStatCard(
        title: 'Pending Approvals',
        value: pendingCount.toString(),
        subtitle: 'Resorts awaiting review',
        icon: Icons.hourglass_top_rounded,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
        trendText: pendingCount > 0 ? 'Needs Action' : 'All Clear',
        isPositiveTrend: pendingCount == 0,
        onTap: () => onNavigate(4),
      ),
      AdminStatCard(
        title: 'Active Listings',
        value: activeCount.toString(),
        subtitle: 'Bookable resorts',
        icon: Icons.check_circle_rounded,
        iconBg: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        trendText: 'Live',
        isPositiveTrend: true,
        onTap: () => onNavigate(4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isDesktop ? 4 : (isTablet ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.4 : 1.1),
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isMobile,
  }) {

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: isMobile ? 16 : 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 9,
                      color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CHART 1: BOOKINGS OVERVIEW (LINE CHART) ---
  Widget _buildBookingsOverviewCard(List<String> days, List<double> thisWeek, List<double> lastWeek, double maxVal) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bookings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              Row(
                children: [
                  _buildLegendIndicator(const Color(0xFF0F4C43), 'This Week'),
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
                        if (value % (maxVal / 4) == 0 || value == maxVal) {
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
                maxY: maxVal,
                lineBarsData: [
                  // This Week (Green)
                  LineChartBarData(
                    spots: List.generate(7, (i) => FlSpot(i.toDouble(), thisWeek[i])),
                    isCurved: true,
                    color: const Color(0xFF0F4C43),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0F4C43).withOpacity(0.08),
                    ),
                  ),
                  // Last Week (Orange)
                  LineChartBarData(
                    spots: List.generate(7, (i) => FlSpot(i.toDouble(), lastWeek[i])),
                    isCurved: true,
                    color: const Color(0xFFE5A93C),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE5A93C).withOpacity(0.08),
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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
                              color: const Color(0xFF0F4C43),
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
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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
                      _buildStatusLegend(const Color(0xFF0F4C43), 'Confirmed', '$confirmed (${pctConfirmed.toStringAsFixed(1)}%)'),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Bookings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2D27),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Latest reservation activity',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => onNavigate(2), // Navigate to Bookings view
                child: Text(
                  'View all >',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF0F4C43),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length > 4 ? 4 : bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = bookings[bookings.length - 1 - index]; // Show newest first
              final status = b['status'];
              Color badgeBgColor = Colors.grey.shade100;
              Color statusColor = Colors.grey;

              if (status == 'Confirmed' || status == 'Completed') {
                badgeBgColor = const Color(0xFFE8F5E9);
                statusColor = const Color(0xFF2E7D32);
              } else if (status == 'Pending') {
                badgeBgColor = const Color(0xFFFFF3E0);
                statusColor = const Color(0xFFF57C00);
              } else if (status == 'Cancelled') {
                badgeBgColor = const Color(0xFFFFEBEE);
                statusColor = const Color(0xFFC62828);
              }

              // Extract Initials
              final guestName = b['guestName'] ?? 'Guest';
              final namesList = guestName.trim().split(" ");
              String initials = "";
              if (namesList.isNotEmpty && namesList[0].isNotEmpty) {
                initials += namesList[0][0].toUpperCase();
              }
              if (namesList.length > 1 && namesList[1].isNotEmpty) {
                initials += namesList[1][0].toUpperCase();
              }
              if (initials.isEmpty) initials = "G";

              final avatarBgColors = [
                const Color(0xFF0F4C43),
                const Color(0xFF1E88E5),
                const Color(0xFF8E24AA),
                const Color(0xFFF4511E),
              ];
              final avatarBgColor = avatarBgColors[index % avatarBgColors.length];

              final amount = b['amount'] ?? 0.0;
              final displayAmount = "₹${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

              return Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarBgColor,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guestName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E2D27),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.villa_outlined, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                b['resortName'] ?? 'Resort',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayAmount,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E2D27),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              TextButton(
                onPressed: () => onNavigate(1), // Navigate to Resorts view
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF0F4C43), fontWeight: FontWeight.bold)),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        r['imageUrl'] ?? '',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.villa_outlined, size: 20, color: Colors.grey),
                          );
                        },
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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
        return const Color(0xFF0F4C43);
      case 1:
        return const Color(0xFF5A93E5);
      case 2:
        return const Color(0xFFE5A93C);
      default:
        return Colors.grey.shade400;
    }
  }

  // --- CHART 3: EARNINGS OVERVIEW (BAR CHART) ---
  Widget _buildEarningsOverviewCard(List<String> days, List<double> earnings, double maxVal) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                  SizedBox(width: 2),
                  Text('Active vs last week', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
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
                        if (value % (maxVal / 4) == 0 || value == maxVal) {
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
                barGroups: List.generate(7, (i) => _makeBarGroup(i, earnings[i])),
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
          color: const Color(0xFF0F4C43),
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E2D27)),
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
    final actions = [
      {'icon': Icons.villa_outlined, 'label': 'Resorts Audit', 'index': 4, 'color': const Color(0xFF0F4C43), 'bg': const Color(0xFFF0F4F2)},
      {'icon': Icons.location_on_outlined, 'label': 'Locations', 'index': 1, 'color': const Color(0xFFE5A93C), 'bg': const Color(0xFFFDF5E6)},
      {'icon': Icons.calendar_today_outlined, 'label': 'Bookings Log', 'index': 2, 'color': const Color(0xFF5A93E5), 'bg': const Color(0xFFEEF4FC)},
      {'icon': Icons.people_outline, 'label': 'Platform Guests', 'index': 3, 'color': const Color(0xFFE57373), 'bg': const Color(0xFFFDECEA)},
      {'icon': Icons.storefront_outlined, 'label': 'Resort Owners', 'index': 5, 'color': Colors.purple, 'bg': const Color(0xFFF3E5F5)},
      {'icon': Icons.gpp_good_outlined, 'label': 'Verification', 'index': 6, 'color': Colors.teal, 'bg': const Color(0xFFE0F2F1)},
      {'icon': Icons.campaign_outlined, 'label': 'Promo Codes', 'index': 7, 'color': Colors.pink, 'bg': const Color(0xFFFCE4EC)},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Payouts', 'index': 8, 'color': Colors.indigo, 'bg': const Color(0xFFE8EAF6)},
      {'icon': Icons.chat_bubble_outline, 'label': 'Support Tickets', 'index': 11, 'color': Colors.brown, 'bg': const Color(0xFFEFEBE9)},
      {'icon': Icons.notification_important_outlined, 'label': 'Notifications', 'index': 12, 'color': Colors.orange, 'bg': const Color(0xFFFFF3E0)},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 10, 'color': Colors.blueGrey, 'bg': const Color(0xFFECEFF1)},
      {'icon': Icons.help_outline, 'label': 'Content FAQs', 'index': 9, 'color': Colors.cyan, 'bg': const Color(0xFFE0F7FA)},
      {'icon': Icons.security_outlined, 'label': 'Security Audits', 'index': 13, 'color': Colors.red, 'bg': const Color(0xFFFFEBEE)},
      {'icon': Icons.settings_outlined, 'label': 'System Settings', 'index': 14, 'color': Colors.blueGrey.shade800, 'bg': const Color(0xFFEEEEEE)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2D27),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Launch any module instantly',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: actions.length,
          itemBuilder: (context, idx) {
            final act = actions[idx];
            return _buildQuickActionButton(
              act['icon'] as IconData,
              act['label'] as String,
              act['color'] as Color,
              act['bg'] as Color,
              () => onNavigate(act['index'] as int),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2D27),
                  ),
                ),
              ],
            ),
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
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
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

  Widget _buildLiveOverviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C43), Color(0xFF197365)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C43).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '• LIVE OVERVIEW',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+18% MoM',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Good Morning 👋',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your resort portfolio is performing well',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '20 May 2025 — 26 May 2025',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Search resorts, guests, bookings...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.grey.shade700, size: 18),
              const SizedBox(width: 6),
              Text(
                'Filter',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildBottomMiniCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
            value: '94%',
            label: 'Verified',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBottomMiniCard(
            icon: Icons.trending_up,
            iconColor: const Color(0xFF1E88E5),
            bgColor: const Color(0xFFE3F2FD),
            value: '78%',
            label: 'Occupancy',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBottomMiniCard(
            icon: Icons.star_outline,
            iconColor: const Color(0xFFF57C00),
            bgColor: const Color(0xFFFFF3E0),
            value: '4.7★',
            label: 'Avg Rating',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomMiniCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E2D27),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

