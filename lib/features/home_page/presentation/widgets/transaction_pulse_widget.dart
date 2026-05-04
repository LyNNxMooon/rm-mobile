import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/session_counts_cubit.dart';

/// Transaction category data model
class TransactionCategory {
  final String key;
  final String label;
  final String pendingLabel;
  final IconData icon;
  final Color color;
  final int count;
  final String? analysisLine1;
  final String? analysisLine2;

  const TransactionCategory({
    required this.key,
    required this.label,
    required this.pendingLabel,
    required this.icon,
    required this.color,
    required this.count,
    this.analysisLine1,
    this.analysisLine2,
  });
}

/// A dynamic widget that displays pending transaction counts across categories
/// Shows intelligent states based on data availability
class TransactionPulseWidget extends StatelessWidget {
  final VoidCallback? onInvoiceTap;
  final VoidCallback? onSalesOrderTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onLaybyTap;

  const TransactionPulseWidget({
    super.key,
    this.onInvoiceTap,
    this.onSalesOrderTap,
    this.onQuoteTap,
    this.onLaybyTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;

    return BlocBuilder<SessionCountsCubit, SessionCountsState>(
      builder: (context, state) {
        // Build categories with current counts and summaries
        final categories = _buildCategories(state.counts, state.summaries);
        
        // Filter to only show categories with pending items
        final activeCategories = categories.where((c) => c.count > 0).toList();

        return Container(
          margin: EdgeInsets.fromLTRB(
            isTablet ? 22 : 16,
            isTablet ? 16 : 12,
            isTablet ? 22 : 16,
            isTablet ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: colors.isDark
                ? colors.surfaceAlt.withOpacity(0.98)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.isDark
                  ? Colors.white10
                  : Colors.grey.shade200.withOpacity(0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withOpacity(0.10)
                    : colors.cardShadow.withOpacity(0.14),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: activeCategories.isEmpty
              ? _buildAllCaughtUpState(context, colors, isTablet)
              : _buildActiveState(context, colors, isTablet, activeCategories),
        );
      },
    );
  }

  List<TransactionCategory> _buildCategories(
    Map<String, int> counts,
    Map<String, SessionSummary> summaries,
  ) {
    final invoiceSummary = summaries['Account Sales'];
    final salesOrderSummary = summaries['Sales Order'];
    final quoteSummary = summaries['Quotes'];
    final laybySummary = summaries['Lay-bys'];

    return [
      TransactionCategory(
        key: 'Account Sales',
        label: 'Invoices',
        pendingLabel: 'Pending Invoices',
        icon: Icons.receipt_long_outlined,
        color: const Color.fromARGB(255, 238, 130, 166), // Pink - matches grid card
        count: counts['Account Sales'] ?? 0,
        analysisLine1: _formatTotalValue(invoiceSummary?.totalValue),
        analysisLine2: _formatSummaryDetails(invoiceSummary, 'invoice'),
      ),
      TransactionCategory(
        key: 'Sales Order',
        label: 'Sales Orders',
        pendingLabel: 'Pending Orders',
        icon: Icons.shopping_cart_outlined,
        color: const Color.fromARGB(255, 44, 133, 211), // Blue - matches grid card
        count: counts['Sales Order'] ?? 0,
        analysisLine1: _formatTotalValue(salesOrderSummary?.totalValue),
        analysisLine2: _formatSummaryDetails(salesOrderSummary, 'order'),
      ),
      TransactionCategory(
        key: 'Quotes',
        label: 'Quotes',
        pendingLabel: 'Active Quotes',
        icon: Icons.request_quote_outlined,
        color: Colors.orange.shade500, // Orange - matches grid card
        count: counts['Quotes'] ?? 0,
        analysisLine1: _formatTotalValue(quoteSummary?.totalValue),
        analysisLine2: _formatSummaryDetails(quoteSummary, 'quote'),
      ),
      TransactionCategory(
        key: 'Lay-bys',
        label: 'Laybys',
        pendingLabel: 'Active Laybys',
        icon: Icons.inventory_2_outlined, // Matches grid card icon
        color: const Color.fromARGB(255, 152, 86, 165), // Purple - matches grid card
        count: counts['Lay-bys'] ?? 0,
        analysisLine1: _formatTotalValue(laybySummary?.totalValue),
        analysisLine2: _formatSummaryDetails(laybySummary, 'layby'),
      ),
    ];
  }

  String? _formatTotalValue(double? value) {
    if (value == null || value == 0) return null;
    if (value >= 1000000) {
      return 'Total: \$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'Total: \$${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Total: \$${value.toStringAsFixed(2)}';
  }

  String? _formatSummaryDetails(SessionSummary? summary, String type) {
    if (summary == null) return null;
    
    final parts = <String>[];
    
    // Add customer info
    if (summary.customerCount > 0) {
      parts.add('${summary.customerCount} customer${summary.customerCount > 1 ? 's' : ''}');
    }
    
    // Add item count
    if (summary.itemCount > 0) {
      parts.add('${summary.itemCount} item${summary.itemCount > 1 ? 's' : ''}');
    }
    
    // Add age indicator
    if (summary.ageInDays >= 0 && summary.oldestDate != null) {
      if (summary.ageInDays == 0) {
        parts.add('Today');
      } else if (summary.ageInDays == 1) {
        parts.add('1 day old');
      } else if (summary.ageInDays < 7) {
        parts.add('${summary.ageInDays} days old');
      } else if (summary.ageInDays < 30) {
        parts.add('${(summary.ageInDays / 7).floor()}w old');
      } else {
        parts.add('${(summary.ageInDays / 30).floor()}mo old');
      }
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : null;
  }

  /// Zero-state UI when no pending transactions exist
  Widget _buildAllCaughtUpState(
    BuildContext context,
    AppThemeColors colors,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 18 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Caught Up!",
                  style: getSmartTitle(
                    fontSize: isTablet ? 16 : 14,
                    color: colors.isDark ? Colors.white : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "No pending transactions. System running smoothly.",
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    color: colors.isDark
                        ? Colors.white54
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 10 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: isTablet ? 16 : 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  "On Track",
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Active state UI with transaction categories
  Widget _buildActiveState(
    BuildContext context,
    AppThemeColors colors,
    bool isTablet,
    List<TransactionCategory> activeCategories,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine layout based on screen width and category count
    final bool useCompactLayout = screenWidth < 400 || 
        (activeCategories.length >= 3 && screenWidth < 600);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 14 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: isTablet ? 18 : 14,
                  color: kPrimaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  "Transaction Pulse",
                  style: getSmartTitle(
                    fontSize: isTablet ? 14 : 12,
                    color: colors.isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 8 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${_totalPending(activeCategories)} pending",
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 9,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          // Categories row/grid
          useCompactLayout
              ? _buildCompactGrid(context, colors, isTablet, activeCategories)
              : _buildHorizontalRow(context, colors, isTablet, activeCategories),
        ],
      ),
    );
  }

  int _totalPending(List<TransactionCategory> categories) {
    return categories.fold(0, (sum, c) => sum + c.count);
  }

  /// Horizontal row layout for wider screens
  Widget _buildHorizontalRow(
    BuildContext context,
    AppThemeColors colors,
    bool isTablet,
    List<TransactionCategory> categories,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            Expanded(
              child: _buildCategoryTile(
                context,
                colors,
                isTablet,
                categories[i],
                isCompact: false,
              ),
            ),
            // Add separator between items, but not after the last one
            if (i < categories.length - 1)
              Container(
                width: 1.5,
                margin: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
                color: colors.isDark
                    ? Colors.white30
                    : const Color(0xFFCECECE),
              ),
          ],
        ],
      ),
    );
  }

  /// Compact grid layout for narrower screens
  Widget _buildCompactGrid(
    BuildContext context,
    AppThemeColors colors,
    bool isTablet,
    List<TransactionCategory> categories,
  ) {
    return Wrap(
      spacing: isTablet ? 8 : 6,
      runSpacing: isTablet ? 8 : 6,
      children: categories.map((category) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                  (isTablet ? 44 + 24 + 16 : 32 + 16 + 12)) / 2,
          child: _buildCategoryTile(
            context,
            colors,
            isTablet,
            category,
            isCompact: true,
          ),
        );
      }).toList(),
    );
  }

  /// Individual category tile
  Widget _buildCategoryTile(
    BuildContext context,
    AppThemeColors colors,
    bool isTablet,
    TransactionCategory category, {
    required bool isCompact,
  }) {
    final VoidCallback? onTap = switch (category.key) {
      'Account Sales' => onInvoiceTap,
      'Sales Order' => onSalesOrderTap,
      'Quotes' => onQuoteTap,
      'Lay-bys' => onLaybyTap,
      _ => null,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: isCompact
            ? BoxDecoration(
                color: category.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: category.color.withOpacity(0.2),
                  width: 1,
                ),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with filled background
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: Colors.white,
                size: isTablet ? 22 : 18,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    category.pendingLabel,
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 9,
                      fontWeight: FontWeight.w600,
                      color: colors.isDark ? Colors.white : colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Count
                  Text(
                    "${category.count}",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 15,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                  // Analysis data - Total value (green)
                  if (category.analysisLine1 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category.analysisLine1!,
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50), // Green
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Analysis data - Details (customers, items, time)
                  if (category.analysisLine2 != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      category.analysisLine2!,
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 9,
                        fontWeight: FontWeight.w500,
                        color: colors.isDark
                            ? Colors.white70
                            : Colors.blueGrey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUrgencyLabel(int count) {
    if (count >= 10) return "High priority";
    if (count >= 5) return "Needs attention";
    return "Pending";
  }

  Color _getUrgencyColor(int count) {
    if (count >= 10) return Colors.red.shade400;
    if (count >= 5) return Colors.orange.shade400;
    return Colors.grey.shade500;
  }
}
