import 'dart:ui';
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
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 280),
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

  // 60-30-10 Color Architecture Category Accent Mapping
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Orders':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'Deliveries':
        return const Color(0xFF0EA5E9); // Electric Cyan
      case 'Gallons':
        return const Color(0xFF3B82F6); // Royal Blue
      case 'Sales':
        return const Color(0xFF10B981); // Emerald Green
      case 'Accounts':
        return const Color(0xFF8B5CF6); // iOS Purple
      default:
        return const Color(0xFF0A84FF); // iOS System Blue
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
        return Icons.person_rounded;
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
    final panelWidth = screenWidth > 540 ? 460.0 : screenWidth * 0.92;

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

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: panelWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            // 60% Base Canvas Color (iOS Deep Translucent Glass Canvas)
            color: const Color(0xFF0B132B).withValues(alpha: 0.94),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 40,
                spreadRadius: 4,
                offset: Offset(-16, 0),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // iOS Sheet Header & Top Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 16),
                  decoration: BoxDecoration(
                    // 30% Surface Color
                    color: const Color(0xFF131C2E).withValues(alpha: 0.85),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // iOS Drag Grabber Bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),

                      // Title & Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // 10% Accent Glass Badge
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0A84FF), Color(0xFF00C6FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0A84FF).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'System Notifications',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: totalUnread > 0
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF64748B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        totalUnread > 0
                                            ? '$totalUnread unread real-time updates'
                                            : 'All notifications up to date',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: totalUnread > 0
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // iOS Glass Close Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // iOS Glass Search Input Field (30% Surface Fill)
                      TextField(
                        controller: _searchController,
                        cursorColor: const Color(0xFF0A84FF),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B).withValues(alpha: 0.75),
                          hintText: 'Search order #, rider, customer...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF0A84FF),
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: Color(0xFF64748B),
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A84FF),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // iOS Horizontal Category Segmented Pill Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: const Color(0xFF0E1627).withValues(alpha: 0.9),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final unreadCount = _getCategoryUnreadCount(cat);
                        final catColor = _getCategoryColor(cat);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                                decoration: BoxDecoration(
                                  // 10% Accent Fill when Active
                                  color: isSelected
                                      ? (cat == 'All' ? const Color(0xFF0A84FF) : catColor)
                                      : const Color(0xFF1E293B).withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (cat == 'All' ? const Color(0xFF0A84FF) : catColor)
                                                .withValues(alpha: 0.38),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(cat),
                                      size: 13.5,
                                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    if (unreadCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.28)
                                              : catColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // iOS Sub-Bar: Unread Toggle & Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Modern iOS Toggle Switch
                      InkWell(
                        onTap: () => setState(() => _unreadOnly = !_unreadOnly),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 18,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _unreadOnly
                                      ? const Color(0xFF0A84FF)
                                      : const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: _unreadOnly
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Unread Only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFCBD5E1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Action Buttons
                      Row(
                        children: [
                          if (totalUnread > 0)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                widget.onMarkAllAsRead();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 14,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Mark All Read',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (totalUnread > 0 && widget.notifications.isNotEmpty)
                            const SizedBox(width: 8),
                          if (widget.notifications.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                widget.onClearAll();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.delete_sweep_rounded,
                                      size: 14,
                                      color: Color(0xFFF87171),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFF87171),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Notification ListView Card Stream
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 40,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No notifications found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _unreadOnly
                                      ? 'No unread alerts in this classification.'
                                      : 'System is quiet. All activity will appear here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final catColor = _getCategoryColor(item.category);
                            final catIcon = _getCategoryIcon(item.category);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    // 30% Surface Color (Elevated Glass Tiles)
                                    color: item.isRead
                                        ? const Color(0xFF0F172A).withValues(alpha: 0.45)
                                        : const Color(0xFF162032).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: item.isRead
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : catColor.withValues(alpha: 0.35),
                                      width: item.isRead ? 1.0 : 1.2,
                                    ),
                                    boxShadow: item.isRead
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: catColor.withValues(alpha: 0.14),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Unread Accent Stripe Indicator
                                      if (!item.isRead)
                                        Container(
                                          width: 4,
                                          height: 42,
                                          margin: const EdgeInsets.only(right: 10, top: 2),
                                          decoration: BoxDecoration(
                                            color: catColor,
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: catColor.withValues(alpha: 0.6),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Category Avatar Icon Box
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: item.isRead ? 0.12 : 0.20),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: catColor.withValues(alpha: item.isRead ? 0.25 : 0.45),
                                            width: 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          catIcon,
                                          color: item.isRead
                                              ? catColor.withValues(alpha: 0.7)
                                              : catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Notification Body
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header Tag & Timestamp Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Category Tag Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: catColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: catColor.withValues(alpha: 0.35),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.category.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: catColor,
                                                      letterSpacing: 0.6,
                                                    ),
                                                  ),
                                                ),

                                                // Timestamp & Pulsing Unread Indicator
                                                Row(
                                                  children: [
                                                    Text(
                                                      item.timestamp,
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                    ),
                                                    if (!item.isRead) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        width: 7,
                                                        height: 7,
                                                        decoration: BoxDecoration(
                                                          color: catColor,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: catColor.withValues(alpha: 0.6),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 7),

                                            // Title Text
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: item.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: item.isRead
                                                    ? const Color(0xFFE2E8F0)
                                                    : Colors.white,
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Subtitle Message Text
                                            Text(
                                              item.message,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w400,
                                                color: item.isRead
                                                    ? const Color(0xFF64748B)
                                                    : const Color(0xFF94A3B8),
                                                height: 1.35,
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
        ),
      ),
    );
  }
}
