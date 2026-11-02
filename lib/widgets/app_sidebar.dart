import 'package:flutter/material.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final int pendingCount;
  final int driversCount;
  final int customersCount;
  final int productsCount;
  final int unreadNotificationCount;
  final Function(int) onNavigate;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.pendingCount,
    required this.driversCount,
    required this.customersCount,
    required this.productsCount,
    this.unreadNotificationCount = 0,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, bool> _expandedSections = {
    'CORE OPERATIONS': true,
    'ASSET MANAGEMENT': true,
    'MARKETING & ENGAGEMENT': true,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildNavCategoryHeader(String title, double paddingTop, double paddingBottom) {
    return Padding(
      padding: EdgeInsets.only(left: 10, right: 10, top: paddingTop, bottom: paddingBottom),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Color(0xFF38BDF8),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required double verticalPadding,
    required double marginBottom,
    required double iconSize,
    required double fontSize,
    int? badgeCount,
    bool isNewBadge = false,
  }) {
    if (_searchQuery.trim().isNotEmpty) {
      if (!title.toLowerCase().contains(_searchQuery.toLowerCase().trim())) {
        return const SizedBox.shrink();
      }
    }

    final isActive = widget.selectedIndex == index;
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            widget.onNavigate(index);
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF0098DA), Color(0xFF0284C7)],
                    )
                  : null,
              color: isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0098DA).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: iconSize + 2, // Larger icons as requested
                  color: isActive ? Colors.white : const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1.2,
                            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                            color: isActive ? Colors.white : const Color(0xFFF0F9FF),
                          ),
                        ),
                      ),
                      if (isNewBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0B1D2A)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF041E38) : const Color(0xFF0098DA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required double verticalPadding,
    required double fontSize,
  }) {
    final isExpanded = _expandedSections[title] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF041E38).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              setState(() {
                _expandedSections[title] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF38BDF8),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        double verticalPadding = 10.0;
        double iconSize = 19.0;
        double fontSize = 12.0;
        double itemMarginBottom = 6.0;
        double sidePadding = 18.0;
        double logoutPaddingVertical = 14.0;

        final headerWidget = Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14, left: 2, right: 2),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0098DA), Color(0xFF38BDF8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x400098DA), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AquaSync',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'ADMIN CONTROL CENTER',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFFBAE6FD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick Search bar
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF041E38).withValues(alpha: 0.8),
                  hintText: 'Quick Search Navigation',
                  hintStyle: TextStyle(color: const Color(0xFF7DD3FC).withValues(alpha: 0.7), fontSize: fontSize),
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF38BDF8), size: iconSize + 2),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: const Color(0xFF38BDF8), size: iconSize),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x3838BDF8), width: 1.2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x3838BDF8), width: 1.2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const Divider(color: Color(0x3838BDF8), height: 1.5),
            const SizedBox(height: 12),
          ],
        );

        final logoutButton = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0098DA), width: 1.5),
                backgroundColor: const Color(0xFF0098DA).withValues(alpha: 0.18),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: logoutPaddingVertical),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: const Color(0xFF38BDF8), size: iconSize + 2),
                  const SizedBox(width: 12),
                  Text('Logout Session', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        );

        return Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF061A2B),
                Color(0xFF0B253D),
                Color(0xFF04121F),
              ],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerWidget,
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // OVERVIEW
                      _buildNavCategoryHeader('OVERVIEW', 2, 6),
                      _buildNavItem(context: context, index: 0, icon: Icons.grid_view_rounded, title: 'Dashboard', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),

                      const SizedBox(height: 8),

                      // CORE OPERATIONS
                      _buildSectionCard(
                        title: 'CORE OPERATIONS',
                        verticalPadding: verticalPadding,
                        fontSize: fontSize,
                        children: [
                          _buildNavItem(context: context, index: 1, icon: Icons.local_shipping_rounded, title: 'Orders & Deliveries', badgeCount: widget.pendingCount > 0 ? widget.pendingCount : null, verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 2, icon: Icons.map_rounded, title: 'Live Map & Geofence', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                        ],
                      ),

                      // ASSET MANAGEMENT
                      _buildSectionCard(
                        title: 'ASSET MANAGEMENT',
                        verticalPadding: verticalPadding,
                        fontSize: fontSize,
                        children: [
                          _buildNavCategoryHeader('INVENTORY', 2, 4),
                          _buildNavItem(context: context, index: 7, icon: Icons.inventory_2_rounded, title: 'Products (${widget.productsCount})', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 8, icon: Icons.local_drink_rounded, title: 'Gallons & QR Registry', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavCategoryHeader('STAFF & USERS', 8, 4),
                          _buildNavItem(context: context, index: 5, icon: Icons.manage_accounts_rounded, title: 'Account Management', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                        ],
                      ),

                      // MARKETING & ENGAGEMENT
                      _buildSectionCard(
                        title: 'MARKETING & ENGAGEMENT',
                        verticalPadding: verticalPadding,
                        fontSize: fontSize,
                        children: [
                          _buildNavItem(context: context, index: 9, icon: Icons.local_offer_rounded, title: 'Promo Codes & Coupons', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 6, icon: Icons.credit_card_rounded, title: 'Loyalty / RFID Cards', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 4, icon: Icons.rate_review_rounded, title: 'Customer Reviews', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 3, icon: Icons.campaign_rounded, title: 'Announcements', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                        ],
                      ),

                      // FINANCE
                      _buildNavCategoryHeader('FINANCE', 6, 6),
                      _buildNavItem(context: context, index: 10, icon: Icons.insights_rounded, title: 'Sales & Revenue', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),

                      // SYSTEM
                      _buildNavCategoryHeader('SYSTEM', 10, 6),
                      _buildNavItem(context: context, index: 11, icon: Icons.settings_rounded, title: 'Settings', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                    ],
                  ),
                ),
              ),
              logoutButton,
            ],
          ),
        );
      },
    );
  }
}
