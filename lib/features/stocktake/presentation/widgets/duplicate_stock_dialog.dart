import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import '../../../../constants/colors.dart';

class DuplicateStockDialog extends StatelessWidget {
  final List<StockVO> matches;

  const DuplicateStockDialog({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {

    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.6;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kBgColor,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                  const Text(
                    "Duplicate Barcode",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Multiple items found. Please select one:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: kGreyColor,
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
                height: 45,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kGreyColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: kGreyColor,
                      fontWeight: FontWeight.bold,
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
    return InkWell(
      onTap: () => Navigator.pop(context, s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: kThirdColor.withOpacity(0.05),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Details Row
                  Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          s.barcode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: kThirdColor,
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kGreyColor),
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