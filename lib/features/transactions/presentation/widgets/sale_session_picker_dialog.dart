import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/sale_session_vo.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../constants/standard_dialog.dart';

/// Result from session picker dialog
enum SessionPickerResult { continueSession, newSale, cancelled }

/// Dialog for selecting a saved sale session or starting a new sale
class SaleSessionPickerDialog extends StatelessWidget {
  final List<SaleSessionVO> sessions;
  final String sessionType;

  const SaleSessionPickerDialog({
    super.key,
    required this.sessions,
    required this.sessionType,
  });

  /// Shows the dialog and returns the selected session or null for new sale
  static Future<({SessionPickerResult result, SaleSessionVO? session})?> show({
    required BuildContext context,
    required List<SaleSessionVO> sessions,
    required String sessionType,
  }) {
    return showDialog<({SessionPickerResult result, SaleSessionVO? session})>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          SaleSessionPickerDialog(sessions: sessions, sessionType: sessionType),
    );
  }

  IconData _getIconForSessionType() {
    switch (sessionType) {
      case 'Account Sales':
        return Icons.receipt_long_outlined;
      case 'Sales Order':
        return Icons.shopping_cart_outlined;
      case 'Quotes':
        return Icons.request_quote_outlined;
      case 'Lay-bys':
        return Icons.inventory_2_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getColorForSessionType() {
    switch (sessionType) {
      case 'Account Sales':
        return const Color.fromARGB(255, 210, 148, 172);
      case 'Sales Order':
        return const Color.fromARGB(255, 44, 133, 211);
      case 'Quotes':
        return Colors.orange.shade500;
      case 'Lay-bys':
        return const Color.fromARGB(255, 152, 86, 165);
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppThemeColors(context);
    final isTablet = context.isTablet;
    final useDesktopNav = context.useDesktopNav;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final media = MediaQuery.of(context);
    final double maxDialogHeight = (media.size.height -
        media.viewInsets.vertical -
        (isTablet || useDesktopNav ? 120 : 88))
      .clamp(280.0, media.size.height * 0.92)
      .toDouble();

    final iconColor = _getColorForSessionType();
    final icon = _getIconForSessionType();

    // Use tablet sizing for desktop
    final bool useWideLayout = isTablet || useDesktopNav;

    return StandardDialog(
      title: "",
      colors: colors,
      isDark: isDark,
      maxWidth: useDesktopNav ? 550 : (isTablet ? 500 : double.infinity),
      maxHeight: maxDialogHeight,
      showHeader: false,
      contentPadding: EdgeInsets.fromLTRB(
        useWideLayout ? 12 : 8,
        useWideLayout ? 20 : 16,
        useWideLayout ? 12 : 8,
        useWideLayout ? 18 : 14,
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: useDesktopNav ? 60 : (isTablet ? 40 : 12),
      ),
      onClose: () => Navigator.pop(context, (
        result: SessionPickerResult.cancelled,
        session: null,
      )),
      content: Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom header with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(useWideLayout ? 10 : 8),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: useWideLayout ? 24 : 20,
                  ),
                ),
                SizedBox(width: useWideLayout ? 14 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pending $sessionType",
                        style: TextStyle(
                          fontSize: useWideLayout ? 18 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${sessions.length} ${sessions.length == 1 ? 'record' : 'records'} in the list",
                        style: TextStyle(
                          fontSize: useWideLayout ? 13 : 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, (
                    result: SessionPickerResult.cancelled,
                    session: null,
                  )),
                  icon: Icon(
                    Icons.close,
                    size: useWideLayout ? 24 : 22,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sessions list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  useWideLayout ? 8 : 6,
                  12,
                  useWideLayout ? 8 : 6,
                  12,
                ),
                itemCount: sessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionTile(
                    context,
                    session,
                    colors,
                    isDark,
                    useWideLayout,
                    dateFormat,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        DialogTextAction(
          label: "New $sessionType",
          icon: Icons.add,
          style: DialogActionStyle.outline,
          onPressed: () => Navigator.pop(context, (
            result: SessionPickerResult.newSale,
            session: null,
          )),
        ),
      ],
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    SaleSessionVO session,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
    DateFormat dateFormat,
  ) {
    return Material(
      color: isDark ? colors.surfaceAlt : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.pop(context, (
          result: SessionPickerResult.continueSession,
          session: session,
        )),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Cart icon with item count
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          maxWidth: 28,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          session.itemCount > 99
                              ? "99+"
                              : "${session.itemCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.customerName ?? "Customer",
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 140 : 100,
                          ),
                          child: Text(
                            session.formattedTotal,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateFormat.format(session.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${_formatQuantity(session.totalQuantity)} items",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats large quantities to avoid overflow (e.g., 1234 -> "1,234", 9999999 -> "9.9M")
  String _formatQuantity(num quantity) {
    if (quantity >= 1000000) {
      return "${(quantity / 1000000).toStringAsFixed(1)}M";
    } else if (quantity >= 10000) {
      return "${(quantity / 1000).toStringAsFixed(1)}K";
    }
    final doubleVal = quantity.toDouble();
    return doubleVal.toStringAsFixed(
      doubleVal.truncateToDouble() == doubleVal ? 0 : 2,
    );
  }
}
