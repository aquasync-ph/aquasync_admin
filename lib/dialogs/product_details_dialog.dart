import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';

class ProductDetailsDialog extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    this.onEdit,
  });

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DD3FC),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: const Color(0xFA082A45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3838BDF8), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x3338BDF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x6638BDF8)),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Added on ${product.createdAt}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBAE6FD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFFBAE6FD)),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Large Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 260,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 260,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFBAE6FD)),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFBAE6FD)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
                  const SizedBox(height: 20),
                  
                  _buildInfoRow('PRODUCT NAME', product.name, Icons.label_outline_rounded),
                  Row(
                    children: [
                      Expanded(child: _buildInfoRow('CATEGORY', product.category.toUpperCase(), Icons.category_outlined)),
                      Expanded(child: _buildInfoRow('PRICE', '₱${product.price.toStringAsFixed(2)}', Icons.payments_outlined, valueColor: const Color(0xFF38BDF8))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          'AVAILABILITY',
                          product.isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE',
                          product.isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                          valueColor: product.isAvailable ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          'STATUS',
                          product.isActive ? 'ACTIVE' : 'ARCHIVED',
                          product.isActive ? Icons.visibility_outlined : Icons.archive_outlined,
                          valueColor: product.isActive ? const Color(0xFF34D399) : const Color(0xFFFCD34D),
                        ),
                      ),
                    ],
                  ),
                  _buildInfoRow('PRODUCT ID', product.id, Icons.fingerprint_rounded),

                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7DD3FC),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Text(
                      product.description.trim().isEmpty ? 'No description provided.' : product.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: product.description.trim().isEmpty ? const Color(0xFF93C5FD) : Colors.white,
                        fontStyle: product.description.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onEdit!();
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
