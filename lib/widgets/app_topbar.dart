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
      'Live Map Tracking & Victoria Dispatch',
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
          height: 76,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Color(0xFF0098DA)),
                    onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
                  ),
                ),
                const SizedBox(width: 4),
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
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1D2A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedCurrentDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0098DA), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0098DA), size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Sync / Refresh System Data',
                  ),
                  const SizedBox(width: 4),

                  // Notification Bell Bar Button with Unread Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onOpenNotifications,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: unreadNotificationCount > 0
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.20)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: unreadNotificationCount > 0
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              unreadNotificationCount > 0
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_outlined,
                              color: const Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (unreadNotificationCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: unreadNotificationCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: unreadNotificationCount > 9 ? BorderRadius.circular(10) : null,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            alignment: Alignment.center,
                            child: Text(
                              unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Admin Profile Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x140284C7), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _userInitials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isDesktop && !isVeryCompact) ...[
                    const SizedBox(width: 10),
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'Station Admin',
                            style: TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
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
