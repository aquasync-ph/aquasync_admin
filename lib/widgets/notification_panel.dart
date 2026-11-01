import 'package:flutter/material.dart';
import '../models/models.dart';

class NotificationPanelOverlay extends StatefulWidget {
  final List<SystemNotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onClearAll;
  final Function(String category, String? relatedId, String? targetPage)? onNotificationTap;

  const NotificationPanelOverlay({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    required this.onClearAll,
    this.onNotificationTap,
  });

  static void show(
    BuildContext context, {
    required List<SystemNotificationModel> notifications,
    required Function(String) onMarkAsRead,
    required VoidCallback onMarkAllAsRead,
    required VoidCallback onClearAll,
    Function(String category, String? relatedId, String? targetPage)? onNotificationTap,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'System Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: NotificationPanelOverlay(
              notifications: notifications,
              onMarkAsRead: onMarkAsRead,
              onMarkAllAsRead: onMarkAllAsRead,
              onClearAll: onClearAll,
              onNotificationTap: onNotificationTap,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  State<NotificationPanelOverlay> createState() => _NotificationPanelOverlayState();
}

class _NotificationPanelOverlayState extends State<NotificationPanelOverlay> {
  String _selectedCategory = 'All';
  bool _unreadOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Orders',
    'Deliveries',
    'Gallons',
    'Sales',
    'Accounts',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Orders':
        return const Color(0xFFF59E0B); // Amber
      case 'Deliveries':
        return const Color(0xFF0EA5E9); // Cyan / Blue
      case 'Gallons':
        return const Color(0xFF0284C7); // Sky Blue
      case 'Sales':
        return const Color(0xFF10B981); // Emerald
      case 'Accounts':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF38BDF8);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Orders':
        return Icons.shopping_bag_rounded;
      case 'Deliveries':
        return Icons.local_shipping_rounded;
      case 'Gallons':
        return Icons.water_drop_rounded;
      case 'Sales':
        return Icons.point_of_sale_rounded;
      case 'Accounts':
        return Icons.person_pin_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  int _getCategoryUnreadCount(String category) {
    if (category == 'All') {
      return widget.notifications.where((n) => !n.isRead).length;
    }
    return widget.notifications
        .where((n) => !n.isRead && n.category.toLowerCase() == category.toLowerCase())
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 520 ? 480.0 : screenWidth * 0.92;

    List<SystemNotificationModel> filtered = widget.notifications.where((n) {
      if (_unreadOnly && n.isRead) return false;

      if (_selectedCategory != 'All' &&
          n.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchMsg = n.message.toLowerCase().contains(q);
        final matchCat = n.category.toLowerCase().contains(q);
        final matchRel = (n.relatedId ?? '').toLowerCase().contains(q);
        return matchTitle || matchMsg || matchCat || matchRel;
      }

      return true;
    }).toList();

    final totalUnread = widget.notifications.where((n) => !n.isRead).length;

    return Container(
      width: panelWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF071C2E),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(-8, 0),
          ),
        ],
        border: Border(
          left: BorderSide(color: Color(0x3838BDF8), width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFF0A2640),
                border: Border(bottom: BorderSide(color: Color(0x3838BDF8))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF38BDF8)),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF38BDF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'System Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                totalUnread > 0
                                    ? '$totalUnread unread real-time updates'
                                    : 'All notifications up to date',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFBAE6FD),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close Panel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE0F2FE),
                      hintText: 'Search order #, rider, customer...',
                      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF475569), size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.0)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Category classification filter bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              color: const Color(0xFF061827),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final unreadCount = _getCategoryUnreadCount(cat);
                  final color = _getCategoryColor(cat);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.85)
                            : const Color(0xFF0F2B48),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : const Color(0x3838BDF8),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            size: 13,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFFBAE6FD),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.28)
                                    : color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Action Row: Unread Toggle & Mark All Read
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => setState(() => _unreadOnly = !_unreadOnly),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _unreadOnly,
                            activeColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            onChanged: (val) => setState(() => _unreadOnly = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Unread Only',
                          style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (totalUnread > 0)
                        TextButton.icon(
                          onPressed: () {
                            widget.onMarkAllAsRead();
                            setState(() {});
                          },
                          icon: const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF38BDF8)),
                          label: const Text(
                            'Mark All Read',
                            style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (widget.notifications.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            widget.onClearAll();
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 14, color: Color(0xFFF87171)),
                          label: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 11, color: Color(0xFFF87171)),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x3838BDF8), height: 1),

            // Notification List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2640),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0x3838BDF8)),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 36,
                              color: Color(0xFF7DD3FC),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No notifications found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _unreadOnly
                                ? 'No unread alerts in this classification.'
                                : 'System is quiet. All activity will appear here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final catColor = _getCategoryColor(item.category);
                        final catIcon = _getCategoryIcon(item.category);

                        return Container(
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? const Color(0xFF082238).withValues(alpha: 0.6)
                                : const Color(0xFF0A2F52),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.isRead
                                  ? const Color(0x2238BDF8)
                                  : catColor.withValues(alpha: 0.6),
                              width: item.isRead ? 1 : 1.5,
                            ),
                            boxShadow: item.isRead
                                ? null
                                : [
                                    BoxShadow(
                                      color: catColor.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (!item.isRead) {
                                widget.onMarkAsRead(item.id);
                              }
                              Navigator.of(context).pop();
                              if (widget.onNotificationTap != null) {
                                widget.onNotificationTap!(
                                  item.category,
                                  item.relatedId,
                                  item.targetPage,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Icon Box
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: catColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      catIcon,
                                      color: catColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Category tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: catColor.withValues(alpha: 0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                item.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: catColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  item.timestamp,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                if (!item.isRead) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: catColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFFBAE6FD),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
