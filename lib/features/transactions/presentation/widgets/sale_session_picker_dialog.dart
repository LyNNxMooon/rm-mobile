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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppThemeColors(context);
    final isTablet = context.isTablet;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return StandardDialog(
      title: "Resume $sessionType?",
      subtitle:
          "You have ${sessions.length} unsaved ${sessions.length == 1 ? 'session' : 'sessions'}",
      colors: colors,
      isDark: isDark,
      maxWidth: isTablet ? 500 : double.infinity,
      onClose: () => Navigator.pop(context, (
        result: SessionPickerResult.cancelled,
        session: null,
      )),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionTile(
                context,
                session,
                colors,
                isDark,
                isTablet,
                dateFormat,
              );
            },
          ),
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
