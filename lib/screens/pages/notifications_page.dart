import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class NotificationsPage extends StatefulWidget {
  final List<SystemNotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onClearAll;
  final VoidCallback onRefresh;
  final Function(String category, String? relatedId, String? targetPage)? onNotificationTap;

  const NotificationsPage({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    required this.onClearAll,
    required this.onRefresh,
    this.onNotificationTap,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'All';
  bool _unreadOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;

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
        return const Color(0xFFF59E0B);
      case 'Deliveries':
        return const Color(0xFF0EA5E9);
      case 'Gallons':
        return const Color(0xFF0284C7);
      case 'Sales':
        return const Color(0xFF10B981);
      case 'Accounts':
        return const Color(0xFF8B5CF6);
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

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <SystemNotificationModel>[]
        : filtered.sublist(
            startIndex.clamp(0, filtered.length),
            (startIndex + _itemsPerPage).clamp(0, filtered.length),
          );

    final totalUnread = widget.notifications.where((n) => !n.isRead).length;

    return Container(
      color: const Color(0xFF03182B),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Title & Control Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF082D4F), Color(0xFF041A2E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x3838BDF8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF38BDF8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'System Activity & Live Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time event stream across orders, rider deliveries, sales, and gallon inventory',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: widget.onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh Feed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (totalUnread > 0) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onMarkAllAsRead();
                              setState(() {});
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: const Text('Mark All Read'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0369A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _currentPage = 1;
                        }),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFE0F2FE),
                          hintText: 'Search order number, rider name, customer, status...',
                          hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Color(0xFF475569), size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _currentPage = 1;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.0)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => setState(() {
                        _unreadOnly = !_unreadOnly;
                        _currentPage = 1;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _unreadOnly
                              ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _unreadOnly
                                ? const Color(0xFF38BDF8)
                                : const Color(0x3838BDF8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _unreadOnly,
                              activeColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              onChanged: (val) => setState(() {
                                _unreadOnly = val ?? false;
                                _currentPage = 1;
                              }),
                            ),
                            const Text(
                              'Unread Only',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
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
          const SizedBox(height: 16),

          // Classification Category Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              final unreadCount = _getCategoryUnreadCount(cat);
              final color = _getCategoryColor(cat);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _currentPage = 1;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.85)
                        : const Color(0xFF0B2945),
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
                        size: 15,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFFBAE6FD),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.28)
                                : color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              fontSize: 10,
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
          const SizedBox(height: 16),

          // Notifications Feed
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF082642),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x3838BDF8)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No System Notifications Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _unreadOnly
                                ? 'There are no unread notifications matching your selected classification filter.'
                                : 'All quiet! System operations and rider delivery updates will populate here automatically.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: paginated.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = paginated[index];
                      final catColor = _getCategoryColor(item.category);
                      final catIcon = _getCategoryIcon(item.category);

                      return Container(
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? const Color(0xFF072138).withValues(alpha: 0.7)
                              : const Color(0xFF0A3052),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isRead
                                ? const Color(0x3838BDF8)
                                : catColor.withValues(alpha: 0.8),
                            width: item.isRead ? 1.0 : 1.5,
                          ),
                          boxShadow: item.isRead
                              ? null
                              : [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (!item.isRead) {
                              widget.onMarkAsRead(item.id);
                            }
                            if (widget.onNotificationTap != null) {
                              widget.onNotificationTap!(
                                item.category,
                                item.relatedId,
                                item.targetPage,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Icon Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: catColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    catIcon,
                                    color: catColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Notification Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: catColor.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  item.category.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: catColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              if (item.targetPage != null) ...[
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 14,
                                                  color: Color(0xFF38BDF8),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                item.timestamp,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                              if (!item.isRead) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 10,
                                                  height: 10,
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
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFFBAE6FD),
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
