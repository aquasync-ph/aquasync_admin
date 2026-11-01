import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class GallonHistoryDialog extends StatelessWidget {
  final String gallonId;
  final String gallonCode;

  const GallonHistoryDialog({
    super.key,
    required this.gallonId,
    required this.gallonCode,
  });

  Color _getActionColor(String action) {
    final act = action.toUpperCase();
    if (act.contains('RETIRED') || act.contains('DAMAGED') || act.contains('LOST')) {
      return const Color(0xFFFCA5A5);
    } else if (act.contains('RESTORED') || act.contains('AVAILABLE') || act.contains('RETURNED')) {
      return const Color(0xFF34D399);
    } else if (act.contains('BORROWED') || act.contains('OUT')) {
      return const Color(0xFF38BDF8);
    }
    return const Color(0xFFBAE6FD);
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
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x330284C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x4038BDF8)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gallon Transaction History',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'Container Code: $gallonCode',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                // CONTENT
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseService.fetchGallonHistory(gallonId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                      }
                      final history = snapshot.data ?? [];
                      if (history.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No transaction history recorded for this container.',
                              style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final actionStr = item['action']?.toString().toUpperCase() ?? item['transaction_type']?.toString().toUpperCase() ?? 'UPDATE';
                          final notesStr = item['notes']?.toString() ?? 'Status update recorded';
                          final createdStr = item['created_at']?.toString() ?? '';
                          final timeFormat = createdStr.contains('T') ? createdStr.replaceAll('T', ' ').split('.').first : createdStr;

                          String customerName = '';
                          if (item['profiles'] != null && item['profiles'] is Map) {
                            customerName = item['profiles']['full_name']?.toString() ?? '';
                          }

                          final actionColor = _getActionColor(actionStr);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: actionColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: actionColor.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                    ),
                                    if (index < history.length - 1)
                                      Container(width: 2, height: 56, color: Colors.white.withValues(alpha: 0.18)),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: actionColor.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                actionStr,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: actionColor),
                                              ),
                                            ),
                                            Text(
                                              timeFormat,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          notesStr,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                        if (customerName.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF38BDF8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Customer / Assigned: $customerName',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // FOOTER ACTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
