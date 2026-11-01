import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class LoyaltyRfidPage extends StatefulWidget {
  final List<CustomerModel> customers;
  final Function(CustomerModel) getGallonsPurchased;
  final Function(CustomerModel) onAssignRfid;
  final Function(CustomerModel) onToggleRfidStatus;
  final VoidCallback onRegisterUnassignedRfid;

  const LoyaltyRfidPage({
    super.key,
    required this.customers,
    required this.getGallonsPurchased,
    required this.onAssignRfid,
    required this.onToggleRfidStatus,
    required this.onRegisterUnassignedRfid,
  });

  @override
  State<LoyaltyRfidPage> createState() => _LoyaltyRfidPageState();
}

class _LoyaltyRfidPageState extends State<LoyaltyRfidPage> {
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<CustomerModel> get _filteredCustomers {
    if (_searchQuery.trim().isEmpty) return widget.customers;
    final q = _searchQuery.toLowerCase().trim();
    return widget.customers.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.rfidUid.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
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
    return TextField(
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search customer name, loyalty RFID UID, phone...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
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

  @override
  Widget build(BuildContext context) {
    final rewardReadyCustomers = widget.customers.where((c) => widget.getGallonsPurchased(c) >= 15).toList();
    final filtered = _filteredCustomers;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <CustomerModel>[]
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

    int totalCustomers = widget.customers.length;
    int rfidAssigned = widget.customers.where((c) => c.rfidUid.isNotEmpty).length;
    int activeCards = widget.customers.where((c) => c.rfidUid.isNotEmpty && c.isRfidActive).length;
    int rewardReady = rewardReadyCustomers.length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Customers', value: '$totalCustomers', icon: Icons.people_outline_rounded, color: const Color(0xFF0284C7))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'RFID Assigned', value: '$rfidAssigned', icon: Icons.badge_outlined, color: const Color(0xFF0284C7))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Active Cards', value: '$activeCards', icon: Icons.credit_card_rounded, color: const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Reward Ready (15+)', value: '$rewardReady', icon: Icons.stars_rounded, color: const Color(0xFFF59E0B))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total Customers', value: '$totalCustomers', icon: Icons.people_outline_rounded, color: const Color(0xFF0284C7))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Assigned', value: '$rfidAssigned', icon: Icons.badge_outlined, color: const Color(0xFF0284C7))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Active Cards', value: '$activeCards', icon: Icons.credit_card_rounded, color: const Color(0xFF10B981))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Reward Ready', value: '$rewardReady', icon: Icons.stars_rounded, color: const Color(0xFFF59E0B))),
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
                  Text('Customer Loyalty / RFID Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('RFID cards identify registered loyal customers. 15 qualifying gallons = Reward Ready.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onRegisterUnassignedRfid,
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('Register Unassigned RFID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
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

          if (rewardReadyCustomers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${rewardReadyCustomers.length} Customer(s) Qualified for Loyalty Reward!', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('Qualified Customers: ${rewardReadyCustomers.map((c) => c.fullName).join(', ')}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: _buildSearchField(),
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
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('No loyalty RFID records found matching search.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
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
                                    columnSpacing: 26,
                                    columns: const [
                                      DataColumn(label: Text('CUSTOMER NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                      DataColumn(label: Text('LOYALTY RFID UID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                      DataColumn(label: Text('CARD STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                      DataColumn(label: Text('GALLONS PURCHASED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                      DataColumn(label: Text('REWARD PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                      DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                    ],
                                    rows: paginated.map((cust) {
                                      final hasRfid = cust.rfidUid.isNotEmpty;
                                      final gallonsPurchased = widget.getGallonsPurchased(cust);
                                      final isRewardReady = gallonsPurchased >= 15;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(cust.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                          DataCell(Text(hasRfid ? cust.rfidUid : 'Not Assigned', style: TextStyle(fontSize: 13, color: hasRfid ? const Color(0xFF0284C7) : const Color(0xFF475569), fontWeight: hasRfid ? FontWeight.bold : FontWeight.normal))),
                                          DataCell(Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: !hasRfid ? const Color(0xFFF1F5F9) : cust.isRfidActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(999)),
                                            child: Text(!hasRfid ? 'UNASSIGNED' : cust.isRfidActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: !hasRfid ? const Color(0xFF475569) : cust.isRfidActive ? const Color(0xFF166534) : const Color(0xFF991B1B))),
                                          )),
                                          DataCell(Text('$gallonsPurchased gallon(s)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                          DataCell(Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isRewardReady ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(999),
                                              border: isRewardReady ? Border.all(color: const Color(0xFF86EFAC)) : null,
                                            ),
                                            child: Text(
                                              isRewardReady ? 'REWARD READY ($gallonsPurchased / 15)' : '$gallonsPurchased / 15 gallons',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isRewardReady ? const Color(0xFF166534) : const Color(0xFF475569)),
                                            ),
                                          )),
                                          DataCell(Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => widget.onAssignRfid(cust),
                                                icon: const Icon(Icons.badge_outlined, size: 16),
                                                label: Text(hasRfid ? 'Reassign RFID' : 'Assign RFID', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0284C7),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                              if (hasRfid) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(cust.isRfidActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18, color: cust.isRfidActive ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
                                                  onPressed: () => widget.onToggleRfidStatus(cust),
                                                  tooltip: cust.isRfidActive ? 'Deactivate Card' : 'Activate Card',
                                                ),
                                              ],
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
