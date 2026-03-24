import 'package:flutter/material.dart';

import '../../../../../constants/colors.dart';
import '../../../../../constants/images.dart';
import '../../../../../constants/theme_colors.dart';
import '../../../domain/models/cart_item.dart';

/// Mobile-optimized cart tile with thumbnail, description and price
class MobileCartTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final VoidCallback? onDelete;

  const MobileCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : kSecondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : kThirdColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail Image
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                overviewPlaceholder,
                fit: BoxFit.fill,
              ),
            ),
          ),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Quantity & Extension Total
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Qty Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "x${item.qty}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Extension Total
              Text(
                "\$${item.extension.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tablet-optimized cart tile with grid layout
class TabletCartTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final VoidCallback? onDelete;

  const TabletCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : kSecondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : kThirdColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail Image
          Container(
            width: 45,
            height: 45,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                overviewPlaceholder,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: kPrimaryColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              item.description,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              "\$${item.sellPrice.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "x${item.qty}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              "\$${item.extension.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact cart tile - table row style without thumbnails
class CompactCartTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;

  const CompactCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              // Code
              SizedBox(
                width: 85,
                child: Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: kPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Description
              Expanded(
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Qty
              SizedBox(
                width: 30,
                child: Text(
                  "${item.qty}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
              // Price
              SizedBox(
                width: 65,
                child: Text(
                  "\$${item.extension.toStringAsFixed(2)}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
      ],
    );
  }
}

/// Grid header for tablet view
class CartGridHeader extends StatelessWidget {
  final AppThemeColors colors;

  const CartGridHeader({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildHeader("Code")),
        Expanded(flex: 4, child: _buildHeader("Description")),
        SizedBox(width: 100, child: _buildHeader("Price", alignRight: true)),
        SizedBox(width: 120, child: Center(child: _buildHeader("Qty"))),
        SizedBox(width: 100, child: _buildHeader("Ext", alignRight: true)),
        const SizedBox(width: 40), // Space for delete button
      ],
    );
  }

  Widget _buildHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceMuted,
      ),
    );
  }
}
