import 'package:flutter/material.dart';

import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../constants/standard_dialog.dart';

/// Dialog for showing out of stock items when trying to finalise a sale
class OutOfStockFinaliseDialog extends StatelessWidget {
  final List<CartItemVO> outOfStockItems;
  final AppThemeColors colors;
  final bool isDark;

  const OutOfStockFinaliseDialog({
    super.key,
    required this.outOfStockItems,
    required this.colors,
    required this.isDark,
  });

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required List<CartItemVO> outOfStockItems,
    required AppThemeColors colors,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => OutOfStockFinaliseDialog(
        outOfStockItems: outOfStockItems,
        colors: colors,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.isTablet;

    return StandardDialog(
      title: 'Not Permitted!',
      colors: colors,
      isDark: isDark,
      maxWidth: isTablet ? 450 : double.infinity,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock items cannot be sold if inventory levels are below the sale quantity.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: outOfStockItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please review inventory levels of items in the list.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
      actions: [
        DialogTextAction(
          label: 'Cancel',
          style: DialogActionStyle.cancelOutline,
          onPressed: () => Navigator.pop(context),
        ),
        DialogTextAction(
          label: 'OK',
          style: DialogActionStyle.primary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
