import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../dialogs/dialogs.dart';
import '../../widgets/widgets.dart';

class PromosPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const PromosPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<PromosPage> createState() => _PromosPageState();
}

class _PromosPageState extends State<PromosPage> {
  bool _isGridView = false;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<PromoModel> _promos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.fetchPromos();
      if (mounted) {
        setState(() {
          _promos = res.map((m) => PromoModel.fromSupabase(m)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PromoModel> get _filteredPromos {
    return _promos.where((p) {
      final matchesSearch = p.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.discountType.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && p.isCurrentlyValid) ||
          (_statusFilter == 'expired' && p.isExpired) ||
          (_statusFilter == 'inactive' && !p.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _openAddPromoModal() {
    showDialog(
      context: context,
      builder: (context) => AddPromoDialog(
        onSuccess: () {
          _loadPromos();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Promo code created successfully.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to create promo code: $err');
        },
      ),
    );
  }

  void _openEditPromoModal(PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => EditPromoDialog(
        promo: promo,
        onSuccess: () {
          _loadPromos();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Promo code updated.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to update promo code: $err');
        },
      ),
    );
  }

  void _togglePromoStatus(PromoModel promo) async {
    try {
      final newStatus = !promo.isActive;
      await SupabaseService.togglePromoStatus(promoId: promo.id, isActive: newStatus);
      await _loadPromos();
      widget.onRefresh();
      SweetAlert.showGlobalSuccess('Promo "${promo.code}" marked as ${newStatus ? "Active" : "Inactive"}.');
    } catch (e) {
      SweetAlert.showGlobalError('Failed to update status: $e');
    }
  }

  void _confirmDeletePromo(PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        title: const Text('Delete Promo Code?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text('Are you sure you want to delete promo code "${promo.code}"? This action cannot be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deletePromo(promo.id);
                await _loadPromos();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Promo code deleted permanently.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to delete promo code: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Promo'),
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
      accentColor: const Color(0xFF0284C7),
    );
  }

  Widget _buildStatusBadge(PromoModel promo) {
    Color bg;
    Color fg;
    String label = promo.status;

    switch (label) {
      case 'ACTIVE':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'EXPIRED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'UPCOMING':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'LIMIT REACHED':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'INACTIVE':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildPromoCard(PromoModel promo) {
    final discountStr = promo.discountType == 'percentage'
        ? '${promo.discountValue.toStringAsFixed(0)}%'
        : '₱${promo.discountValue.toStringAsFixed(2)}';

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(promo.code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ],
              ),
              _buildStatusBadge(promo),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DISCOUNT', style: TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(discountStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MIN SPEND', style: TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('₱${promo.minSpend.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    'Uses: ${promo.usedCount} / ${promo.maxUses > 0 ? promo.maxUses : "∞"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text('Until: ${promo.validUntil}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _togglePromoStatus(promo),
                    icon: Icon(promo.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 14),
                    label: Text(promo.isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: promo.isActive ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                      foregroundColor: promo.isActive ? const Color(0xFF92400E) : const Color(0xFF166534),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _openEditPromoModal(promo),
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
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _confirmDeletePromo(promo),
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
          ),
        ],
      ),
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

    int totalCount = _promos.length;
    int activeCount = _promos.where((p) => p.isCurrentlyValid).length;
    int expiredCount = _promos.where((p) => p.isExpired).length;
    int fixedCount = _promos.where((p) => p.discountType == 'fixed').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Promos', value: '$totalCount', icon: Icons.local_offer_rounded, color: const Color(0xFF0284C7))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Active Promos', value: '$activeCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Expired Promos', value: '$expiredCount', icon: Icons.history_rounded, color: const Color(0xFFEF4444))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Fixed Discounts', value: '$fixedCount', icon: Icons.payments_rounded, color: const Color(0xFF8B5CF6))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total', value: '$totalCount', icon: Icons.local_offer_rounded, color: const Color(0xFF0284C7))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Active', value: '$activeCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Expired', value: '$expiredCount', icon: Icons.history_rounded, color: const Color(0xFFEF4444))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Fixed', value: '$fixedCount', icon: Icons.payments_rounded, color: const Color(0xFF8B5CF6))),
            ],
          );
        }
      },
    );

    final filteredList = _filteredPromos;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedList = filteredList.isEmpty
        ? <PromoModel>[]
        : filteredList.sublist(
            startIndex.clamp(0, filteredList.length),
            (startIndex + _itemsPerPage).clamp(0, filteredList.length),
          );

    Widget viewToggleWidget = Container(
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
    );

    Widget createPromoBtn = ElevatedButton.icon(
      onPressed: _openAddPromoModal,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Create Promo Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    List<DropdownMenuItem<String>> filterOptions = const [
      DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)))),
      DropdownMenuItem(value: 'active', child: Text('Active Only', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)))),
      DropdownMenuItem(value: 'expired', child: Text('Expired Only', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)))),
      DropdownMenuItem(value: 'inactive', child: Text('Inactive Only', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)))),
    ];

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summaryStrip,
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 920) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search promo code or discount type...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0284C7)),
                                filled: true,
                                fillColor: const Color(0xFFE0F2FE),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          viewToggleWidget,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _statusFilter,
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFE0F2FE),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              items: filterOptions,
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
                          const SizedBox(width: 10),
                          createPromoBtn,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      flex: 50,
                      child: TextField(
                        onChanged: (val) => setState(() {
                          _searchQuery = val;
                          _currentPage = 1;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search promo code or discount type...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0284C7)),
                          filled: true,
                          fillColor: const Color(0xFFE0F2FE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                        ),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFE0F2FE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                        ),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                        items: filterOptions,
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
                    const SizedBox(width: 10),
                    viewToggleWidget,
                    const SizedBox(width: 10),
                    createPromoBtn,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
                  )
                : filteredList.isEmpty
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(40),
                        child: const Center(child: Text('No promo codes found matching filter.', style: TextStyle(fontSize: 13, color: Color(0xFF475569)))),
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
                            itemCount: paginatedList.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 220,
                            ),
                            itemBuilder: (context, index) => _buildPromoCard(paginatedList[index]),
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
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  dataRowMinHeight: 54,
                                  dataRowMaxHeight: 58,
                                  headingRowHeight: 50,
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('PROMO CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('DISCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('MIN SPEND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('USES (LIMIT)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('VALID UNTIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  ],
                                  rows: paginatedList.map((promo) {
                                    final discountStr = promo.discountType == 'percentage'
                                        ? '${promo.discountValue.toStringAsFixed(0)}%'
                                        : '₱${promo.discountValue.toStringAsFixed(2)}';

                                    return DataRow(
                                      cells: [
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 8),
                                            Text(promo.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                          ],
                                        )),
                                        DataCell(Text(discountStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                        DataCell(Text('₱${promo.minSpend.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                        DataCell(Text('${promo.usedCount} / ${promo.maxUses > 0 ? promo.maxUses : "∞"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)))),
                                        DataCell(_buildStatusBadge(promo)),
                                        DataCell(Text(promo.validUntil, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                        DataCell(Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _togglePromoStatus(promo),
                                              icon: Icon(promo.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 14),
                                              label: Text(promo.isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: promo.isActive ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                                foregroundColor: promo.isActive ? const Color(0xFF92400E) : const Color(0xFF166534),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton.icon(
                                              onPressed: () => _openEditPromoModal(promo),
                                              icon: const Icon(Icons.edit_rounded, size: 14),
                                              label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0284C7),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton.icon(
                                              onPressed: () => _confirmDeletePromo(promo),
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
