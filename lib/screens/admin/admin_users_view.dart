import 'package:flutter/material.dart';

class AdminUsersView extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> bookings; // Dynamic bookings list
  final ValueChanged<Map<String, dynamic>> onUserAdded;
  final Function(int, Map<String, dynamic>) onUserUpdated;
  final ValueChanged<int> onUserDeleted;

  const AdminUsersView({
    super.key,
    required this.users,
    required this.bookings,
    required this.onUserAdded,
    required this.onUserUpdated,
    required this.onUserDeleted,
  });

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  Widget _buildSummaryCard(String label, String count, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(count, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E2D27))),
            ],
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.users;
    return widget.users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  // User History Dialog containing Live Logs & Bookings
  void _showUserHistoryDialog(Map<String, dynamic> user) {
    // Dynamically filter bookings for the selected guest
    final userBookings = widget.bookings
        .where((b) => b['guestName'].toString().toLowerCase() == user['name'].toString().toLowerCase())
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Activity & Booking History: ${user['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Booking History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF7F9F6), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                    child: userBookings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('No bookings found for this user.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                          )
                        : Column(
                            children: userBookings.map((b) {
                              final status = b['status'] ?? 'Pending';
                              return ListTile(
                                dense: true,
                                title: Text(b['resortName'] ?? 'Resort'),
                                subtitle: Text('Booking #${b['id']} • Amount: ₹${(b['amount'] as num).toInt()} • Date: ${b['date']}'),
                                trailing: Chip(
                                  label: Text(status, style: TextStyle(
                                    color: status == 'Confirmed' || status == 'Completed' ? Colors.green : Colors.red,
                                    fontSize: 9,
                                  )),
                                  backgroundColor: status == 'Confirmed' || status == 'Completed'
                                      ? const Color(0xFFF0F4F2)
                                      : const Color(0xFFFDECEA),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  // Dialog to Add or Edit User
  void _showUserFormDialog({int? index, Map<String, dynamic>? user}) {
    final isEditing = index != null && user != null;
    final nameController = TextEditingController(text: isEditing ? user['name'] : '');
    final emailController = TextEditingController(text: isEditing ? user['email'] : '');
    final phoneController = TextEditingController(text: isEditing ? user['phone'] : '');
    String selectedUserType = isEditing ? (user['role'] ?? '1') : '1';
    String selectedStatus = isEditing ? user['status'] : 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit User Details' : 'Add New User',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUserType,
                            decoration: const InputDecoration(labelText: 'User Type / Role'),
                            items: const [
                              DropdownMenuItem(value: '1', child: Text('1 - Regular User')),
                              DropdownMenuItem(value: '2', child: Text('2 - System Admin')),
                              DropdownMenuItem(value: '3', child: Text('3 - Resort Owner')),
                              DropdownMenuItem(value: '4', child: Text('4 - Ticket Scanner')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedUserType = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: ['Active', 'Suspended'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
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
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all fields')),
                      );
                      return;
                    }

                    final data = {
                      'id': isEditing ? user['id'] : 'U${widget.users.length + 1}',
                      'name': name,
                      'email': email,
                      'phone': phone,
                      'role': selectedUserType,
                      'status': selectedStatus,
                      'joinDate': isEditing ? user['joinDate'] : _formattedToday(),
                    };

                    if (isEditing) {
                      final originalIndex = widget.users.indexOf(user);
                      widget.onUserUpdated(originalIndex, data);
                    } else {
                      widget.onUserAdded(data);
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C43),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add User',
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

  void _showDeleteConfirmDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Account', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete the account of ${user['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = widget.users.indexOf(user);
              widget.onUserDeleted(originalIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleUserSuspend(Map<String, dynamic> user) {
    final idx = widget.users.indexOf(user);
    if (idx != -1) {
      final updatedUser = Map<String, dynamic>.from(user);
      final newStatus = user['status'] == 'Active' ? 'Suspended' : 'Active';
      updatedUser['status'] = newStatus;
      widget.onUserUpdated(idx, updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $newStatus')),
      );
    }
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

    final totalGuests = widget.users.length;
    final activeUsers = widget.users.where((u) => u['status'] == 'Active').length;
    final suspendedUsers = widget.users.where((u) => u['status'] == 'Suspended').length;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 220,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search user...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showUserFormDialog(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add User', style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C43),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _filteredUsers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No users found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            : isDesktop
                ? _buildUserTable()
                : _buildUserCardList(),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  Widget _buildUserTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9F6)),
          horizontalMargin: 12,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
          ],
          rows: _filteredUsers.map((u) {
            final isActive = u['status'] == 'Active';
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF0F4C43),
                      child: Icon(Icons.person, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                )),
                DataCell(Text(u['email'], style: const TextStyle(fontSize: 13))),
                DataCell(Text(u['phone'], style: const TextStyle(fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(u['role']).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getRoleName(u['role']),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getUserTypeColor(u['role']),
                    ),
                  ),
                )),
                DataCell(Text(u['joinDate'], style: const TextStyle(fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    u['status'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFF0F4C43) : const Color(0xFFE57373),
                    ),
                  ),
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_outlined, size: 18, color: Colors.blueAccent),
                      onPressed: () => _showUserHistoryDialog(u),
                      tooltip: 'View Booking & Activity Logs',
                    ),
                    IconButton(
                      icon: Icon(isActive ? Icons.lock_outline : Icons.lock_open, size: 18, color: Colors.orangeAccent),
                      onPressed: () => _toggleUserSuspend(u),
                      tooltip: isActive ? 'Suspend User' : 'Activate User',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => _showUserFormDialog(index: widget.users.indexOf(u), user: u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmDialog(u),
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

  Widget _buildUserCardList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _filteredUsers[index];
        final isActive = u['status'] == 'Active';
        final statusColor = isActive ? const Color(0xFF0F4C43) : const Color(0xFFE57373);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: statusColor, width: 4.5),
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: statusColor.withOpacity(0.12),
                        child: Icon(Icons.person, size: 16, color: statusColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2D27))),
                            const SizedBox(height: 2),
                            Text(
                              _getRoleName(u['role']),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getUserTypeColor(u['role'])),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u['status'] ?? 'Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildCardInfoRow(Icons.email_outlined, u['email']),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.phone_outlined, u['phone']),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.calendar_today_outlined, 'Joined: ${u['joinDate']}'),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.security_outlined, 'Verified Account'),
                  const Divider(height: 24, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.history_outlined, size: 18, color: Colors.blueAccent),
                        onPressed: () => _showUserHistoryDialog(u),
                        tooltip: 'View Booking Logs',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(isActive ? Icons.lock_outline : Icons.lock_open, size: 18, color: Colors.orangeAccent),
                        onPressed: () => _toggleUserSuspend(u),
                        tooltip: isActive ? 'Suspend User' : 'Activate User',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        onPressed: () => _showUserFormDialog(index: widget.users.indexOf(u), user: u),
                        tooltip: 'Edit Profile',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmDialog(u),
                        tooltip: 'Delete User',
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _getRoleName(String? type) {
    switch (type) {
      case '1': return 'Regular User';
      case '2': return 'System Admin';
      case '3': return 'Resort Owner';
      case '4': return 'Ticket Scanner';
      default: return 'Regular User';
    }
  }

  Color _getUserTypeColor(String? type) {
    switch (type) {
      case '1': return const Color(0xFF0F4C43);
      case '2': return const Color(0xFF5A93E5);
      case '3': return const Color(0xFFE5A93C);
      case '4': return const Color(0xFFE57373);
      default: return Colors.grey;
    }
  }
}
