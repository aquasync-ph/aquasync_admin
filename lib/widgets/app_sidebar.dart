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
      padding: EdgeInsets.only(left: 8, right: 8, top: paddingTop, bottom: paddingBottom),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Color(0xFF7DD3FC),
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
        color: isActive ? const Color(0xFF0098DA) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            widget.onNavigate(index);
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: verticalPadding),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: isActive ? Colors.white : const Color(0xFF7DD3FC),
                ),
                const SizedBox(width: 10),
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
                            height: 1.15,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? Colors.white : const Color(0xFFE0F2FE),
                          ),
                        ),
                      ),
                      if (isNewBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF075985) : const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF041E38).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3838BDF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              setState(() {
                _expandedSections[title] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.9,
                      color: Color(0xFF7DD3FC),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF7DD3FC),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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

        double verticalPadding;
        double iconSize;
        double fontSize;
        double itemMarginBottom;
        double sidePadding;
        double logoutPaddingVertical;

        if (availableHeight >= 760) {
          verticalPadding = 9.0;
          iconSize = 17.0;
          fontSize = 11.5;
          itemMarginBottom = 4.0;
          sidePadding = 16.0;
          logoutPaddingVertical = 12.0;
        } else if (availableHeight >= 700) {
          verticalPadding = 7.5;
          iconSize = 16.5;
          fontSize = 11.0;
          itemMarginBottom = 3.0;
          sidePadding = 14.0;
          logoutPaddingVertical = 10.0;
        } else {
          verticalPadding = 5.5;
          iconSize = 15.5;
          fontSize = 10.5;
          itemMarginBottom = 2.0;
          sidePadding = 12.0;
          logoutPaddingVertical = 8.0;
        }

        final headerWidget = Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: availableHeight < 700 ? 8 : 12, left: 2, right: 2),
              child: Row(
                children: [
                  Container(
                    width: availableHeight < 700 ? 34 : 40,
                    height: availableHeight < 700 ? 34 : 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: const Color(0xFF0284C7),
                      size: availableHeight < 700 ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AquaSync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ADMIN CONTROL CENTER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
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
              margin: EdgeInsets.only(bottom: availableHeight < 700 ? 8 : 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF041E38).withValues(alpha: 0.6),
                  hintText: 'Quick Search',
                  hintStyle: TextStyle(color: const Color(0xFF7DD3FC).withValues(alpha: 0.7), fontSize: fontSize),
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF7DD3FC), size: iconSize),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: const Color(0xFF7DD3FC), size: iconSize - 2),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x3838BDF8), width: 1.0)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x3838BDF8), width: 1.0)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            const Divider(color: Color(0x3838BDF8), height: 1),
            SizedBox(height: availableHeight < 700 ? 6 : 10),
          ],
        );

        final logoutButton = Padding(
          padding: EdgeInsets.only(top: availableHeight < 700 ? 6 : 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x3838BDF8)),
                backgroundColor: const Color(0x1A0284C7),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: logoutPaddingVertical),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: const Color(0xFF7DD3FC), size: iconSize),
                  const SizedBox(width: 10),
                  Text('Logout Session', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
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
                Color(0xFF0B1D2A),
                Color(0xFF1B4965),
                Color(0xFF0B1D2A),
              ],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: availableHeight < 700 ? 12 : 18),
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
                      _buildNavCategoryHeader('OVERVIEW', 2, 4),
                      _buildNavItem(context: context, index: 0, icon: Icons.grid_view_rounded, title: 'Dashboard', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),

                      const SizedBox(height: 6),

                      // CORE OPERATIONS
                      _buildSectionCard(
                        title: 'CORE OPERATIONS',
                        verticalPadding: verticalPadding,
                        fontSize: fontSize,
                        children: [
                          _buildNavItem(context: context, index: 1, icon: Icons.local_shipping_outlined, title: 'Orders & Deliveries', badgeCount: widget.pendingCount > 0 ? widget.pendingCount : null, verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 2, icon: Icons.map_rounded, title: 'Live Map & Geofence', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                        ],
                      ),


                      // ASSET MANAGEMENT
                      _buildSectionCard(
                        title: 'ASSET MANAGEMENT',
                        verticalPadding: verticalPadding,
                        fontSize: fontSize,
                        children: [
                          _buildNavCategoryHeader('INVENTORY', 2, 2),
                          _buildNavItem(context: context, index: 7, icon: Icons.inventory_2_outlined, title: 'Products (${widget.productsCount})', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 8, icon: Icons.local_drink_outlined, title: 'Gallons & QR Registry', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavCategoryHeader('STAFF & USERS', 6, 2),
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
                          _buildNavItem(context: context, index: 4, icon: Icons.rate_review_outlined, title: 'Customer Reviews', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                          _buildNavItem(context: context, index: 3, icon: Icons.campaign_rounded, title: 'Announcements', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
                        ],
                      ),

                      // FINANCE
                      _buildNavCategoryHeader('FINANCE', 4, 4),
                      _buildNavItem(context: context, index: 10, icon: Icons.insights_rounded, title: 'Sales & Revenue', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),

                      // SYSTEM
                      _buildNavCategoryHeader('SYSTEM', 8, 4),
                      _buildNavItem(context: context, index: 11, icon: Icons.settings_outlined, title: 'Settings', verticalPadding: verticalPadding, marginBottom: itemMarginBottom, iconSize: iconSize, fontSize: fontSize),
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
