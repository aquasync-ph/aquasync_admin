import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import '../../dialogs/dialogs.dart';

class ProductsPage extends StatefulWidget {
  final List<ProductModel> products;
  final VoidCallback onAddProduct;
  final Function(ProductModel) onEditProduct;
  final VoidCallback onRefresh;

  const ProductsPage({
    super.key,
    required this.products,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onRefresh,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _showArchived = false;
  bool _isGridView = true;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  List<ProductModel> get _filteredProducts {
    final list = widget.products.where((p) => p.isActive == !_showArchived).toList();
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();
  }

  void _showProductDetails(ProductModel prod) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: prod,
        onEdit: () => widget.onEditProduct(prod),
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

  void _toggleAvailability(ProductModel prod) async {
    final newStatus = !prod.isAvailable;
    try {
      await SupabaseService.toggleProductAvailability(id: prod.id, isAvailable: newStatus);
      widget.onRefresh();
      SweetAlert.showGlobalSuccess(
        '"${prod.name}" status set to ${newStatus ? 'AVAILABLE' : 'NOT AVAILABLE'}.',
      );
    } catch (e) {
      SweetAlert.showGlobalError('Failed to change status: $e');
    }
  }

  void _confirmArchive(ProductModel prod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Product Master?'),
        content: Text('Are you sure you want to archive "${prod.name}"? It will be hidden from User ordering and Cashier POS active catalogs.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProductActiveStatus(id: prod.id, isActive: false);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${prod.name}" moved to archived products.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to archive: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Archive Product'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(ProductModel prod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Archived Product?'),
        content: Text('Restore "${prod.name}" back to the active catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.toggleProductActiveStatus(id: prod.id, isActive: true);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${prod.name}" restored to active catalog.');
              } catch (e) {
                SweetAlert.showGlobalError('Failed to restore: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Restore Product'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(ProductModel prod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Product?'),
        content: Text('Are you sure you want to PERMANENTLY delete "${prod.name}"? This action CANNOT be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteProduct(prod.id);
                widget.onRefresh();
                SweetAlert.showGlobalSuccess('"${prod.name}" permanently deleted.');
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

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search product by name, category, description, or ID...',
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

  Widget _buildProductCard(ProductModel prod) {
    String desc = prod.description.trim();
    if (desc.length > 100) {
      desc = '${desc.substring(0, 100)}...';
    }

    return AppGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showProductDetails(prod),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image & Badge Header
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: prod.imageUrl != null && prod.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      prod.imageUrl!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: 180,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFBAE6FD)),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFFBAE6FD)),
                                    ),
                            ),
                          ),
                          // Category Badge (Top Left)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xEE082A45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x6638BDF8)),
                              ),
                              child: Text(
                                prod.category.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          // Availability Toggle Button Badge (Top Right)
                          if (!_showArchived)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleAvailability(prod),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: prod.isAvailable ? const Color(0xEE059669) : const Color(0xEED97706),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          prod.isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          prod.isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Body Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      prod.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '₱${prod.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (desc.isNotEmpty) ...[
                                Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                                ),
                              ] else ...[
                                const Text(
                                  'No description provided.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                                ),
                              ],
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ID: ${prod.id.length >= 8 ? prod.id.substring(0, 8) : prod.id}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                  if (_showArchived)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFF59E0B)),
                                      ),
                                      child: const Text('ARCHIVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    // Action Buttons
                    !_showArchived
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => widget.onEditProduct(prod),
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmArchive(prod),
                                  icon: const Icon(Icons.archive_outlined, size: 16),
                                  label: const Text('Archive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmRestore(prod),
                                  icon: const Icon(Icons.unarchive_outlined, size: 16),
                                  label: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmDeletePermanently(prod),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                                  label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTableView(List<ProductModel> filtered) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          headingRowHeight: 52,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('PRODUCT ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('IMAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('PRICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('AVAILABILITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('DESCRIPTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
            DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
          ],
          rows: filtered.map((prod) {
            String desc = prod.description.trim();
            if (desc.length > 100) desc = '${desc.substring(0, 100)}...';

            return DataRow(
              cells: [
                DataCell(Text(prod.id.length >= 8 ? prod.id.substring(0, 8) : prod.id, style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                DataCell(
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    child: prod.imageUrl != null && prod.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.network(
                                prod.imageUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_rounded, size: 20, color: Color(0xFF0284C7)),
                              ),
                            ),
                          )
                        : const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF0284C7)),
                  ),
                ),
                DataCell(Text(prod.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                DataCell(Text(prod.category, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                DataCell(Text('₱${prod.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                DataCell(
                  !_showArchived
                      ? ElevatedButton.icon(
                          onPressed: () => _toggleAvailability(prod),
                          icon: Icon(prod.isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded, size: 14),
                          label: Text(prod.isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: prod.isAvailable ? const Color(0xFF059669) : const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : const Text('—', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      desc.isNotEmpty ? desc : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                DataCell(
                  !_showArchived
                      ? Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => widget.onEditProduct(prod),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmArchive(prod),
                              icon: const Icon(Icons.archive_outlined, size: 16),
                              label: const Text('Archive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _confirmRestore(prod),
                              icon: const Icon(Icons.unarchive_outlined, size: 16),
                              label: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmDeletePermanently(prod),
                              icon: const Icon(Icons.delete_forever_rounded, size: 16),
                              label: const Text('Delete Permanently', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <ProductModel>[]
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

    int totalProducts = widget.products.length;
    int availableProducts = widget.products.where((p) => p.isActive && p.isAvailable).length;
    int unavailableProducts = widget.products.where((p) => p.isActive && !p.isAvailable).length;
    int archivedProducts = widget.products.where((p) => !p.isActive).length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Catalog', value: '$totalProducts', icon: Icons.inventory_2_outlined, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Available Products', value: '$availableProducts', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Unavailable Products', value: '$unavailableProducts', icon: Icons.pause_circle_outline_rounded, color: const Color(0xFFFCA5A5))),
              const SizedBox(width: 14),
              Expanded(child: _buildSummaryCard(label: 'Archived Catalog', value: '$archivedProducts', icon: Icons.archive_outlined, color: const Color(0xFFFCD34D))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total Catalog', value: '$totalProducts', icon: Icons.inventory_2_outlined, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Available', value: '$availableProducts', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF34D399))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Unavailable', value: '$unavailableProducts', icon: Icons.pause_circle_outline_rounded, color: const Color(0xFFFCA5A5))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Archived', value: '$archivedProducts', icon: Icons.archive_outlined, color: const Color(0xFFFCD34D))),
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
                  Text('Product Catalog', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                  SizedBox(height: 4),
                  Text('Products available for User Ordering & Cashier POS in public.products.', style: TextStyle(fontSize: 13, color: Color(0xFF5A5E63))),
                ],
              ),
              Row(
                children: [
                  // View mode toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F3FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5A5E63).withValues(alpha: 0.3)),
                    ),
                    child: Row(
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
                  const SizedBox(width: 12),
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
                    onPressed: widget.onAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            child: filtered.isEmpty
                ? ClipRRect(
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
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            _showArchived ? 'No archived products.' : 'No active products matching search.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ),
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
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              mainAxisExtent: 390,
                            ),
                            itemBuilder: (context, index) => _buildProductCard(paginated[index]),
                          );
                        },
                      )
                    : ClipRRect(
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
                            child: _buildTableView(paginated),
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
