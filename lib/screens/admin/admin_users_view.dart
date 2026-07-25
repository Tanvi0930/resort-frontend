import 'package:flutter/material.dart';

class AdminUsersView extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final ValueChanged<Map<String, dynamic>> onUserAdded;
  final Function(int, Map<String, dynamic>) onUserUpdated;
  final ValueChanged<int> onUserDeleted;

  const AdminUsersView({
    super.key,
    required this.users,
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
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
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
                            initialValue: selectedUserType,
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
                            initialValue: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: ['Active', 'Inactive'].map((s) {
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

                    if (phone.length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number must be exactly 10 digits')),
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
                      // Find actual index in parent list
                      final originalIndex = widget.users.indexOf(user);
                      widget.onUserUpdated(originalIndex, data);
                    } else {
                      widget.onUserAdded(data);
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7C59),
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
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View Header with Search and Add buttons
              Row(
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                  const Spacer(),
                  // Search Box
                  Container(
                    width: 220,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F2),
                      borderRadius: BorderRadius.circular(8),
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
                  // Add User Button
                  ElevatedButton.icon(
                    onPressed: () => _showUserFormDialog(),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Add User', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E7C59),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // Grid/List representation based on screen size
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No users found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : isDesktop
                        ? _buildUserTable()
                        : _buildUserCardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DESKTOP DATA TABLE ---
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
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('User Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Join Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
          ],
          rows: _filteredUsers.map((u) {
            final isActive = u['status'] == 'Active';
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF3E7C59),
                      child: Icon(Icons.person, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                )),
                DataCell(Text(u['email'], style: const TextStyle(fontSize: 13))),
                DataCell(Text(u['phone'], style: const TextStyle(fontSize: 13))),
                DataCell(Text(u['role'] ?? '1', style: const TextStyle(fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(u['role']).withValues(alpha: 0.12),
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
                    color: isActive ? const Color(0xFFE8F3EB) : const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    u['status'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFF3E7C59) : const Color(0xFFE57373),
                    ),
                  ),
                )),
                DataCell(Row(
                  children: [
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

  // --- MOBILE CARD LIST ---
  Widget _buildUserCardList() {
    return ListView.separated(
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _filteredUsers[index];
        final isActive = u['status'] == 'Active';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF3E7C59),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFE8F3EB) : const Color(0xFFFDECEA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u['status'],
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF3E7C59) : const Color(0xFFE57373)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildCardDetailRow('Email', u['email']),
              const SizedBox(height: 4),
              _buildCardDetailRow('Phone', u['phone']),
              const SizedBox(height: 4),
              _buildCardDetailRow('User Type', u['role'] ?? '1'),
              const SizedBox(height: 4),
              _buildCardDetailRow('Role', _getRoleName(u['role'])),
              const SizedBox(height: 4),
              _buildCardDetailRow('Joined', u['joinDate']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showUserFormDialog(index: widget.users.indexOf(u), user: u),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmDialog(u),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardDetailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B))),
      ],
    );
  }

  String _getRoleName(String? type) {
    switch (type) {
      case '1':
        return 'Regular User';
      case '2':
        return 'System Admin';
      case '3':
        return 'Resort Owner';
      case '4':
        return 'Ticket Scanner';
      default:
        return 'Regular User';
    }
  }

  Color _getUserTypeColor(String? type) {
    switch (type) {
      case '1':
        return const Color(0xFF3E7C59); // Green
      case '2':
        return const Color(0xFF5A93E5); // Blue
      case '3':
        return const Color(0xFFE5A93C); // Orange
      case '4':
        return const Color(0xFFE57373); // Red
      default:
        return Colors.grey;
    }
  }
}
