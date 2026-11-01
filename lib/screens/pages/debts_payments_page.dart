import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../dialogs/dialogs.dart';
import '../../widgets/widgets.dart';

class DebtsPaymentsPage extends StatefulWidget {
  final List<CustomerModel> customers;
  final List<OrderItemModel> orders;
  final VoidCallback onRefresh;

  const DebtsPaymentsPage({
    super.key,
    required this.customers,
    required this.orders,
    required this.onRefresh,
  });

  @override
  State<DebtsPaymentsPage> createState() => _DebtsPaymentsPageState();
}

class _DebtsPaymentsPageState extends State<DebtsPaymentsPage> {
  int _selectedTab = 0; // 0 = Customer Debts, 1 = Audit Payments (Read-Only)
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<DebtItemModel> _debts = [];
  List<PaymentItemModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rawDebts = await SupabaseService.fetchDebts();
      final rawPayments = await SupabaseService.fetchPayments();

      if (mounted) {
        setState(() {
          _debts = rawDebts.map((m) => DebtItemModel.fromSupabase(m)).toList();
          _payments = rawPayments.map((m) => PaymentItemModel.fromSupabase(m)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DebtItemModel> get _filteredDebts {
    return _debts.where((d) {
      final matchesSearch = d.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d.orderNumber != null && d.orderNumber!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          d.status.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' || d.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<PaymentItemModel> get _filteredPayments {
    return _payments.where((p) {
      return p.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.method.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openAddDebtModal() {
    showDialog(
      context: context,
      builder: (context) => AddDebtDialog(
        customers: widget.customers,
        orders: widget.orders,
        onSuccess: () {
          _loadData();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Customer debt recorded successfully.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to record debt: $err');
        },
      ),
    );
  }

  void _openEditDebtModal(DebtItemModel debt) {
    showDialog(
      context: context,
      builder: (context) => EditDebtDialog(
        debt: debt,
        onSuccess: () {
          _loadData();
          widget.onRefresh();
          SweetAlert.showGlobalSuccess('Debt record updated.');
        },
        onError: (err) {
          SweetAlert.showGlobalError('Failed to update debt: $err');
        },
      ),
    );
  }

  void _confirmMarkAsPaid(DebtItemModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Mark Debt as Fully Paid?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Confirm full payment settlement of ₱${debt.remainingBalance.toStringAsFixed(2)} for ${debt.customerName}?', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.settleDebtFully(debtId: debt.id, remainingBalance: debt.remainingBalance);
                await _loadData();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Debt marked as fully paid and settled.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to update debt: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Confirm Settle Debt'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDebt(DebtItemModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Delete Debt Record?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to delete debt record for "${debt.customerName}"? This action cannot be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteDebt(debt.id);
                await _loadData();
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('Debt record deleted.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to delete debt: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Record'),
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

  Widget _buildSearchField(String hintText) {
    return TextField(
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: hintText,
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

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
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
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Debt Statuses', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'partial', child: Text('Partially Paid', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        DropdownMenuItem(value: 'paid', child: Text('Fully Paid', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    double totalUnpaid = _debts.fold(0.0, (sum, d) => sum + d.remainingBalance);
    int unpaidCount = _debts.where((d) => d.status.toLowerCase() == 'unpaid').length;
    int partialCount = _debts.where((d) => d.status.toLowerCase() == 'partial').length;
    int paidCount = _debts.where((d) => d.status.toLowerCase() == 'paid').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Credit Balance', value: '₱${totalUnpaid.toStringAsFixed(2)}', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFFCA5A5))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Unpaid Accounts', value: '$unpaidCount Accounts', icon: Icons.hourglass_top_rounded, color: const Color(0xFFFCD34D))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Partially Paid', value: '$partialCount Accounts', icon: Icons.payments_outlined, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Fully Settled', value: '$paidCount Accounts', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total Balance', value: '₱${totalUnpaid.toStringAsFixed(2)}', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFFCA5A5))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Unpaid', value: '$unpaidCount', icon: Icons.hourglass_top_rounded, color: const Color(0xFFFCD34D))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Partially Paid', value: '$partialCount', icon: Icons.payments_outlined, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Fully Paid', value: '$paidCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
            ],
          );
        }
      },
    );

    final filteredDebtsList = _filteredDebts;
    final filteredPaymentsList = _filteredPayments;

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedDebts = filteredDebtsList.isEmpty
        ? <DebtItemModel>[]
        : filteredDebtsList.sublist(
            startIndex.clamp(0, filteredDebtsList.length),
            (startIndex + _itemsPerPage).clamp(0, filteredDebtsList.length),
          );
    final paginatedPayments = filteredPaymentsList.isEmpty
        ? <PaymentItemModel>[]
        : filteredPaymentsList.sublist(
            startIndex.clamp(0, filteredPaymentsList.length),
            (startIndex + _itemsPerPage).clamp(0, filteredPaymentsList.length),
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
                  Text('Debts & Customer Credit', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                  SizedBox(height: 4),
                  Text('Track customer credit balances, payment logs, and due dates.', style: TextStyle(fontSize: 13, color: Color(0xFF5A5E63))),
                ],
              ),
              SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF0098DA),
                  selectedForegroundColor: Colors.white,
                  backgroundColor: const Color(0xFFE6F3FA),
                  foregroundColor: const Color(0xFF0B1D2A),
                  side: BorderSide(color: const Color(0xFF5A5E63).withValues(alpha: 0.3)),
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Customer Debts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ButtonSegment(value: 1, label: Text('Audit Payments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (set) => setState(() {
                  _selectedTab = set.first;
                  _currentPage = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          summaryStrip,
          const SizedBox(height: 20),

          if (_selectedTab == 0) ...[
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
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchField('Search by customer, description, order number, or status...')),
                      const SizedBox(width: 12),
                      SizedBox(width: 200, child: _buildStatusDropdown()),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _openAddDebtModal,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Record Debt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                        : filteredDebtsList.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('No customer debt records found.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
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
                                                DataColumn(label: Text('CUSTOMER NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('ORDER #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('ORIGINAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('PAID AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('REMAINING BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('DUE DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                              ],
                                              rows: paginatedDebts.map((debt) {
                                                final isFullyPaid = debt.status.toLowerCase() == 'paid' || debt.remainingBalance <= 0;

                                                Color badgeBg = const Color(0xFFFEF3C7);
                                                Color badgeFg = const Color(0xFF92400E);
                                                if (isFullyPaid) {
                                                  badgeBg = const Color(0xFFDCFCE7);
                                                  badgeFg = const Color(0xFF166534);
                                                } else if (debt.status.toLowerCase() == 'partial' || debt.status.toLowerCase() == 'partially_paid') {
                                                  badgeBg = const Color(0xFFE0F2FE);
                                                  badgeFg = const Color(0xFF0369A1);
                                                }

                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(debt.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                                    DataCell(Text(debt.orderNumber ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                                                    DataCell(SizedBox(
                                                      width: 180,
                                                      child: Text(debt.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                                    )),
                                                    DataCell(Text('₱${debt.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
                                                    DataCell(Text('₱${debt.paidAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.bold))),
                                                    DataCell(Text('₱${debt.remainingBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)))),
                                                    DataCell(Text(debt.dueDate, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                                    DataCell(Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                                                      child: Text(debt.status.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeFg)),
                                                    )),
                                                    DataCell(Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (!isFullyPaid) ...[
                                                          ElevatedButton.icon(
                                                            onPressed: () => _confirmMarkAsPaid(debt),
                                                            icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                                            label: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF10B981),
                                                              foregroundColor: Colors.white,
                                                              elevation: 0,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                        ],
                                                        ElevatedButton.icon(
                                                          onPressed: () => _openEditDebtModal(debt),
                                                          icon: const Icon(Icons.edit_rounded, size: 14),
                                                          label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFD97706),
                                                            foregroundColor: Colors.white,
                                                            elevation: 0,
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        ElevatedButton.icon(
                                                          onPressed: () => _confirmDeleteDebt(debt),
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
              ),
            ),
            if (filteredDebtsList.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppPaginationControls(
                totalItems: filteredDebtsList.length,
                currentPage: _currentPage,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
                onItemsPerPageChanged: (perPage) => setState(() {
                  _itemsPerPage = perPage;
                  _currentPage = 1;
                }),
              ),
            ],
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchField('Search payment by order #, customer, or reference #...')),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF7DD3FC)),
                            SizedBox(width: 6),
                            Text('Read-Only Audit Stream', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                        : filteredPaymentsList.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('No payment records found.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
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
                                                DataColumn(label: Text('ORDER NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('PAYMENT METHOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('REFERENCE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('PAYMENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('PAID DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                                DataColumn(label: Text('RECORDED AT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                              ],
                                              rows: paginatedPayments.map((payment) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(payment.orderNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                                                    DataCell(Text(payment.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                                    DataCell(Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: payment.method.toLowerCase().contains('gcash') ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                                                            borderRadius: BorderRadius.circular(999),
                                                          ),
                                                          child: Text(
                                                            payment.method.toUpperCase(),
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: payment.method.toLowerCase().contains('gcash') ? const Color(0xFF0369A1) : const Color(0xFF166534)),
                                                          ),
                                                        ),
                                                        if (payment.receiptUrl.isNotEmpty) ...[
                                                          const SizedBox(height: 3),
                                                          InkWell(
                                                            onTap: () => showFullReceiptImageDialog(
                                                              context,
                                                              payment.receiptUrl,
                                                              orderNumber: payment.orderNumber,
                                                              referenceNumber: payment.referenceNumber,
                                                            ),
                                                            borderRadius: BorderRadius.circular(4),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                                              ),
                                                              child: const Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(Icons.image_outlined, size: 12, color: Color(0xFF059669)),
                                                                  SizedBox(width: 3),
                                                                  Text('View Receipt', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    )),
                                                    DataCell(Text('₱${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                                    DataCell(Text(payment.referenceNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                                    DataCell(Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(999)),
                                                      child: Text(payment.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                                    )),
                                                    DataCell(Text(payment.paidAt, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                                    DataCell(Text(payment.createdAt, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
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
            if (filteredPaymentsList.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppPaginationControls(
                totalItems: filteredPaymentsList.length,
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
        ],
      ),
    );
  }
}
