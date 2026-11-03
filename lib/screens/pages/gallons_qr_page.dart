import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

class GallonsQrPage extends StatefulWidget {
  final List<GallonItemModel> gallons;
  final List<CustomerModel>? customers;
  final VoidCallback onAddGallon;
  final VoidCallback? onBatchGenerateQr;
  final Function(GallonItemModel) onEditGallon;
  final Function(GallonItemModel) onViewQr;
  final Function(GallonItemModel) onGenerateQr;
  final Function(GallonItemModel) onViewHistory;
  final VoidCallback onRefresh;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;
  final Function(GallonItemModel)? onLocateCustomer;

  const GallonsQrPage({
    super.key,
    required this.gallons,
    this.customers,
    required this.onAddGallon,
    this.onBatchGenerateQr,
    required this.onEditGallon,
    required this.onViewQr,
    required this.onGenerateQr,
    required this.onViewHistory,
    required this.onRefresh,
    this.highlightQuery,
    this.onClearHighlight,
    this.onLocateCustomer,
  });

  @override
  State<GallonsQrPage> createState() => _GallonsQrPageState();
}

class _GallonsQrPageState extends State<GallonsQrPage> {
  bool _showArchived = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  late TextEditingController _searchController;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  bool _isGallonHighlighted(GallonItemModel g) {
    if (widget.highlightQuery == null || widget.highlightQuery!.trim().isEmpty) {
      return false;
    }
    final q = widget.highlightQuery!.toLowerCase().trim();
    return g.gallonCode.toLowerCase().contains(q) ||
        g.id.toLowerCase().contains(q);
  }

  List<GallonItemModel> get _filteredGallons {
    final list = widget.gallons.where((g) {
      final isRet = g.status.toLowerCase() == 'retired';
      return _showArchived ? isRet : !isRet;
    }).toList();

    final filteredList = list.where((g) {
      final formattedName = _formatInitialAndSurname(g.assigned).toLowerCase();
      final matchesSearch = g.gallonCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.status.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.assigned.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          formattedName.contains(_searchQuery.toLowerCase()) ||
          g.containerType.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' || g.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    if (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty) {
      filteredList.sort((a, b) {
        final aH = _isGallonHighlighted(a);
        final bH = _isGallonHighlighted(b);
        if (aH && !bH) return -1;
        if (!aH && bH) return 1;
        return 0;
      });
    }

    return filteredList;
  }

  /// Formats customer full name as Initial + Surname (e.g. "Juan Dela Cruz" -> "J. Dela Cruz")
  String _formatInitialAndSurname(String fullName) {
    final str = fullName.trim();
    if (str.isEmpty ||
        str == '—' ||
        str.toLowerCase().contains('available') ||
        str.toLowerCase().contains('station stock') ||
        str.toLowerCase().contains('unassigned')) {
      return 'Available in Station (AQUAZONE)';
    }
    final parts = str.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first;
    }
    final firstInitial = parts.first[0].toUpperCase();
    final surname = parts.sublist(1).join(' ');
    return '$firstInitial. $surname';
  }

  /// Returns initials badge (e.g. "J.D.C." or "J.C.")
  String _getInitialsBadge(String fullName) {
    final str = fullName.trim();
    if (str.isEmpty ||
        str == '—' ||
        str.toLowerCase().contains('available') ||
        str.toLowerCase().contains('station stock')) {
      return 'AZ';
    }
    final parts = str.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
    }
    return parts.first[0].toUpperCase();
  }

  void _confirmRetire(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Retire Gallon Container?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to retire container "${gallon.gallonCode}"? It will be marked as Retired and moved to archived containers.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleGallonRetiredStatus(gallonId: gallon.id, isRetired: true);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Container moved to archived containers.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to retire container: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Retire Container'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Restore Retired Gallon Container?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Restore container back to active stock as Available?', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleGallonRetiredStatus(gallonId: gallon.id, isRetired: false);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Container restored to available stock.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to restore container: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Restore Container'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Permanently Delete Gallon Container?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text('Are you sure you want to PERMANENTLY delete this container? This action CANNOT be undone.', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteGallon(gallon.id);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Container permanently deleted.');
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
      controller: _searchController,
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search container by customer name, status, or location...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  if (widget.onClearHighlight != null) widget.onClearHighlight!();
                },
              )
            : null,
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

  Widget _buildHighlightBanner() {
    if (widget.highlightQuery == null || widget.highlightQuery!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3860), Color(0xFF03182B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 15, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x2238BDF8), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7DD3FC), size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TARGETED ITEM HIGHLIGHTED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Viewing targeted item: "${widget.highlightQuery}"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _statusFilter,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Container Statuses', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'available', child: Text('Available', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'borrowed', child: Text('Borrowed', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'returned', child: Text('Returned', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'lost', child: Text('Lost', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'damaged', child: Text('Damaged', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _statusFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        if (widget.onBatchGenerateQr != null) ...[
          OutlinedButton.icon(
            onPressed: widget.onBatchGenerateQr,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Batch Generate QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              backgroundColor: const Color(0xFFE0F2FE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: widget.onAddGallon,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Register Gallon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGallons;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <GallonItemModel>[]
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

    int totalCount = widget.gallons.length;
    int availableCount = widget.gallons.where((g) => g.status.toLowerCase() == 'available').length;
    int outCount = widget.gallons.where((g) => g.status.toLowerCase() == 'out_for_delivery' || g.status.toLowerCase() == 'out for delivery').length;
    int borrowedCount = widget.gallons.where((g) => g.status.toLowerCase() == 'borrowed').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Containers', value: '$totalCount', icon: Icons.local_drink_outlined, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Available Stock', value: '$availableCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Out for Delivery', value: '$outCount', icon: Icons.local_shipping_outlined, color: const Color(0xFF7DD3FC))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Borrowed Containers', value: '$borrowedCount', icon: Icons.opacity_rounded, color: const Color(0xFFFCA5A5))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total', value: '$totalCount', icon: Icons.local_drink_outlined, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Available', value: '$availableCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Out for Delivery', value: '$outCount', icon: Icons.local_shipping_outlined, color: const Color(0xFF7DD3FC))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Borrowed', value: '$borrowedCount', icon: Icons.opacity_rounded, color: const Color(0xFFFCA5A5))),
            ],
          );
        }
      },
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightBanner(),
          summaryStrip,
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
              boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1050) {
                  return Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 12),
                      SizedBox(width: 210, child: _buildStatusDropdown()),
                      const SizedBox(width: 12),
                      _buildActionButtons(),
                    ],
                  );
                } else if (constraints.maxWidth >= 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 12),
                          SizedBox(width: 210, child: _buildStatusDropdown()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActionButtons(),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      _buildStatusDropdown(),
                      const SizedBox(height: 12),
                      _buildActionButtons(),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
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
                      child: Text(_showArchived ? 'No retired / archived gallon containers.' : 'No active gallon containers found matching search.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            dataRowMinHeight: 58,
                            dataRowMaxHeight: 62,
                            headingRowHeight: 50,
                            columnSpacing: 22,
                            columns: const [
                              DataColumn(label: Text('ASSIGNED CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataColumn(label: Text('LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataColumn(label: Text('QR STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                            ],
                            rows: paginated.map((gallon) {
                              final isHighlighted = _isGallonHighlighted(gallon);
                              final isAssigned = gallon.assigned.isNotEmpty &&
                                  !gallon.assigned.toLowerCase().contains('available') &&
                                  gallon.assigned != '—';
                              return animatedDataRow(
                                isHighlighted: isHighlighted,
                                cells: [
                                  DataCell(
                                    isAssigned
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2FE),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _getInitialsBadge(gallon.assigned),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatInitialAndSurname(gallon.assigned),
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                  if (gallon.borrowedAt.isNotEmpty && gallon.borrowedAt != 'Not yet recorded') ...[
                                                    const SizedBox(height: 2),
                                                    Text('Borrowed: ${gallon.borrowedAt}', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF0284C7)),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Available in Station (AQUAZONE)',
                                                style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                                              ),
                                            ],
                                          ),
                                  ),
                                  DataCell(GallonStatusBadge(status: gallon.status)),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: SizedBox(
                                        width: 180,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              gallon.location.isEmpty ? 'Aqua Pure Water Station' : gallon.location,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            InkWell(
                                              onTap: widget.onLocateCustomer != null ? () => widget.onLocateCustomer!(gallon) : null,
                                              borderRadius: BorderRadius.circular(4),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 2.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0284C7)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'View Map',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0284C7),
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: gallon.hasQr ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      gallon.hasQr ? 'QR REGISTERED' : 'NO QR',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: gallon.hasQr ? const Color(0xFF166534) : const Color(0xFF92400E),
                                      ),
                                    ),
                                  )),
                                  DataCell(
                                    !_showArchived
                                        ? Row(
                                            children: [
                                              if (!gallon.hasQr)
                                                ElevatedButton.icon(
                                                  onPressed: () => widget.onGenerateQr(gallon),
                                                  icon: const Icon(Icons.qr_code_2_rounded, size: 15),
                                                  label: const Text('Generate QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0284C7),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                )
                                              else
                                                ElevatedButton.icon(
                                                  onPressed: () => widget.onViewQr(gallon),
                                                  icon: const Icon(Icons.qr_code_rounded, size: 15),
                                                  label: const Text('View QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1B4965),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                ),
                                              const SizedBox(width: 6),
                                              Tooltip(
                                                message: 'Edit Gallon',
                                                child: ElevatedButton(
                                                  onPressed: () => widget.onEditGallon(gallon),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0098DA),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(36, 36),
                                                    maximumSize: const Size(36, 36),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: const Icon(Icons.edit_rounded, size: 16),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Tooltip(
                                                message: 'Gallon History',
                                                child: ElevatedButton(
                                                  onPressed: () => widget.onViewHistory(gallon),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF5A5E63),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(36, 36),
                                                    maximumSize: const Size(36, 36),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: const Icon(Icons.history_rounded, size: 16),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Tooltip(
                                                message: 'Retire Gallon',
                                                child: ElevatedButton(
                                                  onPressed: () => _confirmRetire(gallon),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFD97706),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(36, 36),
                                                    maximumSize: const Size(36, 36),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: const Icon(Icons.archive_outlined, size: 16),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _confirmRestore(gallon),
                                                icon: const Icon(Icons.unarchive_outlined, size: 15),
                                                label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Tooltip(
                                                message: 'Delete Permanently',
                                                child: ElevatedButton(
                                                  onPressed: () => _confirmDeletePermanently(gallon),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFDC2626),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(36, 36),
                                                    maximumSize: const Size(36, 36),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: const Icon(Icons.delete_forever_rounded, size: 16),
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
                      );
                    },
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
