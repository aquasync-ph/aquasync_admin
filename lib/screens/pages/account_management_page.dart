import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

class AccountManagementPage extends StatefulWidget {
  final List<CustomerModel> customers;
  final List<DriverModel> drivers;
  final VoidCallback onAddCustomer;
  final VoidCallback onAddDriver;
  final VoidCallback onAddCashier;
  final Function(Map<String, dynamic>) onViewGenericAccount;
  final Function(Map<String, dynamic>) onEditGenericAccount;
  final VoidCallback onRefresh;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;

  const AccountManagementPage({
    super.key,
    required this.customers,
    required this.drivers,
    required this.onAddCustomer,
    required this.onAddDriver,
    required this.onAddCashier,
    required this.onViewGenericAccount,
    required this.onEditGenericAccount,
    required this.onRefresh,
    this.highlightQuery,
    this.onClearHighlight,
  });

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late bool _isGridView;
  String _statusFilter = 'active'; // 'active', 'pending', 'archived'
  String _selectedCategory = 'all'; // 'all', 'customer', 'driver', 'cashier'
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  late TextEditingController _searchController;
  bool _isPolicyBannerDismissed = false;
  bool _isSearchExpanded = false;

  List<Map<String, dynamic>> _allProfiles = [];
  bool _isLoadingProfiles = true;
  Timer? _countdownTicker;
  bool _isPurgingExpired = false;

  @override
  void initState() {
    super.initState();
    _isGridView = widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty;
    _isSearchExpanded = widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty;
    _searchController = TextEditingController();
    _loadProfiles();
    _startCountdownTicker();
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Rebuilds UI for real-time live countdown timer ticking
        _checkAndAutoPurgeExpiredProfiles();
      }
    });
  }

  @override
  void didUpdateWidget(AccountManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfiles();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isAccountHighlighted(Map<String, dynamic> profile) {
    if (widget.highlightQuery == null || widget.highlightQuery!.trim().isEmpty) {
      return false;
    }
    final q = widget.highlightQuery!.toLowerCase().trim();
    final name = (profile['full_name'] ?? '').toString().toLowerCase();
    final id = (profile['id'] ?? '').toString().toLowerCase();
    final email = (profile['email'] ?? '').toString().toLowerCase();
    return name.contains(q) || id.contains(q) || email.contains(q);
  }

  int _totalAccounts = 0;
  int _pendingAccounts = 0;
  int _totalCustomers = 0;
  int _totalDrivers = 0;

  void _recomputeSummaryCounts() {
    int totalAcc = 0;
    int pendingAcc = 0;
    int totalCust = 0;
    int totalDrv = 0;

    for (var p in _allProfiles) {
      final isArchived = p['is_archived'] == true;
      final role = (p['role'] ?? '').toString().toLowerCase().trim();
      final isPending = !isArchived && _isProfilePending(p);

      if (!isArchived && !isPending) totalAcc++;
      if (!isArchived && isPending) pendingAcc++;
      if (!isArchived && role == 'customer') totalCust++;
      if (!isArchived && role == 'driver') totalDrv++;
    }

    _totalAccounts = totalAcc;
    _pendingAccounts = pendingAcc;
    _totalCustomers = totalCust;
    _totalDrivers = totalDrv;
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final res = await SupabaseService.fetchManageableProfiles();
      if (mounted) {
        _allProfiles = res;
        _recomputeSummaryCounts();
        setState(() {
          _isLoadingProfiles = false;
        });
        _checkAndAutoPurgeExpiredProfiles();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Future<void> _checkAndAutoPurgeExpiredProfiles() async {
    if (_isPurgingExpired || _isLoadingProfiles) return;

    final now = DateTime.now();
    final expiredIds = <String>[];
    final expiredNames = <String>[];

    for (var p in _allProfiles) {
      final isArchived = p['is_archived'] == true;
      if (isArchived) continue;

      final status = (p['status'] ?? '').toString().toLowerCase().trim();
      final isVerified = p['is_verified'] == true;
      final isPending = p['is_pending'] == true;

      // Extra safety check: NEVER purge active or verified accounts
      if (status == 'active' || (isVerified && !isPending)) {
        continue;
      }

      if (_isProfilePending(p)) {
        final createdAtRaw = (p['created_at'] ?? '').toString();
        final parsedCreated = DateTime.tryParse(createdAtRaw);
        if (parsedCreated != null) {
          final expiryDate = parsedCreated.add(const Duration(days: 7));
          if (now.isAfter(expiryDate)) {
            final id = p['id']?.toString() ?? '';
            final name = p['full_name']?.toString() ?? 'User';
            if (id.isNotEmpty && !expiredIds.contains(id)) {
              expiredIds.add(id);
              expiredNames.add(name);
            }
          }
        }
      }
    }

    if (expiredIds.isEmpty) return;

    _isPurgingExpired = true;
    int purgedCount = 0;
    for (int i = 0; i < expiredIds.length; i++) {
      final id = expiredIds[i];
      final name = expiredNames[i];
      try {
        await SupabaseService.deleteProfile(id);
        purgedCount++;
        debugPrint('Auto-deleted expired pending unverified profile: $name ($id)');
      } catch (e) {
        debugPrint('Failed to auto-delete expired profile $id: $e');
      }
    }

    _isPurgingExpired = false;
    if (purgedCount > 0 && mounted) {
      SweetAlert.showGlobalSuccess('Auto-purged $purgedCount unverified account(s) past the 7-day registration limit.');
      await _loadProfiles();
      widget.onRefresh();
    }
  }

  Widget _buildTimerBadge(dynamic createdAtRaw) {
    final parsedCreated = DateTime.tryParse(createdAtRaw?.toString() ?? '');
    if (parsedCreated == null) return const SizedBox.shrink();

    final expiryDate = parsedCreated.add(const Duration(days: 7));
    final now = DateTime.now();
    final remaining = expiryDate.difference(now);

    if (remaining.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF87171)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_rounded, size: 12, color: Color(0xFF991B1B)),
            SizedBox(width: 4),
            Text(
              'EXPIRED (Auto-deleting...)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
            ),
          ],
        ),
      );
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final isCritical = days == 0 && hours < 24;
    final bgColor = isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    final borderColor = isCritical ? const Color(0xFFF87171) : const Color(0xFFFCD34D);
    final textColor = isCritical ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    String timeStr;
    if (days > 0) {
      timeStr = '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (hours > 0) {
      timeStr = '${hours}h ${minutes}m ${seconds}s';
    } else {
      timeStr = '${minutes}m ${seconds}s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            '⏳ $timeStr remaining',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  bool _isProfilePending(Map<String, dynamic> profile) {
    final status = (profile['status'] ?? '').toString().toLowerCase().trim();
    final isPendingFlag = profile['is_pending'] == true;
    final isVerifiedFlag = profile['is_verified'] == false;

    // If account is explicitly active OR verified & not pending, it is NOT pending!
    if (status == 'active' || (isVerifiedFlag == false && isPendingFlag == false && status != 'pending' && status != 'unverified')) {
      return false;
    }

    final emailConfirmed = profile['email_confirmed_at'];
    if (emailConfirmed == false) return true;

    return status == 'pending' || status == 'unverified' || isPendingFlag || isVerifiedFlag;
  }

  List<Map<String, dynamic>> get _filteredProfiles {
    final list = _allProfiles.where((profile) {
      final isArchived = profile['is_archived'] == true;
      final isPending = !isArchived && _isProfilePending(profile);

      if (_statusFilter == 'archived') {
        if (!isArchived) return false;
      } else if (_statusFilter == 'pending') {
        if (isArchived || !isPending) return false;
      } else {
        // 'active'
        if (isArchived || isPending) return false;
      }

      final role = (profile['role'] ?? '').toString().toLowerCase().trim();
      if (_selectedCategory != 'all' && role != _selectedCategory) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final name = (profile['full_name'] ?? '').toString().toLowerCase();
        final phone = (profile['phone'] ?? '').toString().toLowerCase();
        final address = (profile['address'] ?? '').toString().toLowerCase();
        final id = (profile['id'] ?? '').toString().toLowerCase();
        return name.contains(q) || phone.contains(q) || address.contains(q) || id.contains(q);
      }

      return true;
    }).toList();

    if (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty) {
      list.sort((a, b) {
        final aH = _isAccountHighlighted(a);
        final bH = _isAccountHighlighted(b);
        if (aH && !bH) return -1;
        if (!aH && bH) return 1;
        return 0;
      });
    }

    return list;
  }

  void _confirmVerifyAccount(Map<String, dynamic> profile) {
    final name = profile['full_name']?.toString() ?? 'User';
    final id = profile['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        title: const Text('Verify / Approve Account?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text('Approve "$name" and set status to Active?', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.approveUserAccount(id);
                await _loadProfiles();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"$name" is now verified and active!');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to verify: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Approve Account'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(Map<String, dynamic> profile) {
    final name = profile['full_name']?.toString() ?? 'User';
    final id = profile['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        title: const Text('Archive Account Profile?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text('Are you sure you want to archive "$name"? The account will be moved to archived records.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProfileArchiveStatus(userId: id, isArchived: true);
                await _loadProfiles();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"$name" moved to archived accounts.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to archive: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Archive Account'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(Map<String, dynamic> profile) {
    final name = profile['full_name']?.toString() ?? 'User';
    final id = profile['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        title: const Text('Restore Archived Account?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text('Restore "$name" back to active accounts?', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProfileArchiveStatus(userId: id, isArchived: false);
                await _loadProfiles();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"$name" restored to active accounts.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to restore: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Restore Account'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(Map<String, dynamic> profile) {
    final name = profile['full_name']?.toString() ?? 'User';
    final id = profile['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        title: const Text('Permanently Delete Account?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text('Are you sure you want to PERMANENTLY delete "$name"? This action CANNOT be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteProfile(id);
                await _loadProfiles();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"$name" permanently deleted.');
              } catch (e) {
                final cleanMsg = e.toString().replaceAll('Exception: ', '');
                SweetAlert.showGlobalError(cleanMsg);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBanner() {
    if (widget.highlightQuery == null || widget.highlightQuery!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x200284C7), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0284C7), size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TARGETED ITEM HIGHLIGHTED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Viewing targeted item: "${widget.highlightQuery}"',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onClearHighlight,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 14, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppSummaryCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: const Color(0xFF0284C7),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {
          _searchQuery = val;
          _currentPage = 1;
        }),
        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search account by name, phone, address, or UUID...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
          prefixIcon: Container(
            margin: const EdgeInsets.all(7),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0284C7)),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF475569), size: 14),
                  ),
                  tooltip: 'Clear search',
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _currentPage = 1;
                    });
                    if (widget.onClearHighlight != null) widget.onClearHighlight!();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F9FF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.25), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.25), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    final totalAccountsCount = _totalAccounts;
    final customersCount = _totalCustomers;
    final driversCount = _totalDrivers;
    final cashiersCount = _allProfiles
        .where((p) => p['is_archived'] != true && (p['role'] ?? '').toString().toLowerCase().trim() == 'cashier')
        .length;

    final categories = [
      {'key': 'all', 'label': 'All Accounts', 'icon': Icons.groups_rounded, 'count': totalAccountsCount},
      {'key': 'customer', 'label': 'Customers', 'icon': Icons.people_outline_rounded, 'count': customersCount},
      {'key': 'driver', 'label': 'Drivers', 'icon': Icons.badge_outlined, 'count': driversCount},
      {'key': 'cashier', 'label': 'Cashiers', 'icon': Icons.point_of_sale_rounded, 'count': cashiersCount},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat['key'];
        final count = cat['count'] as int;

        return InkWell(
          onTap: () => setState(() {
            _selectedCategory = cat['key'] as String;
            _currentPage = 1;
          }),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0x400284C7),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentPill(String key, String label) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() {
        _statusFilter = key;
        _currentPage = 1;
        _isPolicyBannerDismissed = false;
      }),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0x330284C7), blurRadius: 8, offset: Offset(0, 2)),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> profile) {
    final id = profile['id']?.toString() ?? '';
    final name = profile['full_name']?.toString() ?? profile['name']?.toString() ?? 'User';
    final email = profile['email']?.toString() ?? '—';
    final phone = profile['phone']?.toString() ?? '—';
    final address = profile['address']?.toString() ?? profile['delivery_address']?.toString() ?? '—';
    final avatarUrl = profile['avatar_url']?.toString() ?? profile['image_url']?.toString() ?? profile['photo_url']?.toString();
    final role = (profile['role'] ?? 'customer').toString().toLowerCase();
    final isArchived = profile['is_archived'] == true;
    final isPending = !isArchived && _isProfilePending(profile);
    final createdAt = (profile['created_at'] ?? '').toString().split('T').first;

    Color roleBg;
    Color roleFg;
    String roleLabel;
    if (role == 'driver') {
      roleBg = const Color(0xFFE0F2FE);
      roleFg = const Color(0xFF0369A1);
      roleLabel = 'DRIVER';
    } else if (role == 'cashier') {
      roleBg = const Color(0xFFF3E8FF);
      roleFg = const Color(0xFF9333EA);
      roleLabel = 'CASHIER';
    } else {
      roleBg = const Color(0xFFDCFCE7);
      roleFg = const Color(0xFF166534);
      roleLabel = 'CUSTOMER';
    }

    Color statusBg;
    Color statusFg;
    String statusLabel;
    if (isArchived) {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFF991B1B);
      statusLabel = 'ARCHIVED';
    } else if (isPending) {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFF92400E);
      statusLabel = 'PENDING OTP';
    } else {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF166534);
      statusLabel = 'ACTIVE';
    }

    final isHighlighted = _isAccountHighlighted(profile);

    return AppGlassCard(
      isHighlighted: isHighlighted,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleBg,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: roleFg),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (email.isNotEmpty && email != '—')
                      Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(999)),
                child: Text(roleLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleFg)),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 16),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(child: Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text('Reg: $createdAt', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              const Spacer(),
              Text('UUID: ${id.length >= 8 ? id.substring(0, 8) : id}', style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 6),
            _buildTimerBadge(profile['created_at']),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _statusFilter == 'archived'
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmRestore(profile),
                          icon: const Icon(Icons.unarchive_outlined, size: 14),
                          label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmDeletePermanently(profile),
                          icon: const Icon(Icons.delete_forever_rounded, size: 14),
                          label: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => widget.onViewGenericAccount(profile),
                          icon: const Icon(Icons.visibility_rounded, size: 14),
                          label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () => widget.onEditGenericAccount(profile),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () => _confirmVerifyAccount(profile),
                            icon: const Icon(Icons.verified_user_rounded, size: 14),
                            label: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () => _confirmArchive(profile),
                          icon: const Icon(Icons.archive_outlined, size: 14),
                          label: const Text('Archive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProfiles;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <Map<String, dynamic>>[]
        : filtered.sublist(
            startIndex.clamp(0, filtered.length),
            (startIndex + _itemsPerPage).clamp(0, filtered.length),
          );
    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _statusFilter = 'active';
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSummaryCard(label: 'Active Accounts', value: '$_totalAccounts', icon: Icons.manage_accounts_rounded, color: const Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _statusFilter = 'pending';
                    _isPolicyBannerDismissed = false;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSummaryCard(label: 'Pending Verification', value: '$_pendingAccounts', icon: Icons.mark_email_unread_rounded, color: const Color(0xFFF59E0B)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Customers', value: '$_totalCustomers', icon: Icons.people_outline_rounded, color: const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Drivers', value: '$_totalDrivers', icon: Icons.badge_outlined, color: const Color(0xFF0284C7))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: InkWell(
                  onTap: () => setState(() {
                    _statusFilter = 'active';
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSummaryCard(label: 'Active', value: '$_totalAccounts', icon: Icons.manage_accounts_rounded, color: const Color(0xFF0284C7)),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: InkWell(
                  onTap: () => setState(() {
                    _statusFilter = 'pending';
                    _isPolicyBannerDismissed = false;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSummaryCard(label: 'Pending', value: '$_pendingAccounts', icon: Icons.mark_email_unread_rounded, color: const Color(0xFFF59E0B)),
                ),
              ),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Customers', value: '$_totalCustomers', icon: Icons.people_outline_rounded, color: const Color(0xFF10B981))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Drivers', value: '$_totalDrivers', icon: Icons.badge_outlined, color: const Color(0xFF0284C7))),
            ],
          );
        }
      },
    );

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightBanner(),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final controls = Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F3FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5A5E63).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _isGridView = true),
                          icon: const Icon(Icons.grid_view_rounded, size: 20),
                          color: _isGridView ? const Color(0xFF0098DA) : const Color(0xFF5A5E63),
                          tooltip: 'Grid View',
                        ),
                        IconButton(
                          onPressed: () => setState(() => _isGridView = false),
                          icon: const Icon(Icons.table_rows_rounded, size: 20),
                          color: !_isGridView ? const Color(0xFF0098DA) : const Color(0xFF5A5E63),
                          tooltip: 'List / Table View',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentPill('active', 'Active'),
                        _buildSegmentPill('pending', 'Pending'),
                        _buildSegmentPill('archived', 'Archived'),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Add New Account',
                    offset: const Offset(0, 44),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    onSelected: (val) {
                      if (val == 'customer') widget.onAddCustomer();
                      if (val == 'driver') widget.onAddDriver();
                      if (val == 'cashier') widget.onAddCashier();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'customer', child: Row(children: [Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF0284C7)), SizedBox(width: 10), Text('Register Customer', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13))])),
                      PopupMenuItem(value: 'driver', child: Row(children: [Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0284C7)), SizedBox(width: 10), Text('Register Driver', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13))])),
                      PopupMenuItem(value: 'cashier', child: Row(children: [Icon(Icons.point_of_sale_rounded, size: 18, color: Color(0xFF8B5CF6)), SizedBox(width: 10), Text('Register Cashier', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13))])),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x330284C7), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Add Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text('Unified management of customers, delivery drivers, and POS cashiers from public.profiles.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ],
                    ),
                    controls,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text('Unified management of customers, delivery drivers, and POS cashiers from public.profiles.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 18),
          summaryStrip,
          if (_statusFilter == 'pending' && !_isPolicyBannerDismissed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '7-Day Verification & Auto-Deletion Policy',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pending unverified accounts must be approved within 7 days from registration. Accounts not verified within 7 days are automatically purged and deleted from the system.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Dismiss',
                    child: InkWell(
                      onTap: () => setState(() => _isPolicyBannerDismissed = true),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF92400E),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState: _isSearchExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isSearchExpanded = true),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (_searchQuery.isNotEmpty || _selectedCategory != 'all')
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF0284C7).withValues(alpha: 0.25),
                      width: (_searchQuery.isNotEmpty || _selectedCategory != 'all') ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF38BDF8)],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x330284C7),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Search & Filter Accounts',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Filter Active',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Query: "$_searchQuery" • Category: ${_selectedCategory.toUpperCase()}'
                                          : _selectedCategory != 'all'
                                              ? 'Category: ${_selectedCategory.toUpperCase()}'
                                              : 'Click to open search bar and category filters (Customers, Drivers, Cashiers)',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                                  tooltip: 'Clear Filters',
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                      _selectedCategory = 'all';
                                    });
                                  },
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_rounded, size: 15, color: Color(0xFF0284C7)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Open Search',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                    SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: 0.0,
                                      duration: Duration(milliseconds: 350),
                                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0284C7)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            secondChild: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF38BDF8)],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x330284C7),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Search & Filter Accounts',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.2,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF0284C7),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  const Text(
                                                    'Filter Active',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0284C7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Refine profiles by query name, phone, UUID, or user role category',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => setState(() => _isSearchExpanded = false),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Hide Search',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      AnimatedRotation(
                                        turns: 0.5,
                                        duration: Duration(milliseconds: 350),
                                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildSearchField(),
                          const SizedBox(height: 16),
                          _buildCategoryFilterBar(),
                          if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Showing ${filtered.length} matching result${filtered.length == 1 ? '' : 's'}',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                        _selectedCategory = 'all';
                                        _currentPage = 1;
                                      });
                                      if (widget.onClearHighlight != null) widget.onClearHighlight!();
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0284C7)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reset All Filters',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingProfiles
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : filtered.isEmpty
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            _statusFilter == 'archived'
                                ? 'No archived accounts found.'
                                : _statusFilter == 'pending'
                                    ? 'No pending verification accounts found.'
                                    : 'No active accounts found matching filter.',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ),
                      )
                : _isGridView
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 3;
                          if (constraints.maxWidth < 700) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 1100) {
                            crossAxisCount = 2;
                          }
                          return GridView.builder(
                            itemCount: paginated.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 290,
                            ),
                            itemBuilder: (context, index) => _buildAccountCard(paginated[index]),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6))],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: ClipRect(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        dataRowMinHeight: 64,
                                        dataRowMaxHeight: 72,
                                        headingRowHeight: 50,
                                        columnSpacing: 16,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(label: Text('ACCOUNT UUID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('USER PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('PHONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ROLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('REGISTERED DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                        ],
                                        rows: paginated.map((profile) {
                                          final isHighlighted = _isAccountHighlighted(profile);
                                          final id = profile['id']?.toString() ?? '';
                                          final name = profile['full_name']?.toString() ?? profile['name']?.toString() ?? 'User';
                                          final email = profile['email']?.toString() ?? '—';
                                          final phone = profile['phone']?.toString() ?? '—';
                                          final address = profile['address']?.toString() ?? profile['delivery_address']?.toString() ?? '—';
                                          final avatarUrl = profile['avatar_url']?.toString() ?? profile['image_url']?.toString() ?? profile['photo_url']?.toString();
                                          final role = (profile['role'] ?? 'customer').toString().toLowerCase();
                                          final isArchived = profile['is_archived'] == true;
                                          final isPending = !isArchived && _isProfilePending(profile);
                                          final createdAt = (profile['created_at'] ?? '').toString().split('T').first;

                                          Color roleBg;
                                          Color roleFg;
                                          String roleLabel;
                                          if (role == 'driver') {
                                            roleBg = const Color(0xFFE0F2FE);
                                            roleFg = const Color(0xFF0369A1);
                                            roleLabel = 'DRIVER';
                                          } else if (role == 'cashier') {
                                            roleBg = const Color(0xFFF3E8FF);
                                            roleFg = const Color(0xFF9333EA);
                                            roleLabel = 'CASHIER';
                                          } else {
                                            roleBg = const Color(0xFFDCFCE7);
                                            roleFg = const Color(0xFF166534);
                                            roleLabel = 'CUSTOMER';
                                          }

                                          Color statusBg;
                                          Color statusFg;
                                          String statusLabel;
                                          if (isArchived) {
                                            statusBg = const Color(0xFFFEE2E2);
                                            statusFg = const Color(0xFF991B1B);
                                            statusLabel = 'ARCHIVED';
                                          } else if (isPending) {
                                            statusBg = const Color(0xFFFEF3C7);
                                            statusFg = const Color(0xFF92400E);
                                            statusLabel = 'PENDING OTP';
                                          } else {
                                            statusBg = const Color(0xFFDCFCE7);
                                            statusFg = const Color(0xFF166534);
                                            statusLabel = 'ACTIVE';
                                          }

                                          return animatedDataRow(
                                            isHighlighted: isHighlighted,
                                            cells: [
                                              DataCell(Text(id.length >= 8 ? id.substring(0, 8) : id, style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 17,
                                                      backgroundColor: roleBg,
                                                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                                          ? NetworkImage(avatarUrl)
                                                          : null,
                                                      child: avatarUrl == null || avatarUrl.isEmpty
                                                          ? Text(
                                                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roleFg),
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                        if (email.isNotEmpty && email != '—')
                                                          Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(phone, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                                              DataCell(Text(address.length > 25 ? '${address.substring(0, 25)}...' : address, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(999)),
                                                child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleFg)),
                                              )),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusBg,
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                                                ),
                                              )),
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(createdAt, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                                                    if (isPending) ...[
                                                      const SizedBox(height: 3),
                                                      _buildTimerBadge(profile['created_at']),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                _statusFilter == 'archived'
                                                    ? Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmRestore(profile),
                                                            icon: const Icon(Icons.unarchive_outlined, size: 14),
                                                            label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF10B981),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmDeletePermanently(profile),
                                                            icon: const Icon(Icons.delete_forever_rounded, size: 14),
                                                            label: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFDC2626),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ElevatedButton.icon(
                                                            onPressed: () => widget.onViewGenericAccount(profile),
                                                            icon: const Icon(Icons.visibility_rounded, size: 14),
                                                            label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFF1F5F9),
                                                              foregroundColor: const Color(0xFF0F172A),
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          ElevatedButton.icon(
                                                            onPressed: () => widget.onEditGenericAccount(profile),
                                                            icon: const Icon(Icons.edit_rounded, size: 14),
                                                            label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF0284C7),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          if (isPending) ...[
                                                            const SizedBox(width: 4),
                                                            ElevatedButton.icon(
                                                              onPressed: () => _confirmVerifyAccount(profile),
                                                              icon: const Icon(Icons.verified_user_rounded, size: 14),
                                                              label: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFF10B981),
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                              ),
                                                            ),
                                                          ],
                                                          const SizedBox(width: 4),
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmArchive(profile),
                                                            icon: const Icon(Icons.archive_outlined, size: 14),
                                                            label: const Text('Archive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFD97706),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppPaginationControls(
              totalItems: filtered.length,
              currentPage: _currentPage,
              itemsPerPage: _itemsPerPage,
              onPageChanged: (page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (perPage) => setState(() {
                _itemsPerPage = perPage;
                _currentPage = 1;
              }),
            ),
          ],
        ],
      ),
    );
  }
}
