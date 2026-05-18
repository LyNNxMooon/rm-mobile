import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart'; // Adjust if needed
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart'; // Adjust if needed
import 'package:rmmobile/utils/dialog_size_utils.dart';
import 'package:rmmobile/utils/formatting_utils.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

class StockDetailsReadOnlyDialog extends StatelessWidget {
  const StockDetailsReadOnlyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    // Dynamic height constraint (max 85% of screen height)
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.85;
    final double dialogBorderRadius = useDesktopNav ? 12.0 : 20.0;
    final double dialogMaxWidth = useDesktopNav ? 500.0 : double.infinity;

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogBorderRadius),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
      elevation: 10,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth, maxHeight: maxDialogHeight),
        // We reuse the same BlocBuilder to fetch data, but show a different UI
        child: BlocBuilder<StockDetailsBloc, StockFetchingStates>(
          builder: (context, state) {
            // 1. Loading State
            if (state is StockDetailsLoading) {
              return Padding(
                padding: EdgeInsets.all(useDesktopNav ? 32.0 : 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(radius: useDesktopNav ? 12 : 15),
                    SizedBox(height: useDesktopNav ? 12 : 15),
                    Text(
                      "Fetching details...",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                        fontSize: useDesktopNav ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Error State
            if (state is StockDetailsError) {
              return Padding(
                padding: EdgeInsets.all(useDesktopNav ? 16.0 : 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: kErrorColor, size: useDesktopNav ? 32 : 40),
                    SizedBox(height: useDesktopNav ? 8 : 10),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                        fontSize: useDesktopNav ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: useDesktopNav ? 16 : 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(useDesktopNav ? 8 : 10)),
                      ),
                      child: Text(
                        "Close",
                        style: TextStyle(color: colors.onHero),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Loaded State - Show Read-Only View
            if (state is StockDetailsLoaded) {

              double sell = 0.00;
              double cost = 0.00;

              if ((state.stock.goodsTax ?? "") == "GST") {
                cost = state.stock.cost * 1.1;
              } else {
                cost = state.stock.cost;
              }

              if ((state.stock.salesTax ?? "") == "GST") {
                sell = state.stock.sell * 1.1;
              } else {
                sell = state.stock.sell;
              }


              return _ReadOnlyDetailsView(
                inStock: state.stock.quantity,
                sell: sell,
                cost: cost,
                stock: state.stock,
                currentQty: state.qty,
                useDesktopNav: useDesktopNav,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ReadOnlyDetailsView extends StatefulWidget {
  final StockVO stock;
  final num currentQty;
  final double cost;
  final double sell;
  final num inStock;
  final bool useDesktopNav;

  const _ReadOnlyDetailsView({
    required this.stock,
    required this.currentQty,
    required this.cost,
    required this.sell,
    required this.inStock,
    required this.useDesktopNav,
  });

  @override
  State<_ReadOnlyDetailsView> createState() => _ReadOnlyDetailsViewState();
}

class _ReadOnlyDetailsViewState extends State<_ReadOnlyDetailsView> {

  String qty = "";

  @override
  void initState() {
    qty = (widget.inStock % 1 == 0)
        ? widget.inStock.toInt().toString()
        : widget.inStock.toString();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = widget.useDesktopNav;
    // Format quantity cleanly (e.g. 5 instead of 5.0)
    final String formattedQty = (widget.currentQty % 1 == 0)
        ? widget.currentQty.toInt().toString()
        : widget.currentQty.toString();
    
    // Desktop sizing
    final double headerPaddingH = useDesktopNav ? 16.0 : 20.0;
    final double headerPaddingTop = useDesktopNav ? 16.0 : 20.0;
    final double headerPaddingBottom = useDesktopNav ? 8.0 : 10.0;
    final double titleFontSize = useDesktopNav ? 15.0 : 18.0;
    final double descFontSize = useDesktopNav ? 12.0 : 14.0;
    final double detailPaddingH = useDesktopNav ? 16.0 : 20.0;
    final double detailPaddingV = useDesktopNav ? 8.0 : 10.0;
    final double sectionPadding = useDesktopNav ? 16.0 : 20.0;
    final double countedQtyFontSize = useDesktopNav ? 15.0 : 18.0;
    final double countedLabelFontSize = useDesktopNav ? 12.0 : 14.0;
    final double borderRadius = useDesktopNav ? 8.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min, // Wrap content height
      children: [
        // --- HEADER ---
        Padding(
          padding: EdgeInsets.fromLTRB(headerPaddingH, headerPaddingTop, headerPaddingH, headerPaddingBottom),
          child: Column(
            children: [
              Text(
                "Stock Details",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              SizedBox(height: useDesktopNav ? 4 : 5),
              Text(
                widget.stock.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white : colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: descFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: isDark ? Colors.white24 : null,
        ),

        // --- SCROLLABLE DETAILS LIST ---
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: detailPaddingH, vertical: detailPaddingV),
            child: Column(
              children: [
                // Highlighted Counted Quantity at the top
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: useDesktopNav ? 8 : 10),
                  padding: EdgeInsets.all(useDesktopNav ? 10 : 12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(useDesktopNav ? 8 : 10),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Counted Quantity:",
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: countedLabelFontSize,
                        ),
                      ),
                      Text(
                        formattedQty,
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: countedQtyFontSize,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildDetailRow(Icons.qr_code, "Barcode", widget.stock.barcode, useDesktopNav),
                _buildDetailRow(
                  Icons.layers_outlined,
                  "Department",
                  widget.stock.deptName ?? "-",
                  useDesktopNav,
                ),
                _buildDetailRow(
                    Icons.category_outlined,
                    "Categories",
                    "${widget.stock.category1 ?? '-'} / ${widget.stock.category2 ?? '-'} / ${widget.stock.category3 ?? '-'}",
                    useDesktopNav),
                _buildDetailRow(
                    Icons.text_fields, "Custom 1", widget.stock.custom1 ?? "-", useDesktopNav),
                _buildDetailRow(
                    Icons.text_fields, "Custom 2", widget.stock.custom2 ?? "-", useDesktopNav),
                _buildDetailRow(Icons.shopping_bag_outlined, "Supplier",
                    widget.stock.supplier, useDesktopNav),
                _buildDetailRow(
                  Icons.attach_money,
                  "Cost Price",
                  FormattingUtils.formatCurrencyWithDecimals(widget.cost, 2),
                  useDesktopNav,
                ),
                _buildDetailRow(
                  Icons.attach_money,
                  "Sell Price",
                  FormattingUtils.formatCurrencyWithDecimals(widget.sell, 2),
                  useDesktopNav,
                ),
                _buildDetailRow(
                  CupertinoIcons.cube_box_fill,
                  "In-Stock",
                  qty,
                  useDesktopNav,
                ),

                // Add more fields if needed
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // --- OKAY BUTTON (Fixed at bottom) ---
        Padding(
          padding: EdgeInsets.all(sectionPadding),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: EdgeInsets.symmetric(vertical: useDesktopNav ? 10 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                elevation: 0,
              ),
                child: Text(
                "OK",
                style: TextStyle(
                  color: colors.onHero,
                  fontWeight: FontWeight.bold,
                  fontSize: useDesktopNav ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool useDesktopNav) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double verticalPadding = useDesktopNav ? 6.0 : 8.0;
    final double iconContainerPadding = useDesktopNav ? 6.0 : 8.0;
    final double iconSize = useDesktopNav ? 14.0 : 16.0;
    final double labelFontSize = useDesktopNav ? 10.0 : 12.0;
    final double valueFontSize = useDesktopNav ? 12.0 : 14.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(iconContainerPadding),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: kPrimaryColor),
          ),
          SizedBox(width: useDesktopNav ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    color: isDark ? Colors.white : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
