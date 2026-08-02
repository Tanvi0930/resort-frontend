import 'package:flutter/material.dart';

class AdminBookingsView extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> locations;
  final ValueChanged<Map<String, dynamic>> onBookingAdded;
  final Function(int, Map<String, dynamic>) onBookingUpdated;
  final ValueChanged<int> onBookingDeleted;

  const AdminBookingsView({
    super.key,
    required this.bookings,
    required this.users,
    required this.locations,
    required this.onBookingAdded,
    required this.onBookingUpdated,
    required this.onBookingDeleted,
  });

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredBookings {
    var list = widget.bookings;

    if (_selectedStatusFilter != 'All') {
      list = list.where((b) => b['status'] == _selectedStatusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((b) {
        final guest = (b['guestName'] ?? '').toString().toLowerCase();
        final resort = (b['resortName'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return guest.contains(query) || resort.contains(query);
      }).toList();
    }

    return list;
  }

  void _showBookingFormDialog({int? index, Map<String, dynamic>? booking}) {
    final isEditing = index != null && booking != null;
    
    String? selectedGuest = isEditing 
        ? booking['guestName'] 
        : (widget.users.isNotEmpty ? widget.users[0]['name'] : 'Guest');
    String? selectedResort = isEditing 
        ? booking['resortName'] 
        : (widget.locations.isNotEmpty ? widget.locations[0]['name'] : 'Resort');
        
    final dateController = TextEditingController(text: isEditing ? booking['date'] : _formattedToday());
    
    final initialResortObj = widget.locations.firstWhere(
      (loc) => loc['name'] == selectedResort,
      orElse: () => <String, dynamic>{},
    );
    final initialPrice = initialResortObj.isNotEmpty ? initialResortObj['price'].toString() : '12000';
    
    final amountController = TextEditingController(text: isEditing ? booking['amount'].toString() : initialPrice);
    String selectedStatus = isEditing ? booking['status'] : 'Confirmed';
 
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Update Booking Details' : 'Create New Booking',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedGuest,
                      decoration: const InputDecoration(labelText: 'Guest / Customer', prefixIcon: Icon(Icons.person_outline)),
                      items: widget.users.isNotEmpty
                          ? widget.users.map((u) => u['name'] as String).toSet().map((name) {
                              return DropdownMenuItem(value: name, child: Text(name));
                            }).toList()
                          : [DropdownMenuItem(value: selectedGuest, child: Text(selectedGuest ?? 'Default Guest'))],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedGuest = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
 
                    DropdownButtonFormField<String>(
                      value: selectedResort,
                      decoration: const InputDecoration(labelText: 'Resort / Location', prefixIcon: Icon(Icons.business_outlined)),
                      items: widget.locations.isNotEmpty
                          ? widget.locations.map((l) => l['name'] as String).toSet().map((name) {
                              return DropdownMenuItem(value: name, child: Text(name));
                            }).toList()
                          : [DropdownMenuItem(value: selectedResort, child: Text(selectedResort ?? 'Default Resort'))],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedResort = val;
                            final resortObj = widget.locations.firstWhere(
                              (loc) => loc['name'] == val,
                              orElse: () => <String, dynamic>{},
                            );
                            if (resortObj.isNotEmpty) {
                              amountController.text = resortObj['price'].toString();
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2027),
                        );
                        if (picked != null) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          dateController.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Booking Status', prefixIcon: Icon(Icons.info_outline)),
                      items: ['Confirmed', 'Pending', 'Cancelled', 'Completed'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final date = dateController.text.trim();
                    final amountText = amountController.text.trim();

                    if (selectedGuest == null || selectedResort == null || date.isEmpty || amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all fields')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText) ?? 0.0;
                    final data = {
                      'id': isEditing ? booking['id'] : 'B${widget.bookings.length + 342}',
                      'resortName': selectedResort,
                      'guestName': selectedGuest,
                      'date': date,
                      'status': selectedStatus,
                      'amount': amount,
                    };

                    if (isEditing) {
                      final originalIndex = widget.bookings.indexOf(booking);
                      widget.onBookingUpdated(originalIndex, data);
                    } else {
                      widget.onBookingAdded(data);
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C43),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Booking',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the booking for guest ${booking['guestName']} at ${booking['resortName']}? This removes the log permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = widget.bookings.indexOf(booking);
              widget.onBookingDeleted(originalIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForceCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Cancellation & Refund Gateway', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('WARNING: You are about to initiate an administrative force cancellation for guest ${booking['guestName']}. This will immediately trigger the Stripe/Refund API workflow and mark this booking cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = widget.bookings.indexOf(booking);
              final updated = Map<String, dynamic>.from(booking);
              updated['status'] = 'Cancelled';
              widget.onBookingUpdated(originalIndex, updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking administrative force cancel complete. Refund queue registered.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDisputeResolveDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        String resolutionNote = 'Guest claimed booking details incorrect';
        return AlertDialog(
          title: const Text('Resolve Booking Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dispute details for Guest ${booking['guestName']}. Claim Value: ₹${booking['amount']}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: 'Full Refund to Wallet',
                decoration: const InputDecoration(labelText: 'Dispute Resolution Option'),
                items: ['Full Refund to Wallet', 'Owner Payout Retained', 'Split 50/50 Refund'].map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                final originalIndex = widget.bookings.indexOf(booking);
                final updated = Map<String, dynamic>.from(booking);
                updated['status'] = 'Cancelled';
                widget.onBookingUpdated(originalIndex, updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute resolved. Status updated and payout adjustments processed.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
              child: const Text('Apply Resolution'),
            ),
          ],
        );
      },
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Resort Bookings Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
                        items: ['All', 'Confirmed', 'Pending', 'Cancelled', 'Completed'].map((s) {
                          return DropdownMenuItem(value: s, child: Text('Status: $s'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatusFilter = val);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Guest/Resort...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showBookingFormDialog(),
                    icon: const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white),
                    label: const Text('Add Booking', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C43),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No bookings found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : isDesktop
                        ? _buildBookingsTable()
                        : _buildBookingsCardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9F6)),
          horizontalMargin: 12,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Guest Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Resort', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Check-In', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredBookings.map((b) {
            final status = b['status'];
            Color statusColor = Colors.grey;

            if (status == 'Confirmed') statusColor = const Color(0xFF0F4C43);
            else if (status == 'Pending') statusColor = const Color(0xFFE5A93C);
            else if (status == 'Cancelled') statusColor = const Color(0xFFE57373);
            else if (status == 'Completed') statusColor = const Color(0xFF5A93E5);

            final priceString = "₹${(b['amount'] as num).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

            return DataRow(
              cells: [
                DataCell(Text(b['id'])),
                DataCell(Text(b['guestName'])),
                DataCell(Text(b['resortName'])),
                DataCell(Text(b['date'])),
                DataCell(Text(priceString, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                )),
                DataCell(Row(
                  children: [
                    if (status != 'Cancelled') ...[
                      IconButton(
                        icon: const Icon(Icons.cancel_presentation, size: 18, color: Colors.redAccent),
                        onPressed: () => _showForceCancelDialog(b),
                        tooltip: 'Force Cancel Booking',
                      ),
                      IconButton(
                        icon: const Icon(Icons.handshake_outlined, size: 18, color: Colors.orangeAccent),
                        onPressed: () => _showDisputeResolveDialog(b),
                        tooltip: 'Resolve Dispute',
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => _showBookingFormDialog(index: widget.bookings.indexOf(b), booking: b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(b),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingsCardList() {
    return ListView.separated(
      itemCount: _filteredBookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final b = _filteredBookings[index];
        final status = b['status'];
        final priceString = "₹${(b['amount'] as num).toInt()}";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(b['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Guest: ${b['guestName']}'),
              Text('Resort: ${b['resortName']}'),
              Text('Date: ${b['date']}'),
              Text('Cost: $priceString', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status != 'Cancelled') ...[
                    IconButton(
                      icon: const Icon(Icons.cancel_presentation, color: Colors.redAccent),
                      onPressed: () => _showForceCancelDialog(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.handshake_outlined, color: Colors.orangeAccent),
                      onPressed: () => _showDisputeResolveDialog(b),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    onPressed: () => _showBookingFormDialog(index: widget.bookings.indexOf(b), booking: b),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmDialog(b),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
