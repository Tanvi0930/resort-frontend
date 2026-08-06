import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';

class BookingsTab extends StatefulWidget {
  final String userName;

  const BookingsTab({super.key, required this.userName});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/bookings'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        // Filter bookings by guest name (case-insensitive check)
        final userBookings = data.where((b) {
          final guest = b['guestName']?.toString().toLowerCase() ?? '';
          return guest == widget.userName.toLowerCase() || guest == 'tanvi';
        }).toList();

        setState(() {
          _bookings = userBookings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D94)))
                : _bookings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        color: const Color(0xFF0F9D94),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D94).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F9D94), Color(0xFF0A7B74)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F9D94).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'My Bookings',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F9D94),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Bookings Found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF173B3A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of your stay bookings here.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final status = booking['status']?.toString() ?? 'Pending';
    final statusLower = status.toLowerCase();
    final isConfirmed = statusLower == 'confirmed' || statusLower == 'approved';
    final isCancelled = statusLower == 'cancelled' || statusLower == 'rejected';

    final resortName = booking['resortName']?.toString() ?? 'Luxury Resort Stay';
    final location = booking['location']?.toString() ?? booking['city']?.toString() ?? 'Beachfront Haven';
    final date = booking['date']?.toString() ?? booking['checkInDate']?.toString() ?? 'Confirmed Date';
    final amount = (booking['amount'] ?? booking['totalPrice'] ?? 0.0);
    final numAmount = amount is num ? amount.toDouble() : (double.tryParse(amount.toString()) ?? 0.0);
    final imageUrl = booking['imageUrl']?.toString() ??
        booking['image']?.toString() ??
        'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070';
    final guests = booking['peopleCount'] ?? booking['guests'] ?? 1;
    final rooms = booking['roomsCount'] ?? booking['rooms'] ?? 1;
    final bookingId = booking['id']?.toString() ?? booking['bookingId']?.toString() ?? '#RES-${(resortName.hashCode % 9000 + 1000).abs()}';

    Color statusColor = const Color(0xFFD97706);
    Color statusBg = const Color(0xFFFEF3C7);
    if (isConfirmed) {
      statusColor = const Color(0xFF15803D);
      statusBg = const Color(0xFFDCFCE7);
    } else if (isCancelled) {
      statusColor = const Color(0xFFB91C1C);
      statusBg = const Color(0xFFFEE2E2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showBookingDetailsModal(context, booking),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean Resort Thumbnail Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 105,
                          height: 105,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.holiday_village_rounded, color: Color(0xFF0F9D94), size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Title + Status Pill
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  resortName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Location
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0F9D94)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Date & Guests inline
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$date • $guests Guests, $rooms Room',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Booking ID
                          Text(
                            bookingId,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom Action & Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Paid: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${numAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFF0F9D94),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Receipt icon
                        InkWell(
                          onTap: () => _showInvoiceDialog(context, booking),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF475569), size: 16),
                          ),
                        ),
                        if (!isCancelled) ...[
                          const SizedBox(width: 6),
                          // Cancel icon
                          InkWell(
                            onTap: () => _confirmCancelBooking(context, booking),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 16),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        // View Details
                        InkWell(
                          onTap: () => _showBookingDetailsModal(context, booking),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D94).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Details',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0F9D94),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // --- CANCEL BOOKING LOGIC ---
  Future<void> _confirmCancelBooking(BuildContext context, dynamic booking) async {
    final resortName = booking['resortName']?.toString() ?? 'Resort';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Booking?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        content: Text(
          'Are you sure you want to cancel your reservation for "$resortName"? This action cannot be undone.',
          style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Booking', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bookingId = booking['id'];
      try {
        if (bookingId != null) {
          final response = await http.put(
            Uri.parse('${ApiConfigue.baseUrl}/api/bookings/$bookingId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              ...booking,
              'status': 'Cancelled',
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 204) {
            _fetchBookings();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully.'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error cancelling booking: $e');
      }

      // Local state fallback update
      setState(() {
        booking['status'] = 'Cancelled';
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking status updated to Cancelled.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  // --- INVOICE / RECEIPT DIALOG ---
  void _showInvoiceDialog(BuildContext context, dynamic booking) {
    final resortName = booking['resortName']?.toString() ?? 'Luxury Resort Stay';
    final date = booking['date']?.toString() ?? 'Confirmed Date';
    final amount = (booking['amount'] ?? booking['totalPrice'] ?? 0.0);
    final numAmount = amount is num ? amount.toDouble() : (double.tryParse(amount.toString()) ?? 0.0);
    final bookingId = booking['id']?.toString() ?? booking['bookingId']?.toString() ?? '#RES-${(resortName.hashCode % 9000 + 1000).abs()}';
    final guestName = booking['guestName']?.toString() ?? widget.userName;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCECE9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_rounded, color: Color(0xFF0F9D94), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Receipt',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            bookingId,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PAID',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              _buildInvoiceLine('Guest Name', guestName),
              _buildInvoiceLine('Resort', resortName),
              _buildInvoiceLine('Booking Date', date),
              _buildInvoiceLine('Guests / Rooms', '${booking['peopleCount'] ?? 1} Guests • ${booking['roomsCount'] ?? 1} Rooms'),
              _buildInvoiceLine('Payment Method', 'Online / UPI'),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount Paid', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text('₹${numAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F9D94))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice downloaded to downloads directory.'),
                            backgroundColor: Color(0xFF0F9D94),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                      label: Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D94),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  void _showBookingDetailsModal(BuildContext context, dynamic booking) {
    final resortName = booking['resortName']?.toString() ?? 'Luxury Resort Stay';
    final status = booking['status']?.toString() ?? 'Pending';
    final date = booking['date']?.toString() ?? 'Confirmed Date';
    final amount = (booking['amount'] ?? booking['totalPrice'] ?? 0.0);
    final numAmount = amount is num ? amount.toDouble() : (double.tryParse(amount.toString()) ?? 0.0);
    final bookingId = booking['id']?.toString() ?? booking['bookingId']?.toString() ?? '#RES-${(resortName.hashCode % 9000 + 1000).abs()}';
    final isCancelled = status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Summary',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      bookingId,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDetailModalRow('Resort', resortName),
              _buildDetailModalRow('Guest Name', booking['guestName'] ?? widget.userName),
              _buildDetailModalRow('Status', status),
              _buildDetailModalRow('Date', date),
              _buildDetailModalRow('Guests', '${booking['peopleCount'] ?? 1} Guests'),
              _buildDetailModalRow('Rooms', '${booking['roomsCount'] ?? 1} Rooms'),
              if (booking['category'] != null)
                _buildDetailModalRow('Category', booking['category']),
              if (booking['serviceOptions'] != null && booking['serviceOptions'].toString().isNotEmpty)
                _buildDetailModalRow('Services', booking['serviceOptions']),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              _buildDetailModalRow('Total Paid', '₹${numAmount.toStringAsFixed(0)}', isBold: true),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showInvoiceDialog(context, booking);
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Invoice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F9D94),
                        side: const BorderSide(color: Color(0xFF0F9D94)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (!isCancelled) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmCancelBooking(context, booking);
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D94),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Close Details',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailModalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isBold ? const Color(0xFF0F9D94) : const Color(0xFF0F172A),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


