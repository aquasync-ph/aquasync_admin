import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../dialogs/dialogs.dart';
import '../../widgets/widgets.dart';

class AnnouncementsPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const AnnouncementsPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'
  String _typeFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.fetchAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = res.map((m) => AnnouncementModel.fromSupabase(m)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AnnouncementModel> get _filteredAnnouncements {
    return _announcements.where((a) {
      final matchesSearch = a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.type.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && a.isActive) ||
          (_statusFilter == 'inactive' && !a.isActive);

      final matchesType = _typeFilter == 'all' || a.type.toLowerCase() == _typeFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  void _openAddAnnouncementModal() {
    showDialog(
      context: context,
      builder: (context) => AddAnnouncementDialog(
        onSuccess: () {
          _loadAnnouncements();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Announcement published successfully.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to publish announcement: $err');
        },
      ),
    );
  }

  void _openEditAnnouncementModal(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => EditAnnouncementDialog(
        announcement: announcement,
        onSuccess: () {
          _loadAnnouncements();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Announcement updated.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to update announcement: $err');
        },
      ),
    );
  }

  void _toggleActiveStatus(AnnouncementModel announcement) async {
    try {
      final newStatus = !announcement.isActive;
      await SupabaseService.toggleAnnouncementStatus(announcementId: announcement.id, isActive: newStatus);
      await _loadAnnouncements();
      widget.onRefresh();
      SweetAlert.showGlobalSuccess('Announcement marked as ${newStatus ? "Active" : "Inactive"}.');
    } catch (e) {
      SweetAlert.showGlobalError('Failed to update status: $e');
    }
  }

  void _confirmDeleteAnnouncement(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Delete Announcement?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to delete announcement "${announcement.title}"? This action cannot be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteAnnouncement(announcement.id);
                await _loadAnnouncements();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Announcement deleted permanently.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to delete announcement: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Announcement'),
          ),
        ],
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
      accentColor: const Color(0xFF38BDF8),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search by title, message content, or type...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5A5E63)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0098DA)),
        filled: true,
        fillColor: const Color(0xFFE6F3FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    int totalCount = _announcements.length;
    int activeCount = _announcements.where((a) => a.isActive).length;
    int promoCount = _announcements.where((a) => a.type == 'promo').length;
    int alertCount = _announcements.where((a) => a.type == 'alert' || a.type == 'maintenance').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Broadcasts', value: '$totalCount', icon: Icons.campaign_rounded, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Active Broadcasts', value: '$activeCount', icon: Icons.sensors_outlined, color: const Color(0xFF34D399))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Promos & Offers', value: '$promoCount', icon: Icons.local_offer_rounded, color: const Color(0xFFC084FC))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Alerts & Maintenance', value: '$alertCount', icon: Icons.warning_amber_rounded, color: const Color(0xFFFCD34D))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total', value: '$totalCount', icon: Icons.campaign_rounded, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Active', value: '$activeCount', icon: Icons.sensors_outlined, color: const Color(0xFF34D399))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Promos', value: '$promoCount', icon: Icons.local_offer_rounded, color: const Color(0xFFC084FC))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Alerts', value: '$alertCount', icon: Icons.warning_amber_rounded, color: const Color(0xFFFCD34D))),
            ],
          );
        }
      },
    );

    final filteredList = _filteredAnnouncements;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedList = filteredList.isEmpty
        ? <AnnouncementModel>[]
        : filteredList.sublist(
            startIndex.clamp(0, filteredList.length),
            (startIndex + _itemsPerPage).clamp(0, filteredList.length),
          );

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Broadcast Announcements', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                  SizedBox(height: 4),
                  Text('Manage station promos, news, and maintenance alerts broadcasted in public.announcements.', style: TextStyle(fontSize: 13, color: Color(0xFF5A5E63))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddAnnouncementModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Announcement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0098DA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          summaryStrip,
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Color(0x140B1D2A), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE6F3FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w500),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'active', child: Text('Active Only', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive Only', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _statusFilter = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _typeFilter,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE6F3FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w500),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'info', child: Text('General Info', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'promo', child: Text('Promotional', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'alert', child: Text('Alerts', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _typeFilter = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x140B1D2A), blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0098DA)))
                  : filteredList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text('No broadcast announcements found matching filter.', style: TextStyle(fontSize: 13, color: Color(0xFF5A5E63)))),
                        )
                      : LayoutBuilder(
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
                                        dataRowMinHeight: 54,
                                        dataRowMaxHeight: 58,
                                        headingRowHeight: 50,
                                        columnSpacing: 20,
                                        columns: const [
                                          DataColumn(label: Text('ANNOUNCEMENT TITLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('BROADCAST TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('MESSAGE CONTENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('SCHEDULE (START - END)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('DATE CREATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                        ],
                                            rows: paginatedList.map((ann) {
                                              Color typeBg = const Color(0x330098DA);
                                              Color typeFg = const Color(0xFF0098DA);
                                              if (ann.type == 'promo') {
                                                typeBg = const Color(0x339333EA);
                                                typeFg = const Color(0xFF9333EA);
                                              } else if (ann.type == 'alert') {
                                                typeBg = const Color(0x33DC2626);
                                                typeFg = const Color(0xFFDC2626);
                                              } else if (ann.type == 'maintenance') {
                                                typeBg = const Color(0x33D97706);
                                                typeFg = const Color(0xFFD97706);
                                              }

                                              final now = DateTime.now();
                                              String statusText = 'INACTIVE';
                                              Color statusBg = const Color(0xFFF1F5F9);
                                              Color statusFg = const Color(0xFF5A5E63);

                                              if (!ann.isActive) {
                                                statusText = 'INACTIVE';
                                                statusBg = const Color(0xFFF1F5F9);
                                                statusFg = const Color(0xFF5A5E63);
                                              } else if (ann.startsAt != null && now.isBefore(ann.startsAt!)) {
                                                statusText = 'SCHEDULED';
                                                statusBg = const Color(0xFFFEF3C7);
                                                statusFg = const Color(0xFF92400E);
                                              } else if (ann.endsAt != null && now.isAfter(ann.endsAt!)) {
                                                statusText = 'EXPIRED';
                                                statusBg = const Color(0xFFFEE2E2);
                                                statusFg = const Color(0xFF991B1B);
                                              } else {
                                                statusText = 'ACTIVE';
                                                statusBg = const Color(0xFFDCFCE7);
                                                statusFg = const Color(0xFF166534);
                                              }

                                              String formatDt(DateTime dt) {
                                                String two(int n) => n.toString().padLeft(2, '0');
                                                return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
                                              }

                                              final startText = ann.startsAt != null ? formatDt(ann.startsAt!) : 'Immediate';
                                              final endText = ann.endsAt != null ? formatDt(ann.endsAt!) : 'No Expiry';

                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(ann.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A)))),
                                                  DataCell(Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(999)),
                                                    child: Text(ann.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeFg)),
                                                  )),
                                                  DataCell(SizedBox(
                                                    width: 220,
                                                    child: Text(
                                                      ann.message,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A5E63)),
                                                    ),
                                                  )),
                                                  DataCell(Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Start: $startText', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0B1D2A))),
                                                      Text('End: $endText', style: const TextStyle(fontSize: 11, color: Color(0xFF5A5E63))),
                                                    ],
                                                  )),
                                                  DataCell(Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusBg,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                                                    ),
                                                  )),
                                                  DataCell(Text(ann.createdAt, style: const TextStyle(fontSize: 11, color: Color(0xFF5A5E63)))),
                                                  DataCell(Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        onPressed: () => _toggleActiveStatus(ann),
                                                        icon: Icon(ann.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 14),
                                                        label: Text(ann.isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: ann.isActive ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                                          foregroundColor: ann.isActive ? const Color(0xFF92400E) : const Color(0xFF166534),
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      ElevatedButton.icon(
                                                        onPressed: () => _openEditAnnouncementModal(ann),
                                                        icon: const Icon(Icons.edit_rounded, size: 14),
                                                        label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF0098DA),
                                                          foregroundColor: Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      ElevatedButton.icon(
                                                        onPressed: () => _confirmDeleteAnnouncement(ann),
                                                        icon: const Icon(Icons.delete_forever_rounded, size: 14),
                                                        label: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFFDC2626),
                                                          foregroundColor: Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                    ],
                                                  )),
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
          if (filteredList.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppPaginationControls(
              totalItems: filteredList.length,
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
