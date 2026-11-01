import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

class DriversPage extends StatefulWidget {
  final List<DriverModel> drivers;
  final VoidCallback onAddDriver;
  final Function(DriverModel) onViewDriverDetails;
  final Function(DriverModel) onEditDriver;
  final VoidCallback onRefresh;

  const DriversPage({
    super.key,
    required this.drivers,
    required this.onAddDriver,
    required this.onViewDriverDetails,
    required this.onEditDriver,
    required this.onRefresh,
  });

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  bool _showArchived = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<DriverModel> get _filteredDrivers {
    final list = widget.drivers.where((d) => d.isActive == !_showArchived).toList();
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((d) {
      return d.fullName.toLowerCase().contains(q) ||
          (d.phone != null && d.phone!.toLowerCase().contains(q)) ||
          d.id.toLowerCase().contains(q);
    }).toList();
  }

  void _confirmArchive(DriverModel drv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Archive Driver Profile?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to archive "${drv.fullName}"? The driver will be moved to archived records.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProfileArchiveStatus(userId: drv.id, isArchived: true);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${drv.fullName}" moved to archived drivers.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to archive: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Archive Driver'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(DriverModel drv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Restore Archived Driver?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Restore "${drv.fullName}" back to active driver roster?', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProfileArchiveStatus(userId: drv.id, isArchived: false);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${drv.fullName}" restored to active drivers.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to restore: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Restore Driver'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(DriverModel drv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Permanently Delete Driver?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to PERMANENTLY delete "${drv.fullName}"? This action CANNOT be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteProfile(drv.id);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${drv.fullName}" permanently deleted.');
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
        hintText: 'Search driver by name, phone, or UUID...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
        filled: true,
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDrivers;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <DriverModel>[]
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

    int totalDrivers = widget.drivers.length;
    int activeDrivers = widget.drivers.where((d) => d.isActive).length;
    int archivedDrivers = widget.drivers.where((d) => !d.isActive).length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Registered Drivers', value: '$totalDrivers', icon: Icons.badge_outlined, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Active Driver Roster', value: '$activeDrivers', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Archived Drivers', value: '$archivedDrivers', icon: Icons.archive_outlined, color: const Color(0xFFFCD34D))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total', value: '$totalDrivers', icon: Icons.badge_outlined, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Active', value: '$activeDrivers', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Archived', value: '$archivedDrivers', icon: Icons.archive_outlined, color: const Color(0xFFFCD34D))),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Driver Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                  SizedBox(height: 4),
                  Text('Registered delivery drivers loaded from public.profiles where role = driver.', style: TextStyle(fontSize: 13, color: Color(0xFF5A5E63))),
                ],
              ),
              Row(
                children: [
                  SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFF0098DA),
                      selectedForegroundColor: Colors.white,
                      backgroundColor: const Color(0xFFE6F3FA),
                      foregroundColor: const Color(0xFF0B1D2A),
                      side: BorderSide(color: const Color(0xFF5A5E63).withValues(alpha: 0.3)),
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: true, label: Text('Archived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (set) => setState(() {
                      _showArchived = set.first;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: widget.onAddDriver,
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Add Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          summaryStrip,
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
                  boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: _buildSearchField(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
                    boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(_showArchived ? 'No archived driver records.' : 'No active drivers found matching search.', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ),
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
                                        columnSpacing: 22,
                                        columns: const [
                                          DataColumn(label: Text('DRIVER UUID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('FULL NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('REGISTERED DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                        ],
                                        rows: paginated.map((drv) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(drv.id.length >= 8 ? drv.id.substring(0, 8) : drv.id, style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                                              DataCell(Text(drv.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                              DataCell(Text(drv.phone ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(999)),
                                                child: const Text('DRIVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                              )),
                                              DataCell(Text(drv.createdAt, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                                              DataCell(
                                                !_showArchived
                                                    ? Row(
                                                        children: [
                                                          ElevatedButton.icon(
                                                            onPressed: () => widget.onViewDriverDetails(drv),
                                                            icon: const Icon(Icons.visibility_rounded, size: 14),
                                                            label: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFE0F2FE),
                                                              foregroundColor: const Color(0xFF0284C7),
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          ElevatedButton.icon(
                                                            onPressed: () => widget.onEditDriver(drv),
                                                            icon: const Icon(Icons.edit_rounded, size: 14),
                                                            label: const Text('Edit Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF0284C7),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmArchive(drv),
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
                                                      )
                                                    : Row(
                                                        children: [
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmRestore(drv),
                                                            icon: const Icon(Icons.unarchive_outlined, size: 14),
                                                            label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF10B981),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmDeletePermanently(drv),
                                                            icon: const Icon(Icons.delete_forever_rounded, size: 14),
                                                            label: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFDC2626),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
