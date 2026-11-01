import 'dart:math';
import 'package:flutter/material.dart';

class AppPaginationControls extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;

  const AppPaginationControls({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.itemsPerPageOptions = const [5, 10, 20, 50, 100],
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) {
      return const SizedBox.shrink();
    }

    final totalPages = max(1, (totalItems / itemsPerPage).ceil());
    final safeCurrentPage = currentPage.clamp(1, totalPages);

    final startItem = (safeCurrentPage - 1) * itemsPerPage + 1;
    final endItem = min(safeCurrentPage * itemsPerPage, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0284C7),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 640;

          final infoAndSelector = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Showing $startItem–$endItem of $totalItems',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              if (onItemsPerPageChanged != null) ...[
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F3FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0098DA).withValues(alpha: 0.30),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPageOptions.contains(itemsPerPage)
                          ? itemsPerPage
                          : itemsPerPageOptions.first,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1D2A),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF0098DA),
                      ),
                      items: itemsPerPageOptions.map((opt) {
                        return DropdownMenuItem<int>(
                          value: opt,
                          child: Text('$opt / page'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && onItemsPerPageChanged != null) {
                          onItemsPerPageChanged!(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          );

          final pageButtons = _buildPageButtons(
            safeCurrentPage: safeCurrentPage,
            totalPages: totalPages,
            isMobile: isMobile,
          );

          if (isMobile) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                infoAndSelector,
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: pageButtons,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              infoAndSelector,
              pageButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageButtons({
    required int safeCurrentPage,
    required int totalPages,
    required bool isMobile,
  }) {
    List<int> pagesToShow = [];
    if (totalPages <= 7) {
      pagesToShow = List.generate(totalPages, (i) => i + 1);
    } else {
      pagesToShow.add(1);
      int start = max(2, safeCurrentPage - 1);
      int end = min(totalPages - 1, safeCurrentPage + 1);

      if (start > 2) {
        pagesToShow.add(-1); // ellipsis
      }

      for (int i = start; i <= end; i++) {
        pagesToShow.add(i);
      }

      if (end < totalPages - 1) {
        pagesToShow.add(-2); // ellipsis
      }

      pagesToShow.add(totalPages);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First Page Button
        _buildNavButton(
          icon: Icons.first_page_rounded,
          enabled: safeCurrentPage > 1,
          onPressed: () => onPageChanged(1),
          tooltip: 'First Page',
        ),
        const SizedBox(width: 4),
        // Previous Page Button
        _buildNavButton(
          icon: Icons.chevron_left_rounded,
          enabled: safeCurrentPage > 1,
          onPressed: () => onPageChanged(safeCurrentPage - 1),
          tooltip: 'Previous Page',
        ),
        const SizedBox(width: 6),

        // Numbered Pages
        ...pagesToShow.map((pageNum) {
          if (pageNum < 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          }

          final isSelected = pageNum == safeCurrentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelected ? null : () => onPageChanged(pageNum),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0098DA)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0098DA)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 6),
        // Next Page Button
        _buildNavButton(
          icon: Icons.chevron_right_rounded,
          enabled: safeCurrentPage < totalPages,
          onPressed: () => onPageChanged(safeCurrentPage + 1),
          tooltip: 'Next Page',
        ),
        const SizedBox(width: 4),
        // Last Page Button
        _buildNavButton(
          icon: Icons.last_page_rounded,
          enabled: safeCurrentPage < totalPages,
          onPressed: () => onPageChanged(totalPages),
          tooltip: 'Last Page',
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFE6F3FA)
                  : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? const Color(0xFF0098DA).withValues(alpha: 0.30)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? const Color(0xFF0098DA) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
