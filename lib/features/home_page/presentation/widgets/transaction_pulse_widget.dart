import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/session_counts_cubit.dart';
import '../BLoC/dashboard_white_theme_cubit.dart';

/// Transaction category data model
class TransactionCategory {
  final String key;
  final String label;
  final String pendingLabel;
  final IconData icon;
  final String? iconAsset;
  final Color color;
  final int count;
  final String? analysisLine1;
  final String? analysisLine2;

  const TransactionCategory({
    required this.key,
    required this.label,
    required this.pendingLabel,
    required this.icon,
    this.iconAsset,
    required this.color,
    required this.count,
    this.analysisLine1,
    this.analysisLine2,
  });
}

/// A dynamic widget that displays pending transaction counts across categories
/// Shows intelligent states based on data availability
class TransactionPulseWidget extends StatelessWidget {
  final VoidCallback? onSalesTap;

  const TransactionPulseWidget({
    super.key,
    this.onSalesTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;

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
          decoration: whiteTheme
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.8),
                  // border: Border.all(
                  //   color: Colors.black.withOpacity(0.12),
                  //   width: 1,
                  // ),
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.4),
                    left: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.4),
                    right: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF42A5F5).withOpacity(0.40),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45],
                  ),
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
    final salesSummary = summaries['Sales'];
    final int salesCount = (counts['Sales'] ?? 0) +
        (counts['Account Sales'] ?? 0) +
        (counts['Sales Order'] ?? 0) +
        (counts['Quotes'] ?? 0) +
        (counts['Lay-bys'] ?? 0);

    return [
      TransactionCategory(
        key: 'Sales',
        label: 'Sales',
        pendingLabel: 'Sales',
        icon: Icons.insights_outlined,
        iconAsset: 'assets/images/sell.png',
        color: const Color(0xFF00C8B3),
        count: salesCount,
        analysisLine1: _formatTotalValue(salesSummary?.totalValue),
        analysisLine2: _formatSummaryDetails(salesSummary, 'sale'),
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
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 18 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            // decoration: BoxDecoration(
            //   color: Colors.green.withOpacity(0.1),
            //   borderRadius: BorderRadius.circular(10),
            // ),
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
                    fontSize: isTablet ? 16 : 16,
                    color: whiteTheme ? Colors.black87 : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "No pending transactions.",
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 13,
                    color: whiteTheme ? Colors.black54 : Colors.white54,
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
              borderRadius: BorderRadius.circular(6),
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
                    fontSize: isTablet ? 12 : 12,
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
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;
    final Color titleColor = whiteTheme ? Colors.black87 : kSecondaryColor;
    final Color mutedColor = whiteTheme ? Colors.black54 : Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;
    final double subtitleFontSize = isTablet ? 11 : (screenWidth < 360 ? 10 : 11);
    
    // Scale factor for responsive font sizes (matching action grid cards)
    final double scale = isTablet
        ? (MediaQuery.of(context).size.shortestSide / 768).clamp(0.9, 1.25)
        : 1.0;
    final double titleSize = isTablet ? (14 * scale).clamp(14.0, 18.0) : 14.0;
    
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool showInlineSubtitle =
                          isTablet && constraints.maxWidth >= 320;
                      if (showInlineSubtitle) {
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                "Pending Transaction Activity",
                                style: getSmartTitle(
                                  fontSize: titleSize,
                                  color: titleColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "-",
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Transactions not synched to your shopfront",
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pending Transaction Activity",
                            style: getSmartTitle(
                              fontSize: titleSize,
                              color: titleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Transactions not synched to your shopfront",
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: isTablet ? 32 : 28,
                  height: isTablet ? 32 : 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: whiteTheme
                        ? const Color.fromRGBO(12, 58, 85, 1)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${_totalPending(activeCategories)}",
                    style: TextStyle(
                      fontSize: isTablet 
                          ? (12 * (MediaQuery.of(context).size.shortestSide / 768).clamp(0.9, 1.25)).clamp(12.0, 14.0)
                          : 12.0,
                      fontWeight: FontWeight.w800,
                      color: whiteTheme
                          ? Colors.white
                          : const Color.fromRGBO(12, 58, 85, 1),
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
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;
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
                width: 1,
                margin: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
                color:
                     whiteTheme ? Colors.black12 : Colors.white30
               
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
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;
    return Wrap(
      spacing: isTablet ? 8 : 6,
      runSpacing: isTablet ? 8 : 6,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isLastInRow = (index + 1) % 2 == 0;
       // final isLastRow = index >= categories.length - 2;
        
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                  (isTablet ? 44 + 24 + 16 : 32 + 16 + 12)) / 2,
          child: Container(
            decoration: !isTablet ? BoxDecoration(
              border: Border(
                right: !isLastInRow ? BorderSide(color: whiteTheme ? Colors.black12 : Colors.white30, width: 0.5) : BorderSide.none,
               // bottom: !isLastRow ? BorderSide(color: Colors.white30, width: 1) : BorderSide.none,
              ),
            ) : null,
            child: _buildCategoryTile(
              context,
              colors,
              isTablet,
              category,
              isCompact: true,
            ),
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
    final VoidCallback? onTap = category.key == 'Sales' ? onSalesTap : null;
    final bool whiteTheme = context.watch<DashboardWhiteThemeCubit>().state;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: isCompact && isTablet
            ? BoxDecoration(
                color: category.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: category.color.withOpacity(0.2),
                  width: 1,
                ),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with filled background
            Padding(
              padding: EdgeInsets.only(top: isTablet ? 6 : 4),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 9 : 7),
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: category.iconAsset != null
                    ? Image.asset(
                        category.iconAsset!,
                        width: isTablet ? 24 : 16,
                        height: isTablet ? 24 : 16,
                      )
                    : Icon(
                        category.icon,
                        color: Colors.white,
                        size: isTablet ? 28 : 18,
                      ),
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
                      fontSize: isTablet 
                          ? (12 * (MediaQuery.of(context).size.shortestSide / 768).clamp(0.9, 1.25)).clamp(12.0, 14.0)
                          : 12.0,
                      fontWeight: FontWeight.w600,
                      color: whiteTheme ? Colors.black87 : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Count
                  Text(
                    "${category.count}",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 17,
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
                        fontSize: isTablet ? 11 : 11,
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
                        fontSize: isTablet ? 11 : 11,
                        fontWeight: FontWeight.w500,
                        color: whiteTheme ? Colors.black54 : Colors.white70,
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
