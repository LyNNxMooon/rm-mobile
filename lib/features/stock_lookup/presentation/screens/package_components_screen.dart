import 'package:flutter/material.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/package_component.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';
import 'package:logger/logger.dart';

import 'stock_details_screen.dart';

final _logger = Logger();

class PackageComponentsScreen extends StatelessWidget {
  final String packageDescription;
  final List<PackageComponent> components;

  const PackageComponentsScreen({
    super.key,
    required this.packageDescription,
    required this.components,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
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
              'Package Components',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              packageDescription,
              style: TextStyle(
                color: colors.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Items: ',
                        style: TextStyle(
                          color: colors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${components.length}',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total: ',
                        style: TextStyle(
                          color: kPrimaryColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${_calculateGrandTotal().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        toolbarHeight: 56,
      ),
      body: Column(
        children: [
          // Header row
          Container(
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
                Expanded(
                  flex: 2,
                  child: Text(
                    'Barcode',
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Sell (Inc)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Components list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 8 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: components.length,
              itemBuilder: (context, index) {
                final component = components[index];
                final sellInc = component.sellInc ?? 0;
                final total = sellInc * component.quantity;

                final divider = index < components.length - 1
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToStockDetails(context, component),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 14 : 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  component.barcode ?? '-',
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
                                  component.description ?? '-',
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
                                flex: 1,
                                child: Text(
                                  _formatQty(component.quantity),
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
                                  '\$${sellInc.toStringAsFixed(2)}',
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
                                  '\$${total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: isTablet ? 14 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  double _calculateGrandTotal() {
    double total = 0;
    for (final component in components) {
      total += (component.sellInc ?? 0) * component.quantity;
    }
    return total;
  }

  Future<void> _navigateToStockDetails(
    BuildContext context,
    PackageComponent component,
  ) async {
    _logger.i('=== Navigating to component stock details ===');
    _logger.i('Component stockId: ${component.stockId}');
    _logger.i('Component barcode: ${component.barcode}');
    
    // Search by stock_id without shopfront restriction (component stocks may be from any shopfront)
    var stock = await LocalDbDAO.instance.getStockByIdAnyShopfront(component.stockId);
    
    // If not found by ID, try by barcode as fallback
    if (stock == null && component.barcode != null && component.barcode!.isNotEmpty) {
      _logger.w('Stock not found by ID, trying barcode search: ${component.barcode}');
      final shopfrontId = (await LocalDbDAO.instance.getShopfrontId() ?? '').trim();
      final searchResult = await LocalDbDAO.instance.getStockBySearch(component.barcode!, shopfrontId);
      if (!searchResult.notFound && searchResult.stock != null) {
        stock = searchResult.stock;
      } else if (searchResult.duplicates.isNotEmpty) {
        stock = searchResult.duplicates.first;
      }
    }
    
    if (stock != null && context.mounted) {
      _logger.i('Found stock: ${stock.description} (ID: ${stock.stockID})');
      context.navigateToNext(
        StockDetailsScreen(stock: stock),
      );
    } else if (context.mounted) {
      _logger.e('Stock not found for component stockId: ${component.stockId}, barcode: ${component.barcode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock item "${component.description ?? component.barcode}" not found in local database. Try syncing stock first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
