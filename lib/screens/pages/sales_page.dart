import 'dart:math';
import 'package:flutter/material.dart';
import '../../dialogs/receipt_details_dialog.dart';
import '../../services/supabase_service.dart';
import '../../utils/print_helper.dart';
import '../../widgets/widgets.dart';

class SalesPage extends StatefulWidget {
  final double? totalSalesToday;
  final double? cashSalesToday;
  final double? gcashSalesToday;
  final int? transactionCountToday;
  final List<Map<String, dynamic>>? sales;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;

  const SalesPage({
    super.key,
    this.totalSalesToday,
    this.cashSalesToday,
    this.gcashSalesToday,
    this.transactionCountToday,
    this.sales,
    this.highlightQuery,
    this.onClearHighlight,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  String _dateRange = 'all'; // 'all', 'today', 'yesterday', 'week', 'month'
  String _paymentFilter = 'all'; // 'all', 'cash', 'gcash'
  String _classificationFilter = 'all'; // 'all', 'walk-in', 'online'
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  late TextEditingController _searchController;

  bool _isLoading = false;
  double _totalSales = 0.0;
  double _cashSales = 0.0;
  double _gcashSales = 0.0;
  int _transactionCount = 0;
  List<Map<String, dynamic>> _salesList = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.sales != null && widget.sales!.isNotEmpty) {
      _totalSales = widget.totalSalesToday ?? 0.0;
      _cashSales = widget.cashSalesToday ?? 0.0;
      _gcashSales = widget.gcashSalesToday ?? 0.0;
      _transactionCount = widget.transactionCountToday ?? widget.sales!.length;
      _salesList = widget.sales!;
    }
    _loadSalesData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSaleHighlighted(Map<String, dynamic> sale) {
    if (widget.highlightQuery == null || widget.highlightQuery!.trim().isEmpty) {
      return false;
    }
    final q = widget.highlightQuery!.toLowerCase().trim();
    final id = (sale['id'] ?? '').toString().toLowerCase();
    final inv = (sale['invoice_number'] ?? '').toString().toLowerCase();
    return id.contains(q) || inv.contains(q);
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.fetchSalesSummary(_dateRange);
      if (mounted) {
        setState(() {
          _totalSales = (data['totalSales'] as num?)?.toDouble() ?? 0.0;
          _cashSales = (data['cashSales'] as num?)?.toDouble() ?? 0.0;
          _gcashSales = (data['gcashSales'] as num?)?.toDouble() ?? 0.0;
          _transactionCount = (data['transactionCount'] as num?)?.toInt() ?? 0;
          _salesList = List<Map<String, dynamic>>.from(data['sales'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SweetAlert.showToast(
          'Failed to load sales analytics: $e',
          type: SweetAlertType.error,
          title: 'Analytics Error',
          autoDismiss: false,
        );
      }
    }
  }

  String _determineClassification(Map<String, dynamic> item) {
    final invNum = (item['invoice_number'] ?? item['receipt_number'] ?? item['order_number'] ?? item['id'] ?? '').toString().toUpperCase();
    final orderType = (item['order_type'] ?? '').toString().trim().toLowerCase();
    final bool isWalkInFlag = item['is_walk_in'] == true;

    if (orderType == 'online' || orderType == 'app' || orderType == 'delivery' || invNum.contains('ORD-') || invNum.startsWith('ORD') || invNum.startsWith('APP-')) {
      return 'Online';
    }

    if (isWalkInFlag || orderType == 'pos' || orderType == 'walk_in' || orderType == 'walk-in' || invNum.contains('POS-') || invNum.startsWith('POS')) {
      return 'Walk-In';
    }

    final fulfillment = (item['fulfillment_type'] ?? item['notes'] ?? '').toString().toLowerCase();
    if (fulfillment.contains('delivery') || fulfillment.contains('online')) {
      return 'Online';
    }

    if (item['classification'] != null && item['classification'].toString().isNotEmpty) {
      final c = item['classification'].toString().trim().toLowerCase();
      if (c == 'online' || c == 'app' || c == 'delivery') return 'Online';
      if (c == 'walk-in' || c == 'walk_in' || c == 'pos') return 'Walk-In';
    }

    return item['is_online_order'] == true ? 'Online' : 'Walk-In';
  }

  List<Map<String, dynamic>> get _filteredSales {
    final list = _salesList.where((sale) {
      final idStr = sale['id']?.toString() ?? '';
      final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
      final invoiceNum = sale['invoice_number']?.toString() ?? 'INV-$shortId';
      final receiptNum = sale['receipt_number']?.toString() ?? 'RCP-$shortId';
      final custStr = sale['customer_name']?.toString() ?? sale['notes']?.toString() ?? 'Customer';
      final payMethod = sale['payment_method']?.toString() ?? 'Cash';
      final classification = _determineClassification(sale);

      final matchesSearch = invoiceNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          receiptNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          custStr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          payMethod.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          classification.toLowerCase().contains(_searchQuery.toLowerCase());

      final pLower = payMethod.toLowerCase();
      final matchesPayment = _paymentFilter == 'all' ||
          (_paymentFilter == 'cash' && (pLower.contains('cash') || pLower.contains('cod') || pLower.contains('delivery'))) ||
          (_paymentFilter == 'gcash' && (pLower.contains('gcash') || pLower.contains('online') || pLower.contains('paymongo') || pLower.contains('maya')));
      final matchesClassification = _classificationFilter == 'all' || classification.toLowerCase().contains(_classificationFilter.toLowerCase());

      return matchesSearch && matchesPayment && matchesClassification;
    }).toList();

    if (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty) {
      list.sort((a, b) {
        final aH = _isSaleHighlighted(a);
        final bH = _isSaleHighlighted(b);
        if (aH && !bH) return -1;
        if (!aH && bH) return 1;
        return 0;
      });
    }
    return list;
  }

  double get _averageOrderValue {
    if (_transactionCount == 0) return 0.0;
    return _totalSales / _transactionCount;
  }

  int get _walkInCount {
    return _salesList.where((s) => _determineClassification(s) == 'Walk-In').length;
  }

  int get _onlineCount {
    return _salesList.where((s) => _determineClassification(s) == 'Online').length;
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return AppSummaryCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: const Color(0xFF0284C7),
      subText: subtitle,
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
        hintText: 'Search invoice, receipt, customer, classification, payment method...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF475569), size: 18),
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
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
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

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentFilter,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Payment Types (COD & GCash)', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'cash', child: Text('Cash on Delivery (COD) Only', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'gcash', child: Text('GCash Payment Only', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _paymentFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  Widget _buildClassificationDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _classificationFilter,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Classifications', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'walk-in', child: Text('Walk-In Only', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'online', child: Text('Online Only', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _classificationFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  Widget _buildDateRangeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _dateRange,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE0F2FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      items: const [
        DropdownMenuItem(value: 'today', child: Text('Today', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'yesterday', child: Text('Yesterday', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'week', child: Text('Last 7 Days', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'month', child: Text('This Month', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'all', child: Text('All Time', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _dateRange = val;
            _currentPage = 1;
          });
          _loadSalesData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSales;
    final totalPages = max(1, (filtered.length / _itemsPerPage).ceil());
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final paginated = filtered.isEmpty || startIndex >= filtered.length
        ? <Map<String, dynamic>>[]
        : filtered.sublist(startIndex, endIndex);

    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: "Total Revenue", value: '₱${_totalSales.toStringAsFixed(2)}', icon: Icons.payments_outlined, color: const Color(0xFF0284C7), subtitle: 'AOV: ₱${_averageOrderValue.toStringAsFixed(2)}')),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Cash Receipts', value: '₱${_cashSales.toStringAsFixed(2)}', icon: Icons.attach_money_rounded, color: const Color(0xFF10B981), subtitle: '${_totalSales > 0 ? ((_cashSales / _totalSales) * 100).toStringAsFixed(1) : 0}% of revenue')),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'GCash Digital', value: '₱${_gcashSales.toStringAsFixed(2)}', icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF0284C7), subtitle: '${_totalSales > 0 ? ((_gcashSales / _totalSales) * 100).toStringAsFixed(1) : 0}% of revenue')),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Transactions', value: '$_transactionCount Completed', icon: Icons.task_alt_rounded, color: const Color(0xFFF59E0B), subtitle: '$_walkInCount Walk-In • $_onlineCount Online')),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: "Total Revenue", value: '₱${_totalSales.toStringAsFixed(2)}', icon: Icons.payments_outlined, color: const Color(0xFF0284C7))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Cash', value: '₱${_cashSales.toStringAsFixed(2)}', icon: Icons.attach_money_rounded, color: const Color(0xFF10B981))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'GCash', value: '₱${_gcashSales.toStringAsFixed(2)}', icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF0284C7))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Transactions', value: '$_transactionCount', icon: Icons.task_alt_rounded, color: const Color(0xFFF59E0B))),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sales & Revenue Analytics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Comprehensive revenue tracking & transaction analytics recorded from all sales (Walk-in & Online) ($_dateRange).', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (filtered.isEmpty) {
                        SweetAlert.showToast('No sales records to print.', type: SweetAlertType.warning, title: 'Print Warning');
                        return;
                      }
                      PrintHelper.printSalesReport(filtered, _dateRange);
                      SweetAlert.showToast('Sales analytics report sent to printer!', type: SweetAlertType.success, title: 'Printing Report');
                    },
                    icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF0284C7)),
                    label: const Text('Print Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _loadSalesData,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
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
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 640) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      _buildDateRangeDropdown(),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(),
                      const SizedBox(height: 12),
                      _buildClassificationDropdown(),
                    ],
                  );
                } else if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDateRangeDropdown()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildFilterDropdown()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildClassificationDropdown()),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchField()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _buildDateRangeDropdown()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _buildFilterDropdown()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _buildClassificationDropdown()),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6))],
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                    )
                  : filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF0284C7)),
                                const SizedBox(height: 12),
                                Text('No sales transactions found for timeframe: $_dateRange.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                const Text('Try changing your date filter, classification, or search query.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ],
                            ),
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
                                          DataColumn(label: Text('INVOICE / RECEIPT #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('CUSTOMER / NOTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('CLASSIFICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('TOTAL AMOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('TIMESTAMP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                        ],
                                        rows: paginated.map((sale) {
                                          final isHighlighted = _isSaleHighlighted(sale);
                                          final idStr = sale['id']?.toString() ?? '';
                                          final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
                                          final invoiceNum = sale['invoice_number']?.toString() ?? 'INV-$shortId';
                                          final receiptNum = sale['receipt_number']?.toString() ?? 'RCP-$shortId';
                                          final custStr = sale['customer_name']?.toString() ?? sale['notes']?.toString() ?? 'Walk-in Customer';
                                          final payMethod = sale['payment_method']?.toString() ?? 'Cash';
                                          final classification = _determineClassification(sale);
                                          final isOnline = classification == 'Online';
                                          final totalAmt = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
                                          final timeStr = sale['created_at']?.toString().replaceAll('T', ' ').split('.').first ?? 'Today';

                                          return animatedDataRow(
                                            isHighlighted: isHighlighted,
                                            cells: [
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(invoiceNum, style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                                    Text(receiptNum, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(custStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isOnline ? const Color(0xFFEEF2FF) : const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(color: isOnline ? const Color(0xFFC7D2FE) : const Color(0xFFBAE6FD)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isOnline ? Icons.language_rounded : Icons.storefront_rounded,
                                                      size: 12,
                                                      color: isOnline ? const Color(0xFF4338CA) : const Color(0xFF0369A1),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      classification.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isOnline ? const Color(0xFF4338CA) : const Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: payMethod.toLowerCase().contains('gcash') ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  payMethod.toUpperCase(),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: payMethod.toLowerCase().contains('gcash') ? const Color(0xFF075985) : const Color(0xFF166534)),
                                                ),
                                              )),
                                              DataCell(Text('₱${totalAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                              DataCell(Text(timeStr, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => ReceiptDetailsDialog(sale: sale),
                                                        );
                                                      },
                                                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                                      label: const Text('View Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF0284C7),
                                                        foregroundColor: Colors.white,
                                                        elevation: 0,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    IconButton(
                                                      onPressed: () {
                                                        PrintHelper.printReceipt(sale);
                                                        SweetAlert.showToast(
                                                          'Official Invoice & Receipt sent to printer!',
                                                          type: SweetAlertType.success,
                                                          title: 'Printing Receipt',
                                                        );
                                                      },
                                                      icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF0284C7)),
                                                      tooltip: 'Print Receipt',
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: const Color(0xFFE0F2FE),
                                                        padding: const EdgeInsets.all(8),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
