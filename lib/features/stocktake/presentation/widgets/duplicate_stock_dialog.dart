import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/dialog_size_utils.dart';

class DuplicateStockDialog extends StatelessWidget {
  final List<StockVO> matches;

  const DuplicateStockDialog({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.6;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? colors.surface : kBgColor,
      elevation: 10,
      insetPadding: dialogInsetPadding(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.copy_all_rounded,
                        color: kPrimaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Duplicate Barcode",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colors.onSurface : kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Multiple items found. Please select one:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return _buildStockItem(context, matches[i]);
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),
            
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: colors.onHero,
                    minimumSize: const Size(double.infinity, 50),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Cancel",
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(BuildContext context, StockVO s) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.pop(context, s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : kSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? colors.cardShadow
                  : kThirdColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    s.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colors.onSurface : kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Details Row
                  Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? colors.divider : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          s.barcode,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: isDark ? colors.onSurface : kThirdColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      

                      Text(
                        "In Stock: ${_formatQty(s.quantity)}", 

                        style: const TextStyle(
                          fontSize: 12,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? colors.onSurfaceMuted : kGreyColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatQty(num qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
}
