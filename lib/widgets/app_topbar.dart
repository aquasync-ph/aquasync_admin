import 'package:flutter/material.dart';

class AppTopbar extends StatelessWidget {
  final bool isDesktop;
  final int selectedPageIndex;
  final String adminName;
  final VoidCallback onRefresh;
  final int unreadNotificationCount;
  final VoidCallback? onOpenNotifications;

  const AppTopbar({
    super.key,
    required this.isDesktop,
    required this.selectedPageIndex,
    required this.adminName,
    required this.onRefresh,
    this.unreadNotificationCount = 0,
    this.onOpenNotifications,
  });

  String get _formattedCurrentDate {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    String dayName = days[now.weekday - 1];
    String monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}, ${now.year}';
  }

  String get _userInitials {
    final parts = adminName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AP';
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Dashboard Overview',
      'Orders & Deliveries Management',
      'Live Map Tracking',
      'Announcements',
      'Customer Reviews & Feedback',
      'Account Management',
      'Loyalty / RFID Cards',
      'Product Catalog',
      'Gallons & QR Registry',
      'Promo Codes & Discounts',
      'POS & Sales Analytics',
      'System & Station Settings',
    ];

    String headerTitle = selectedPageIndex < titles.length
        ? titles[selectedPageIndex]
        : 'Admin Control';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 680;
        final isVeryCompact = availableWidth < 480;

        return Container(
          height: 82,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Color(0xFF0098DA), size: 26),
                    onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B1D2A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0098DA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formattedCurrentDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF0098DA), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh button with modern container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0098DA), size: 22),
                      onPressed: onRefresh,
                      tooltip: 'Sync / Refresh System Data',
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Notification Bell Bar Button with Unread Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onOpenNotifications,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: unreadNotificationCount > 0
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                                  : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: unreadNotificationCount > 0
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.35),
                                width: unreadNotificationCount > 0 ? 1.5 : 1.0,
                              ),
                            ),
                            child: Icon(
                              unreadNotificationCount > 0
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_outlined,
                              color: const Color(0xFF0284C7),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      if (unreadNotificationCount > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: unreadNotificationCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: unreadNotificationCount > 9 ? BorderRadius.circular(10) : null,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            alignment: Alignment.center,
                            child: Text(
                              unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Admin Profile Avatar (Larger & High-Tech)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0098DA), Color(0xFF0369A1)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x330098DA), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _userInitials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isDesktop && !isVeryCompact) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 11, color: Color(0xFF0098DA)),
                              SizedBox(width: 4),
                              Text(
                                'Station Admin',
                                style: TextStyle(fontSize: 11, color: Color(0xFF0098DA), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
