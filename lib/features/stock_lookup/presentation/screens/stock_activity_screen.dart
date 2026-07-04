import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/response/stock_activity_response.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

import '../BLoC/stock_activity_bloc.dart';

class StockActivityScreen extends StatefulWidget {
  const StockActivityScreen({
    super.key,
    required this.stockId,
    this.stockDescription,
  });

  final int stockId;
  final String? stockDescription;

  @override
  State<StockActivityScreen> createState() => _StockActivityScreenState();
}

class _StockActivityScreenState extends State<StockActivityScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<StockActivityBloc>()
        .add(FetchStockActivityEvent(stockId: widget.stockId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kPrimaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Activity',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((widget.stockDescription ?? '').trim().isNotEmpty)
              Text(
                widget.stockDescription!.trim(),
                style: TextStyle(
                  color: colors.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Showing stock activities from Non-Archived data.",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 84,
      ),
      body: BlocBuilder<StockActivityBloc, StockActivityState>(
        builder: (context, state) {
          if (state is StockActivityLoading || state is StockActivityInitial) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (state is StockActivityError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          final activities = state is StockActivityLoaded
              ? state.activities
              : const <StockActivityItem>[];

          if (activities.isEmpty) {
            return Center(
              child: Text(
                'No activity found for this stock item.',
                style: TextStyle(
                  color: colors.onSurfaceMuted,
                  fontSize: 14,
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildHeaderRow(colors, isDark, isTablet),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 8 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final divider = index < activities.length - 1
                        ? Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          )
                        : const SizedBox.shrink();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDataRow(activity, isDark, isTablet),
                        divider,
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    Widget headerCell(String label, int flex, TextAlign align) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            color: colors.onSurfaceMuted,
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : kSecondaryColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          headerCell('Description', 4, TextAlign.left),
          headerCell('Tran #', 2, TextAlign.center),
          headerCell('Qty', 2, TextAlign.center),
          headerCell('Date', 3, TextAlign.right),
          headerCell('Day(s)', 2, TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    StockActivityItem activity,
    bool isDark,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              activity.transactionDesc.trim().isEmpty
                  ? '-'
                  : activity.transactionDesc,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${activity.tranId}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatQty(activity.quantity),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatShortDate(activity.lastDate),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDays(activity.lastDate),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(num qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  String _formatShortDate(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('MM/dd/yyyy').format(parsed.toLocal());
    }

    return raw;
  }

  String _formatDays(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';

    final local = parsed.toLocal();
    final saleDate = DateTime(local.year, local.month, local.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(saleDate).inDays;

    return days.toString();
  }
}
