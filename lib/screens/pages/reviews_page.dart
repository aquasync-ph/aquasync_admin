import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../dialogs/review_details_dialog.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/app_pagination_controls.dart';

class ReviewsPage extends StatefulWidget {
  final List<ReviewModel> reviews;
  final VoidCallback onRefresh;

  const ReviewsPage({
    super.key,
    required this.reviews,
    required this.onRefresh,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedRatingFilter = 0; // 0 = All, 1..5 = 1..5 stars
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReviewModel> get _filteredReviews {
    final query = _searchController.text.trim().toLowerCase();
    return widget.reviews.where((r) {
      final matchesRating =
          _selectedRatingFilter == 0 || r.rating == _selectedRatingFilter;
      final matchesSearch = query.isEmpty ||
          r.customerName.toLowerCase().contains(query) ||
          r.driverName.toLowerCase().contains(query) ||
          r.orderNumber.toLowerCase().contains(query) ||
          r.review.toLowerCase().contains(query);
      return matchesRating && matchesSearch;
    }).toList();
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
          size: 16,
        );
      }),
    );
  }

  void _showReviewDetails(ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => ReviewDetailsDialog(review: review),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReviews;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <ReviewModel>[]
        : filtered.sublist(
            startIndex.clamp(0, filtered.length),
            (startIndex + _itemsPerPage).clamp(0, filtered.length),
          );

    final totalReviews = widget.reviews.length;
    double avgRating = 0.0;
    if (totalReviews > 0) {
      final sum = widget.reviews.fold<int>(0, (acc, r) => acc + r.rating);
      avgRating = sum / totalReviews;
    }
    final fiveStarCount = widget.reviews.where((r) => r.rating == 5).length;
    final oneStarCount = widget.reviews.where((r) => r.rating == 1).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final parentWidth = constraints.maxWidth;
              double cardWidth = (parentWidth - 16 * 3) / 4;
              if (parentWidth < 600) {
                cardWidth = parentWidth;
              } else if (parentWidth < 1000) {
                cardWidth = (parentWidth - 16) / 2;
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  KpiCard(
                    width: cardWidth,
                    label: 'Total Reviews',
                    value: '$totalReviews',
                    subText: 'All customer feedback',
                    icon: Icons.rate_review_rounded,
                    accentColor: const Color(0xFF0284C7),
                  ),
                  KpiCard(
                    width: cardWidth,
                    label: 'Average Rating',
                    value: totalReviews > 0
                        ? '${avgRating.toStringAsFixed(1)} / 5'
                        : 'N/A',
                    subText: 'Overall satisfaction',
                    icon: Icons.star_rounded,
                    accentColor: const Color(0xFF0284C7),
                  ),
                  KpiCard(
                    width: cardWidth,
                    label: '5-Star Reviews',
                    value: '$fiveStarCount',
                    subText: totalReviews > 0
                        ? '${((fiveStarCount / totalReviews) * 100).toStringAsFixed(0)}% of total'
                        : '0%',
                    icon: Icons.sentiment_very_satisfied_rounded,
                    accentColor: const Color(0xFF0284C7),
                  ),
                  KpiCard(
                    width: cardWidth,
                    label: '1-Star Reviews',
                    value: '$oneStarCount',
                    subText: totalReviews > 0
                        ? '${((oneStarCount / totalReviews) * 100).toStringAsFixed(0)}% of total'
                        : '0%',
                    icon: Icons.sentiment_very_dissatisfied_rounded,
                    accentColor: const Color(0xFF0284C7),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Search & Filter Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {
                      _currentPage = 1;
                    }),
                    decoration: InputDecoration(
                      hintText:
                          'Search by customer name, driver, order #, or review text...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: Color(0xFF475569),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _currentPage = 1;
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFE0F2FE),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedRatingFilter,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRatingFilter = val;
                            _currentPage = 1;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('All Ratings', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('5 Stars', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('4 Stars', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('3 Stars', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2 Stars', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1 Star', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reviews List / Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Review Submissions (${_filteredReviews.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_selectedRatingFilter != 0 ||
                          _searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedRatingFilter = 0;
                              _searchController.clear();
                            });
                          },
                          child: const Text(
                            'Reset Filters',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(color: const Color(0xFFE2E8F0), height: 1),
                if (_filteredReviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No customer reviews found matching your filter criteria.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'CUSTOMER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DRIVER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'ORDER #',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'RATING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'REVIEW MESSAGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DATE SUBMITTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'ACTIONS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                            rows: paginated.map((r) {
                              final msg = r.review.trim().isEmpty
                                  ? '—'
                                  : (r.review.length > 50
                                      ? '${r.review.substring(0, 50)}...'
                                      : r.review);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      r.customerName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          r.driverName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      r.orderNumber,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildStarRating(r.rating),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${r.rating}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 250,
                                      child: Text(
                                        msg,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: r.review.trim().isEmpty
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      r.createdAt,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_rounded,
                                        size: 18,
                                        color: Color(0xFF0284C7),
                                      ),
                                      tooltip: 'View Details',
                                      onPressed: () => _showReviewDetails(r),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
              ],
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
