import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_configue.dart';
import '../services/auth_service.dart';
import '../widgets/qr_code_widget.dart';
import '../widgets/resort_image_widget.dart';
import 'main_screen.dart';

class BookingScreen extends StatefulWidget {
  final dynamic resortData;

  const BookingScreen({super.key, required this.resortData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Step 1: Visit Date Selection
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));

  // Step 2: Ticket Type Quantities
  int _adultCount = 1;
  int _childCount = 0;
  int _seniorCount = 0;

  // Pricing constants (Dynamic calculation)
  double get _adultPrice => ((widget.resortData['price'] as num?)?.toDouble() ?? 699.0);
  double get _childPrice => (_adultPrice * 0.6).roundToDouble();
  double get _seniorPrice => (_adultPrice * 0.75).roundToDouble();

  // Step 3: Extra Services Quantities
  int _lockerCount = 0;
  int _costumeCount = 0;
  int _foodComboCount = 0;
  int _parkingCount = 0;
  int _vipEntryCount = 0;

  static const double _lockerUnitCost = 150.0;
  static const double _costumeUnitCost = 100.0;
  static const double _foodComboUnitCost = 250.0;
  static const double _parkingUnitCost = 50.0;
  static const double _vipEntryUnitCost = 300.0;

  // Step 4: Coupon Code
  final TextEditingController _couponController = TextEditingController();
  String _appliedCoupon = '';
  double _discountAmount = 0.0;
  String _couponStatusMessage = '';
  bool _couponSuccess = false;

  // Step 5: Payment Method Selection
  String _selectedPaymentMethod = 'UPI'; // UPI, Card, NetBanking, Wallet
  String _selectedSubPayment = 'Google Pay';
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  // Booking Flow State
  bool _isProcessingPayment = false;
  bool _isBookingConfirmed = false;
  Map<String, dynamic>? _confirmedBookingPayload;
  String _generatedBookingId = '';

  String _loggedInUserName = 'Guest User';

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final name = await AuthService.getSavedName();
    if (name.isNotEmpty && mounted) {
      setState(() {
        _loggedInUserName = name;
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  // --- Dynamic Pricing Calculations ---
  int get _totalVisitors => _adultCount + _childCount + _seniorCount;

  double get _ticketsSubtotal =>
      (_adultCount * _adultPrice) +
      (_childCount * _childPrice) +
      (_seniorCount * _seniorPrice);

  double get _extraServicesSubtotal =>
      (_lockerCount * _lockerUnitCost) +
      (_costumeCount * _costumeUnitCost) +
      (_foodComboCount * _foodComboUnitCost) +
      (_parkingCount * _parkingUnitCost) +
      (_vipEntryCount * _vipEntryUnitCost);

  double get _rawSubtotal => _ticketsSubtotal + _extraServicesSubtotal;

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _appliedCoupon = '';
        _discountAmount = 0.0;
        _couponStatusMessage = 'Please enter a coupon code';
        _couponSuccess = false;
      });
      return;
    }

    double discount = 0.0;
    String message = '';
    bool success = false;

    if (code == 'AQUA20') {
      discount = _rawSubtotal * 0.20;
      message = 'AQUA20 Applied! 20% discount';
      success = true;
    } else if (code == 'WATERPARK100') {
      discount = 100.0;
      message = 'WATERPARK100 Applied! ₹100 Flat off';
      success = true;
    } else if (code == 'SUMMER15') {
      discount = _rawSubtotal * 0.15;
      message = 'SUMMER15 Applied! 15% discount';
      success = true;
    } else if (code == 'FIRST50') {
      discount = 50.0;
      message = 'FIRST50 Applied! ₹50 Flat off';
      success = true;
    } else {
      discount = 0.0;
      message = 'Invalid Coupon Code. Try AQUA20 or WATERPARK100';
      success = false;
    }

    setState(() {
      _appliedCoupon = success ? code : '';
      _discountAmount = discount;
      _couponStatusMessage = message;
      _couponSuccess = success;
    });
  }

  void _autoFillTestCredentials() {
    setState(() {
      if (_selectedPaymentMethod == 'UPI') {
        _upiIdController.text = 'sandbox.test@upi';
        _selectedSubPayment = 'Google Pay';
      } else if (_selectedPaymentMethod == 'Card') {
        _cardNumberController.text = '4111 2222 3333 4444';
        _cardExpiryController.text = '12/28';
        _cardCvvController.text = '123';
        _cardHolderController.text = 'TEST DEMO USER';
      } else if (_selectedPaymentMethod == 'Net Banking') {
        _selectedSubPayment = 'HDFC Bank';
      } else {
        _selectedSubPayment = 'Paytm Wallet';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Free Sandbox Test Key & Credentials Auto-Filled!'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );
  }

  double get _taxableAmount => math.max(0.0, _rawSubtotal - _discountAmount);
  double get _gstTaxAmount => _taxableAmount * 0.18; // 18% GST
  double get _finalTotalAmount => _taxableAmount + _gstTaxAmount;

  // --- Step 7: Complete Payment & Submit Booking ---
  Future<void> _processPaymentAndConfirm() async {
    if (_totalVisitors <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 visitor (Adult, Child, or Senior).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    // Simulate 2-second payment processing & security check
    await Future.delayed(const Duration(milliseconds: 1800));

    final resortName = (widget.resortData['name'] ?? 'Water Park').toString();
    final String formattedDate = "${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}";
    final String generatedId = "AQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    // Build itemized extra services list
    final List<String> extraServicesList = [];
    if (_lockerCount > 0) extraServicesList.add('Locker (x$_lockerCount)');
    if (_costumeCount > 0) extraServicesList.add('Costume (x$_costumeCount)');
    if (_foodComboCount > 0) extraServicesList.add('Food Combo (x$_foodComboCount)');
    if (_parkingCount > 0) extraServicesList.add('Parking (x$_parkingCount)');
    if (_vipEntryCount > 0) extraServicesList.add('VIP Entry (x$_vipEntryCount)');

    final String serviceOptionsStr = extraServicesList.join(', ');

    final Map<String, dynamic> bookingPayload = {
      'resortName': resortName,
      'guestName': _loggedInUserName,
      'date': formattedDate,
      'status': 'Confirmed',
      'amount': _finalTotalAmount,
      'category': 'Water Park',
      'peopleCount': _totalVisitors,
      'roomsCount': 0,
      'lockersCount': _lockerCount,
      'serviceOptions': serviceOptionsStr.isNotEmpty ? serviceOptionsStr : 'Standard Entry',
    };

    // Post to Spring Boot Backend /api/bookings
    try {
      final response = await http.post(
        Uri.parse('${ApiConfigue.baseUrl}/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingPayload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = json.decode(response.body);
        if (resData['id'] != null) {
          bookingPayload['id'] = resData['id'];
        }
      }
    } catch (e) {
      debugPrint('Note: Posted locally fallback for backend: $e');
    }

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = false;
      _isBookingConfirmed = true;
      _generatedBookingId = generatedId;
      _confirmedBookingPayload = {
        ...bookingPayload,
        'adultCount': _adultCount,
        'childCount': _childCount,
        'seniorCount': _seniorCount,
        'subtotal': _rawSubtotal,
        'discount': _discountAmount,
        'gst': _gstTaxAmount,
        'paymentMethod': '$_selectedPaymentMethod ($_selectedSubPayment)',
        'qrData': '$generatedId|$resortName|$formattedDate|$_totalVisitors Visitors|₹${_finalTotalAmount.toStringAsFixed(0)}',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBookingConfirmed && _confirmedBookingPayload != null) {
      return _buildConfirmationScreen();
    }

    final resortName = (widget.resortData['name'] ?? 'Water Park').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Water Park Tickets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              resortName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F9D94), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Resort Banner with photos from File Server / Owner Panel
                ResortImageWidget(
                  resort: widget.resortData is Map<String, dynamic> ? widget.resortData : <String, dynamic>{'name': resortName},
                  height: 160,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 18),

                // STEP 1: Select Visit Date
                _buildSectionHeader(Icons.calendar_today_rounded, '1. Select Visit Date'),
                const SizedBox(height: 10),
                _buildDatePickerCard(),
                const SizedBox(height: 24),

                // STEP 2: Select Ticket Types & Visitors
                _buildSectionHeader(Icons.confirmation_number_outlined, '2. Select Ticket Types'),
                const SizedBox(height: 10),
                _buildCounterTile('Adult (Age 12+)', '₹${_adultPrice.toStringAsFixed(0)} / person', _adultCount, (val) => setState(() => _adultCount = val)),
                const SizedBox(height: 8),
                _buildCounterTile('Child (Height 3-4.5ft)', '₹${_childPrice.toStringAsFixed(0)} / child', _childCount, (val) => setState(() => _childCount = val), min: 0),
                const SizedBox(height: 8),
                _buildCounterTile('Senior Citizen (Age 60+)', '₹${_seniorPrice.toStringAsFixed(0)} / senior', _seniorCount, (val) => setState(() => _seniorCount = val), min: 0),
                const SizedBox(height: 24),

                // STEP 3: Add Extra Services (Optional)
                _buildSectionHeader(Icons.stars_rounded, '3. Add Extra Services (Optional)'),
                const SizedBox(height: 10),
                _buildCounterTile('Locker Rental', '₹${_lockerUnitCost.toStringAsFixed(0)} / locker', _lockerCount, (val) => setState(() => _lockerCount = val), min: 0),
                const SizedBox(height: 8),
                _buildCounterTile('Swimwear Costume', '₹${_costumeUnitCost.toStringAsFixed(0)} / set', _costumeCount, (val) => setState(() => _costumeCount = val), min: 0),
                const SizedBox(height: 8),
                _buildCounterTile('Food Combo Meal', '₹${_foodComboUnitCost.toStringAsFixed(0)} / meal', _foodComboCount, (val) => setState(() => _foodComboCount = val), min: 0),
                const SizedBox(height: 8),
                _buildCounterTile('Vehicle Parking Pass', '₹${_parkingUnitCost.toStringAsFixed(0)} / vehicle', _parkingCount, (val) => setState(() => _parkingCount = val), min: 0),
                const SizedBox(height: 8),
                _buildCounterTile('VIP Express Line Pass', '₹${_vipEntryUnitCost.toStringAsFixed(0)} / person', _vipEntryCount, (val) => setState(() => _vipEntryCount = val), min: 0),
                const SizedBox(height: 24),

                // STEP 4: Apply Coupon Code (Optional)
                _buildSectionHeader(Icons.local_offer_outlined, '4. Apply Coupon Code'),
                const SizedBox(height: 10),
                _buildCouponCard(),
                const SizedBox(height: 24),

                // STEP 5: Booking Summary Breakdown
                _buildSectionHeader(Icons.receipt_long_rounded, '5. Booking Summary'),
                const SizedBox(height: 10),
                _buildSummaryCard(),
                const SizedBox(height: 24),

                // STEP 6: Select Payment Method
                _buildSectionHeader(Icons.account_balance_wallet_outlined, '6. Select Payment Method'),
                const SizedBox(height: 10),
                _buildPaymentMethodCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Processing Payment Overlay Modal
          if (_isProcessingPayment)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(color: Color(0xFF0F9D94), strokeWidth: 3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Processing Payment...',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connecting to $_selectedPaymentMethod securely',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _buildBottomPayBar(),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0F9D94), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --- Step 1: Visit Date Selection Card ---
  Widget _buildDatePickerCard() {
    final String formatted = "${_visitDate.day} ${_getMonthName(_visitDate.month)} ${_visitDate.year}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D94).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded, color: Color(0xFF0F9D94), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visit Date', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                    Text(
                      formatted,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickCustomDate,
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Change Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D94),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickDateChip('Today', DateTime.now()),
              const SizedBox(width: 8),
              _buildQuickDateChip('Tomorrow', DateTime.now().add(const Duration(days: 1))),
              const SizedBox(width: 8),
              _buildQuickDateChip('Weekend', _getNextSaturday()),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _getNextSaturday() {
    final now = DateTime.now();
    int daysUntilSat = (DateTime.saturday - now.weekday) % 7;
    if (daysUntilSat == 0) daysUntilSat = 7;
    return now.add(Duration(days: daysUntilSat));
  }

  Widget _buildQuickDateChip(String label, DateTime targetDate) {
    final isSelected = _visitDate.year == targetDate.year &&
        _visitDate.month == targetDate.month &&
        _visitDate.day == targetDate.day;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _visitDate = targetDate),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F9D94) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F9D94),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  // --- Step 2 & 3: Counter Tile Widget ---
  Widget _buildCounterTile(String title, String subtitle, int value, ValueChanged<int> onChanged, {int min = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: value > min ? const Color(0xFF0F9D94) : Colors.grey.shade400,
                iconSize: 22,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: const Color(0xFF0F9D94),
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 4: Coupon Card ---
  Widget _buildCouponCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter Coupon (e.g. AQUA20)',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F9D94)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D94),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_couponStatusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _couponStatusMessage,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _couponSuccess ? const Color(0xFF15803D) : Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Step 5: Summary Card ---
  Widget _buildSummaryCard() {
    final String formattedDate = "${_visitDate.day} ${_getMonthName(_visitDate.month)} ${_visitDate.year}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Date of Visit', formattedDate),
          _buildSummaryRow('Visitors Breakdown', '$_adultCount Adult, $_childCount Child, $_seniorCount Senior'),
          if (_adultCount > 0) _buildSummaryRow('  • Adult Tickets (x$_adultCount)', '₹${(_adultCount * _adultPrice).toStringAsFixed(0)}'),
          if (_childCount > 0) _buildSummaryRow('  • Child Tickets (x$_childCount)', '₹${(_childCount * _childPrice).toStringAsFixed(0)}'),
          if (_seniorCount > 0) _buildSummaryRow('  • Senior Tickets (x$_seniorCount)', '₹${(_seniorCount * _seniorPrice).toStringAsFixed(0)}'),
          const Divider(height: 16),

          if (_extraServicesSubtotal > 0) ...[
            _buildSummaryRow('Extra Services Total', '₹${_extraServicesSubtotal.toStringAsFixed(0)}'),
            if (_lockerCount > 0) _buildSummaryRow('  • Locker (x$_lockerCount)', '₹${(_lockerCount * _lockerUnitCost).toStringAsFixed(0)}'),
            if (_costumeCount > 0) _buildSummaryRow('  • Costume (x$_costumeCount)', '₹${(_costumeCount * _costumeUnitCost).toStringAsFixed(0)}'),
            if (_foodComboCount > 0) _buildSummaryRow('  • Food Combo (x$_foodComboCount)', '₹${(_foodComboCount * _foodComboUnitCost).toStringAsFixed(0)}'),
            if (_parkingCount > 0) _buildSummaryRow('  • Parking Pass (x$_parkingCount)', '₹${(_parkingCount * _parkingUnitCost).toStringAsFixed(0)}'),
            if (_vipEntryCount > 0) _buildSummaryRow('  • VIP Entry (x$_vipEntryCount)', '₹${(_vipEntryCount * _vipEntryUnitCost).toStringAsFixed(0)}'),
            const Divider(height: 16),
          ],

          _buildSummaryRow('Subtotal', '₹${_rawSubtotal.toStringAsFixed(0)}'),
          if (_discountAmount > 0)
            _buildSummaryRow('Discount ($_appliedCoupon)', '-₹${_discountAmount.toStringAsFixed(0)}', isDiscount: true),
          _buildSummaryRow('GST Tax (18%)', '₹${_gstTaxAmount.toStringAsFixed(0)}'),
          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Payable',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                '₹${_finalTotalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F9D94)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDiscount ? const Color(0xFF15803D) : const Color(0xFF475569),
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? const Color(0xFF15803D) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 6: Payment Method Card ---
  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FREE TEST KEY SANDBOX BANNER
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_rounded, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'FREE TEST GATEWAY KEY',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SANDBOX ENABLED',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Key ID: rzp_test_free_aqua2026',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _autoFillTestCredentials,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '⚡ Auto-Fill Free Test Credentials',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              _buildPaymentTab('UPI', Icons.qr_code_2_rounded),
              const SizedBox(width: 8),
              _buildPaymentTab('Card', Icons.credit_card_rounded),
              const SizedBox(width: 8),
              _buildPaymentTab('Net Banking', Icons.account_balance_rounded),
              const SizedBox(width: 8),
              _buildPaymentTab('Wallet', Icons.account_balance_wallet_rounded),
            ],
          ),
          const SizedBox(height: 14),

          if (_selectedPaymentMethod == 'UPI') ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'UPI ID'].map((upiApp) {
                final isSelected = _selectedSubPayment == upiApp;
                return ChoiceChip(
                  label: Text(upiApp),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F9D94),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (val) => setState(() => _selectedSubPayment = upiApp),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _upiIdController,
              decoration: InputDecoration(
                labelText: 'UPI ID (Optional Test Key)',
                hintText: 'e.g. sandbox.test@upi',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else if (_selectedPaymentMethod == 'Card') ...[
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Test Card Number',
                hintText: '4111 2222 3333 4444',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExpiryController,
                    decoration: InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '12/28',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cardCvvController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_selectedPaymentMethod == 'Net Banking') ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['HDFC Bank', 'SBI', 'ICICI Bank', 'Axis Bank', 'Kotak'].map((bank) {
                final isSelected = _selectedSubPayment == bank;
                return ChoiceChip(
                  label: Text(bank),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F9D94),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (val) => setState(() => _selectedSubPayment = bank),
                );
              }).toList(),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Paytm Wallet', 'Amazon Pay', 'MobiKwik'].map((wallet) {
                final isSelected = _selectedSubPayment == wallet;
                return ChoiceChip(
                  label: Text(wallet),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F9D94),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (val) => setState(() => _selectedSubPayment = wallet),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTab(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = title;
            _selectedSubPayment = title == 'UPI' ? 'Google Pay' : (title == 'Net Banking' ? 'HDFC Bank' : 'Paytm Wallet');
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F9D94) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF475569)),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPayBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                '₹${_finalTotalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F9D94)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessingPayment ? null : _processPaymentAndConfirm,
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: Text(
                'Pay & Confirm',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D94),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 8 & 9: Confirmation Screen & Dynamic QR Code Ticket ---
  Widget _buildConfirmationScreen() {
    final payload = _confirmedBookingPayload!;
    final resortName = payload['resortName'] ?? 'Water Park';
    final String date = payload['date'] ?? '';
    final String qrData = payload['qrData'] ?? _generatedBookingId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: const Text('Booking Confirmed!'),
        backgroundColor: const Color(0xFF0F9D94),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entry Pass Confirmed!',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    resortName,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F9D94), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // DYNAMIC QR CODE TICKET
                  QrCodeWidget(
                    data: qrData,
                    size: 200,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ticket ID: $_generatedBookingId',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Show this QR Code at the Entry Gate for scanning',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildSummaryRow('Guest Name', _loggedInUserName),
                  _buildSummaryRow('Visit Date', date),
                  _buildSummaryRow('Visitors', '$_totalVisitors Person(s) (${payload['adultCount']} Adult, ${payload['childCount']} Child)'),
                  _buildSummaryRow('Services', payload['serviceOptions']),
                  _buildSummaryRow('Payment Method', payload['paymentMethod']),
                  _buildSummaryRow('Total Paid', '₹${_finalTotalAmount.toStringAsFixed(0)}', isDiscount: false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainScreen(
                            userId: '1',
                            userName: _loggedInUserName,
                            userPhone: '',
                            userEmail: '',
                            userRole: '1',
                            initialTab: 2, // Go directly to My Bookings tab!
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('View My Bookings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F9D94),
                      side: const BorderSide(color: Color(0xFF0F9D94)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('E-Ticket QR downloaded to gallery.'),
                          backgroundColor: Color(0xFF0F9D94),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D94),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }
}
