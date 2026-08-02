import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// MODULE 3: RESORT OWNER MANAGEMENT
// ==========================================
class AdminOwnersView extends StatefulWidget {
  final List<Map<String, dynamic>> owners;
  final Function(String ownerId, String action, String value) onOwnerAction;

  const AdminOwnersView({
    super.key,
    required this.owners,
    required this.onOwnerAction,
  });

  @override
  State<AdminOwnersView> createState() => _AdminOwnersViewState();
}

class _AdminOwnersViewState extends State<AdminOwnersView> {
  String _filterStatus = 'All';
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
              Text(count, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27))),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    var list = widget.owners;
    if (_filterStatus != 'All') {
      list = list.where((o) => o['status'] == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((o) => o['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    final totalOwners = widget.owners.length;
    final verifiedOwners = widget.owners.where((o) => o['verified'] == true).length;
    final suspendedOwners = widget.owners.where((o) => o['status'] == 'Suspended').length;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resort Owner Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search owner name...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterStatus,
                  style: const TextStyle(color: Color(0xFF1E2D27), fontWeight: FontWeight.w600, fontSize: 13),
                  items: ['All', 'Active', 'Pending', 'Suspended'].map((status) {
                    return DropdownMenuItem(value: status, child: Text('$status Owners'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _filterStatus = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No owners registered on the platform.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            : isDesktop
                ? _buildOwnersTable(list)
                : _buildOwnersCardList(list),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  Widget _buildOwnersTable(List<Map<String, dynamic>> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9F6)),
          horizontalMargin: 12,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Join Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Resorts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2D27)))),
          ],
          rows: list.map((o) {
            final isVerified = o['verified'] ?? false;
            final isSuspended = o['status'] == 'Suspended';
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isVerified ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA),
                      child: Icon(
                        isVerified ? Icons.verified_user : Icons.gpp_maybe,
                        size: 12,
                        color: isVerified ? const Color(0xFF0F4C43) : const Color(0xFFE57373),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(o['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                )),
                DataCell(Text(o['emailOrPhone'] ?? '', style: const TextStyle(fontSize: 13))),
                DataCell(Text(o['joinDate'] ?? '', style: const TextStyle(fontSize: 13))),
                DataCell(Text('${o['resortsCount'] ?? 0} listed', style: const TextStyle(fontSize: 13))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVerified ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isVerified ? const Color(0xFF0F4C43) : const Color(0xFFE57373),
                    ),
                  ),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuspended ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    o['status'] ?? 'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSuspended ? Colors.red : Colors.teal,
                    ),
                  ),
                )),
                DataCell(Row(
                  children: [
                    if (!isVerified)
                      IconButton(
                        icon: const Icon(Icons.gpp_good_outlined, size: 18, color: Colors.teal),
                        onPressed: () => widget.onOwnerAction(o['id'].toString(), 'verify', 'true'),
                        tooltip: 'Verify Business Documents',
                      ),
                    IconButton(
                      icon: Icon(isSuspended ? Icons.lock_open : Icons.lock_outline, size: 18, color: Colors.orangeAccent),
                      onPressed: () {
                        if (isSuspended) {
                          widget.onOwnerAction(o['id'].toString(), 'activate', 'Active');
                        } else {
                          widget.onOwnerAction(o['id'].toString(), 'suspend', 'Suspended');
                        }
                      },
                      tooltip: isSuspended ? 'Activate Account' : 'Suspend Account',
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

  Widget _buildOwnersCardList(List<Map<String, dynamic>> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final o = list[idx];
        final isVerified = o['verified'] ?? false;
        final isSuspended = o['status'] == 'Suspended';
        final statusColor = isSuspended ? const Color(0xFFE57373) : const Color(0xFF0F4C43);

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
                        backgroundColor: isVerified ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA),
                        child: Icon(
                          isVerified ? Icons.verified_user : Icons.gpp_maybe,
                          size: 16,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2D27))),
                            const SizedBox(height: 2),
                            Text(
                              isVerified ? 'Verified Business' : 'Documents Pending',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isVerified ? Colors.teal : Colors.orangeAccent),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuspended ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o['status'] ?? 'Active',
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
                  
                  _buildCardInfoRow(Icons.phone_outlined, o['emailOrPhone'] ?? ''),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.villa_outlined, '${o['resortsCount'] ?? 0} resorts listed'),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.calendar_today_outlined, 'Registered: ${o['joinDate']}'),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.security_outlined, isVerified ? 'KYC Complete' : 'KYC Pending'),
                  
                  const Divider(height: 24, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isVerified)
                        ElevatedButton.icon(
                          onPressed: () => widget.onOwnerAction(o['id'].toString(), 'verify', 'true'),
                          icon: const Icon(Icons.gpp_good_outlined, size: 14, color: Colors.white),
                          label: const Text('Verify', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C43),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (isSuspended) {
                            widget.onOwnerAction(o['id'].toString(), 'activate', 'Active');
                          } else {
                            widget.onOwnerAction(o['id'].toString(), 'suspend', 'Suspended');
                          }
                        },
                        icon: Icon(isSuspended ? Icons.lock_open : Icons.lock_outline, size: 14),
                        label: Text(isSuspended ? 'Activate' : 'Suspend', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isSuspended ? Colors.teal : Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: isSuspended ? Colors.teal : Colors.redAccent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
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
}

// ==========================================
// MODULE 6: VERIFICATION CENTER
// ==========================================
class AdminVerificationView extends StatefulWidget {
  final List<Map<String, dynamic>> verifications;
  final Function(int id, String status) onStatusChange;

  const AdminVerificationView({
    super.key,
    required this.verifications,
    required this.onStatusChange,
  });

  @override
  State<AdminVerificationView> createState() => _AdminVerificationViewState();
}

class _AdminVerificationViewState extends State<AdminVerificationView> {
  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Document Verification Center',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review registered business identity documents, licenses, and deeds.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: widget.verifications.isEmpty
                    ? const Center(child: Text('No verifications requests registered yet.'))
                    : ListView.builder(
                        itemCount: widget.verifications.length,
                        itemBuilder: (context, idx) {
                          final v = widget.verifications[idx];
                          final status = v['status'] ?? 'Pending';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: const Color(0xFFF7F9F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Verification Case #${v['id']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Chip(
                                        label: Text(status),
                                        backgroundColor: status == 'Pending'
                                            ? const Color(0xFFFDF5E6)
                                            : (status == 'Approved' ? const Color(0xFFF0F4F2) : const Color(0xFFFDECEA)),
                                        labelStyle: TextStyle(
                                          color: status == 'Pending'
                                              ? const Color(0xFFE5A93C)
                                              : (status == 'Approved' ? const Color(0xFF0F4C43) : const Color(0xFFE57373)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Type: ${v['type']} Verification'),
                                  Text('Title: ${v['title']}'),
                                  Text('Submitted: ${v['submittedDate']}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Downloading document preview...')),
                                          );
                                        },
                                        icon: const Icon(Icons.file_open, size: 14),
                                        label: const Text('View Document', style: TextStyle(fontSize: 12)),
                                      ),
                                      const Spacer(),
                                      if (status == 'Pending') ...[
                                        TextButton(
                                          onPressed: () => widget.onStatusChange(v['id'], 'Rejected'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => widget.onStatusChange(v['id'], 'Approved'),
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                                          child: const Text('Approve Document', style: TextStyle(color: Colors.white)),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MODULE 7: PROMOTIONS & MARKETING
// ==========================================
class AdminPromotionsView extends StatefulWidget {
  final List<Map<String, dynamic>> coupons;
  final List<Map<String, dynamic>> banners;
  final Function(Map<String, dynamic> coupon) onCouponAdded;
  final Function(int id) onCouponDelete;
  final Function(Map<String, dynamic> banner) onBannerAdded;
  final Function(int id) onBannerDelete;

  const AdminPromotionsView({
    super.key,
    required this.coupons,
    required this.banners,
    required this.onCouponAdded,
    required this.onCouponDelete,
    required this.onBannerAdded,
    required this.onBannerDelete,
  });

  @override
  State<AdminPromotionsView> createState() => _AdminPromotionsViewState();
}

class _AdminPromotionsViewState extends State<AdminPromotionsView> {
  final _couponCodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _bannerTitleController = TextEditingController();
  final _bannerUrlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Coupons
          Card(
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
                  const Text('Coupon Code Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCodeController,
                          decoration: const InputDecoration(labelText: 'Coupon Code (e.g. MONSOON30)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          decoration: const InputDecoration(labelText: 'Discount Value (e.g. 30% or ₹150)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final code = _couponCodeController.text.trim();
                          final disc = _discountController.text.trim();
                          if (code.isNotEmpty && disc.isNotEmpty) {
                            widget.onCouponAdded({
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'code': code.toUpperCase(),
                              'discount': disc,
                              'type': code.contains('%') ? 'Percentage' : 'Flat',
                              'maxUsage': 100,
                              'used': 0,
                              'expiry': '2026-12-31',
                              'status': 'Active',
                            });
                            _couponCodeController.clear();
                            _discountController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                        child: const Text('Add Coupon', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  widget.coupons.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('No promo coupons created yet.', style: TextStyle(color: Colors.grey)),
                        )
                      : Table(
                          border: TableBorder(bottom: BorderSide(color: Colors.grey.shade200)),
                          children: [
                            const TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Redemptions', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ]
                            ),
                            ...widget.coupons.map((c) {
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(c['code'] ?? '')),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(c['discount'] ?? '')),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text('${c['used'] ?? 0}/${c['maxUsage'] ?? 100}')),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(c['status'] ?? '', style: TextStyle(color: c['status'] == 'Active' ? Colors.green : Colors.red)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () => widget.onCouponDelete(c['id']),
                                    ),
                                  )
                                ]
                              );
                            })
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section 2: Banners
          Card(
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
                  const Text('Promotion & Campaign Banners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bannerTitleController,
                          decoration: const InputDecoration(labelText: 'Banner Headline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _bannerUrlController,
                          decoration: const InputDecoration(labelText: 'Image URL'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final title = _bannerTitleController.text.trim();
                          final url = _bannerUrlController.text.trim();
                          if (title.isNotEmpty && url.isNotEmpty) {
                            widget.onBannerAdded({
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'title': title,
                              'imageUrl': url,
                              'link': '/promo/general',
                              'status': 'Active',
                            });
                            _bannerTitleController.clear();
                            _bannerUrlController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                        child: const Text('Add Banner', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  widget.banners.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('No promotional campaign banners uploaded.', style: TextStyle(color: Colors.grey)),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: widget.banners.length,
                          itemBuilder: (context, idx) {
                            final b = widget.banners[idx];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      b['imageUrl'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.35),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(b['status'] ?? 'Active', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                              onPressed: () => widget.onBannerDelete(b['id']),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// MODULE 8: FINANCIAL MANAGEMENT
// ==========================================
class AdminFinancialsView extends StatefulWidget {
  final double initialCommission;
  final ValueChanged<double> onCommissionSave;
  final List<Map<String, dynamic>> refunds;
  final Function(int refundId, bool approve) onRefundResult;

  const AdminFinancialsView({
    super.key,
    required this.initialCommission,
    required this.onCommissionSave,
    required this.refunds,
    required this.onRefundResult,
  });

  @override
  State<AdminFinancialsView> createState() => _AdminFinancialsViewState();
}

class _AdminFinancialsViewState extends State<AdminFinancialsView> {
  late TextEditingController _commController;

  @override
  void initState() {
    super.initState();
    _commController = TextEditingController(text: widget.initialCommission.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
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
                  const Text('Platform Commission Setting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _commController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: '%',
                            labelText: 'Commission Rate',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final val = double.tryParse(_commController.text) ?? 10.0;
                          widget.onCommissionSave(val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Commission rate updated to $val%')),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                        child: const Text('Update Settings', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
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
                  const Text('Refund Requests Approval Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  widget.refunds.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('No active refund requests registered from cancellations.', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.refunds.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final r = widget.refunds[idx];
                            final idVal = int.tryParse(r['id'].toString()) ?? 0;
                            return ListTile(
                              title: Text('Booking #${r['id']} - ${r['guestName']}'),
                              subtitle: Text('Amount: ₹${r['amount']} • Date: ${r['date']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => widget.onRefundResult(idVal, false),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Deny'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => widget.onRefundResult(idVal, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                                    child: const Text('Approve Refund', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// MODULE 9: CONTENT MANAGEMENT
// ==========================================
class AdminContentView extends StatefulWidget {
  final List<Map<String, dynamic>> faqs;
  final Function(String q, String a) onAddFaq;
  final String terms;
  final String privacy;
  final Function(String terms, String privacy) onSavePolicies;

  const AdminContentView({
    super.key,
    required this.faqs,
    required this.onAddFaq,
    required this.terms,
    required this.privacy,
    required this.onSavePolicies,
  });

  @override
  State<AdminContentView> createState() => _AdminContentViewState();
}

class _AdminContentViewState extends State<AdminContentView> {
  late TextEditingController _termsController;
  late TextEditingController _privacyController;

  @override
  void initState() {
    super.initState();
    _termsController = TextEditingController(text: widget.terms);
    _privacyController = TextEditingController(text: widget.privacy);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
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
                  const Text('Terms & Conditions Editor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _termsController,
                    maxLines: 4,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Privacy Policy Editor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _privacyController,
                    maxLines: 3,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSavePolicies(_termsController.text, _privacyController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Policies saved and synchronized successfully.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                    child: const Text('Save Legal Documents', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
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
                  const Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  widget.faqs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('No FAQs created yet.', style: TextStyle(color: Colors.grey)),
                        )
                      : Column(
                          children: widget.faqs.map((f) => ExpansionTile(
                            title: Text(f['q'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(f['a'] ?? ''),
                              )
                            ],
                          )).toList(),
                        ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final qC = TextEditingController();
                      final aC = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add FAQ Entry'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(controller: qC, decoration: const InputDecoration(labelText: 'Question')),
                              TextField(controller: aC, decoration: const InputDecoration(labelText: 'Answer')),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                if (qC.text.isNotEmpty && aC.text.isNotEmpty) {
                                  widget.onAddFaq(qC.text, aC.text);
                                }
                                Navigator.pop(context);
                              },
                              child: const Text('Add'),
                            )
                          ],
                        ),
                      );
                    },
                    child: const Text('Create FAQ Entry'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// MODULE 10: REPORTS & ANALYTICS
// ==========================================
class AdminReportsView extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;

  const AdminReportsView({
    super.key,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dynamic chart data based on active bookings counts
    double pendingVal = bookings.where((b) => b['status'] == 'Pending').length.toDouble();
    double confirmedVal = bookings.where((b) => b['status'] == 'Confirmed').length.toDouble();
    double completedVal = bookings.where((b) => b['status'] == 'Completed').length.toDouble();
    double cancelledVal = bookings.where((b) => b['status'] == 'Cancelled').length.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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
                  const Text('Dynamic Booking Status Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: pendingVal == 0 ? 1 : pendingVal, color: Colors.orangeAccent)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: confirmedVal == 0 ? 1 : confirmedVal, color: const Color(0xFF0F4C43))]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: completedVal == 0 ? 1 : completedVal, color: Colors.blueAccent)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: cancelledVal == 0 ? 1 : cancelledVal, color: Colors.redAccent)]),
                        ],
                        titlesData: const FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _getTitles,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
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
                  const Text('Export Financial & Booking Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Download structural datasets for auditing and accounting.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Excel spreadsheet...')));
                        },
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export Excel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV document exported.')));
                        },
                        icon: const Icon(Icons.text_snippet),
                        label: const Text('Export CSV'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  static Widget _getTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('Pending', style: style);
        break;
      case 2:
        text = const Text('Confirmed', style: style);
        break;
      case 3:
        text = const Text('Completed', style: style);
        break;
      case 4:
        text = const Text('Cancelled', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
  }
}

// ==========================================
// MODULE 11: SUPPORT MANAGEMENT
// ==========================================
class AdminSupportView extends StatefulWidget {
  final List<Map<String, dynamic>> tickets;
  final Function(int ticketId, String reply) onSendReply;

  const AdminSupportView({
    super.key,
    required this.tickets,
    required this.onSendReply,
  });

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  final _replyController = TextEditingController();
  Map<String, dynamic>? _selectedTicket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Support Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: widget.tickets.isEmpty
                          ? const Center(child: Text('No support tickets registered.'))
                          : ListView.builder(
                              itemCount: widget.tickets.length,
                              itemBuilder: (context, idx) {
                                final t = widget.tickets[idx];
                                final isSelected = _selectedTicket?['id'] == t['id'];
                                return ListTile(
                                  selected: isSelected,
                                  onTap: () => setState(() => _selectedTicket = t),
                                  title: Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('From: ${t['senderName']} • Status: ${t['status']}'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _selectedTicket == null
                    ? const Center(child: Text('Select a ticket from the list to view conversations.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject: ${_selectedTicket!['subject']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Divider(),
                          Expanded(
                            child: ListView(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F3F0), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${_selectedTicket!['senderName']}:\n${_selectedTicket!['message']}'),
                                  ),
                                ),
                                ...((_selectedTicket!['replies'] as List? ?? []).map((rep) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(color: const Color(0xFFF0F4F2), borderRadius: BorderRadius.circular(8)),
                                      child: Text('Admin:\n${rep['text']}'),
                                    ),
                                  );
                                })),
                              ],
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  decoration: const InputDecoration(hintText: 'Type resolution message here...'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF0F4C43)),
                                onPressed: () {
                                  final text = _replyController.text.trim();
                                  final ticketIdVal = int.tryParse(_selectedTicket!['id'].toString()) ?? 0;
                                  if (text.isNotEmpty) {
                                    widget.onSendReply(ticketIdVal, text);
                                    setState(() {
                                      _selectedTicket!['replies'].add({'sender': 'Admin', 'text': text, 'date': 'Just Now'});
                                    });
                                    _replyController.clear();
                                  }
                                },
                              )
                            ],
                          )
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// MODULE 12: NOTIFICATION CENTER
// ==========================================
class AdminNotificationsView extends StatefulWidget {
  final List<Map<String, dynamic>> outbox;
  final Function(String title, String body, String audience) onSendNotification;

  const AdminNotificationsView({
    super.key,
    required this.outbox,
    required this.onSendNotification,
  });

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();
  String _targetAudience = 'All';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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
                  const Text('Broadcast System Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _targetAudience,
                    decoration: const InputDecoration(labelText: 'Target Audience'),
                    items: ['All', 'Guests', 'Owners'].map((aud) {
                      return DropdownMenuItem(value: aud, child: Text(aud));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _targetAudience = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Notification Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message Body'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final t = _titleController.text.trim();
                      final b = _msgController.text.trim();
                      if (t.isNotEmpty && b.isNotEmpty) {
                        widget.onSendNotification(t, b, _targetAudience);
                        _titleController.clear();
                        _msgController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications pushed successfully.')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                    child: const Text('Send Broadcast', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Outbox Notification Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: widget.outbox.isEmpty
                ? const Center(child: Text('No logs in outbox yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: widget.outbox.length,
                    itemBuilder: (context, idx) {
                      final item = widget.outbox[idx];
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(item['title'] ?? ''),
                          subtitle: Text('Audience: ${item['audience'] ?? "All"} • Pushed: ${item['date'] ?? ""}'),
                          trailing: const Icon(Icons.send_rounded, color: Colors.green, size: 18),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// MODULE 13: SECURITY & AUDIT LOGS
// ==========================================
class AdminSecurityView extends StatefulWidget {
  final List<Map<String, dynamic>> auditLogs;

  const AdminSecurityView({
    super.key,
    required this.auditLogs,
  });

  @override
  State<AdminSecurityView> createState() => _AdminSecurityViewState();
}

class _AdminSecurityViewState extends State<AdminSecurityView> {
  final Map<String, Map<String, bool>> rolePermissions = {
    'Admin': {'Manage Resorts': true, 'View Analytics': true, 'Configure System': true},
    'Owner': {'Manage Resorts': true, 'View Analytics': true, 'Configure System': false},
    'Scanner': {'Manage Resorts': false, 'View Analytics': false, 'Configure System': false},
  };

  Widget _buildPermissionToggle(String role, String permission) {
    final value = rolePermissions[role]![permission] ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(permission, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        Switch(
          value: value,
          activeColor: const Color(0xFF0F4C43),
          onChanged: (val) {
            setState(() {
              rolePermissions[role]![permission] = val;
            });
          },
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security & Control Matrix',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27)),
          ),
          const SizedBox(height: 16),

          // Role Clearance Matrices
          isDesktop
              ? Row(
                  children: rolePermissions.keys.map((role) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$role Permissions',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2D27)),
                            ),
                            const Divider(height: 24),
                            _buildPermissionToggle(role, 'Manage Resorts'),
                            _buildPermissionToggle(role, 'View Analytics'),
                            _buildPermissionToggle(role, 'Configure System'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: rolePermissions.keys.map((role) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$role Permissions',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2D27)),
                          ),
                          const Divider(height: 24),
                          _buildPermissionToggle(role, 'Manage Resorts'),
                          _buildPermissionToggle(role, 'View Analytics'),
                          _buildPermissionToggle(role, 'Configure System'),
                        ],
                      ),
                    );
                  }).toList(),
                ),


        ],
      ),
    );
  }
}

// ==========================================
// MODULE 14: SYSTEM SETTINGS
// ==========================================
class AdminSettingsView extends StatefulWidget {
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic> settings) onSaveSettings;

  const AdminSettingsView({
    super.key,
    required this.initialSettings,
    required this.onSaveSettings,
  });

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  late double _taxRate;
  late bool _maintenanceMode;
  late bool _instantBooking;
  late bool _smsLogin;
  late double _refundWindow;

  @override
  void initState() {
    super.initState();
    _taxRate = (widget.initialSettings['taxRate'] as num?)?.toDouble() ?? 5.0;
    _maintenanceMode = widget.initialSettings['maintenanceMode'] ?? false;
    _instantBooking = widget.initialSettings['instantBooking'] ?? true;
    _smsLogin = widget.initialSettings['smsOtpLogin'] ?? true;
    _refundWindow = (widget.initialSettings['refundWindowHours'] as num?)?.toDouble() ?? 48.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              const Text('System Settings & Platform Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27))),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Enable to lock system access and show maintenance screen to customers.'),
                value: _maintenanceMode,
                onChanged: (val) => setState(() => _maintenanceMode = val),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Instant Bookings', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Allows guests to secure bookings instantly without owner manual approval.'),
                value: _instantBooking,
                onChanged: (val) => setState(() => _instantBooking = val),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('SMS OTP Login API', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Require OTP authentication verification during registration and logging.'),
                value: _smsLogin,
                onChanged: (val) => setState(() => _smsLogin = val),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tax Configuration Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Slider(
                      value: _taxRate,
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '${_taxRate.toInt()}%',
                      onChanged: (val) => setState(() => _taxRate = val),
                    ),
                    Text('Current Tax Charge: ${_taxRate.toInt()}%', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Refund Cancellation Window (Hours)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Slider(
                      value: _refundWindow,
                      min: 12,
                      max: 72,
                      divisions: 5,
                      label: '${_refundWindow.toInt()} hrs',
                      onChanged: (val) => setState(() => _refundWindow = val),
                    ),
                    Text('Window: ${_refundWindow.toInt()} hours before booking date.', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  widget.onSaveSettings({
                    'taxRate': _taxRate,
                    'maintenanceMode': _maintenanceMode,
                    'instantBooking': _instantBooking,
                    'smsOtpLogin': _smsLogin,
                    'refundWindowHours': _refundWindow,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuration saved successfully.')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C43)),
                child: const Text('Save System Configurations', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MODULE 15: ADMIN PROFILE VIEW
// ==========================================
class AdminProfileView extends StatefulWidget {
  final String adminName;
  final String adminRole;

  const AdminProfileView({
    super.key,
    required this.adminName,
    required this.adminRole,
  });

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.adminName;
    _emailController.text = 'admin@resortplatform.com';
  }

  Widget _buildSessionMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E2D27))),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final permissions = widget.adminRole == '2'
        ? ['Full Access', 'Resort Management', 'User Control', 'Financial Audits', 'CMS Configuration', 'Security Audits']
        : ['View-Only Access', 'Audit Logs Access', 'CMS Read Access'];

    final recentActivities = [
      {'time': '10 mins ago', 'action': 'Logged in from Firefox (Windows 11)'},
      {'time': '2 hours ago', 'action': 'Updated platform commission payout rate'},
      {'time': 'Yesterday', 'action': 'Approved Resort Registration - Ocean Blue Haven'},
      {'time': '3 days ago', 'action': 'Suspended user account - john_doe@gmail.com'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFF0F4F2),
                        child: Text(
                          widget.adminName.isNotEmpty ? widget.adminName.substring(0, 1).toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F4C43)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.adminName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E2D27))),
                          Text(widget.adminRole == '2' ? 'Super Administrator' : 'Platform Auditor', style: const TextStyle(color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 40),
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(child: _buildSessionMetric('Account Status', 'Active & Safe', Icons.security, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSessionMetric('Active Session', '2h 14m', Icons.timer_outlined, Colors.blueAccent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSessionMetric('Privilege Tier', widget.adminRole == '2' ? 'Root Admin' : 'Auditor', Icons.military_tech_outlined, Colors.orangeAccent)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildSessionMetric('Account Status', 'Active & Safe', Icons.security, Colors.green),
                        const SizedBox(height: 10),
                        _buildSessionMetric('Active Session', '2h 14m', Icons.timer_outlined, Colors.blueAccent),
                        const SizedBox(height: 10),
                        _buildSessionMetric('Privilege Tier', widget.adminRole == '2' ? 'Root Admin' : 'Auditor', Icons.military_tech_outlined, Colors.orangeAccent),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Text('Personal Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Update Security Password', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin Profile updated successfully')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C43),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Role Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27))),
                  const SizedBox(height: 6),
                  const Text('Assigned system permissions based on role security clearance.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: permissions.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0F4C43).withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF0F4C43), size: 14),
                            const SizedBox(width: 6),
                            Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E2D27))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
