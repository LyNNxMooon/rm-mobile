import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/utils/ios_done_bar.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/formatting_utils.dart';

class StockDetailsDialog extends StatelessWidget {
  const StockDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double availableHeight = MediaQuery.of(context).size.height - keyboardHeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: keyboardHeight > 0 ? 16 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight - 48,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2733) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BlocBuilder<StockDetailsBloc, StockFetchingStates>(
            builder: (context, state) {
              if (state is StockDetailsLoading) {
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(radius: 15),
                      const SizedBox(height: 15),
                      Text(
                        "Fetching details...",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : kGreyColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is StockDetailsError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: kErrorColor,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : kGreyColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            color: isDark ? colors.onHero : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

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

                return _EditQuantityForm(
                  inStock: state.stock.quantity,
                  sell: sell,
                  cost: cost,
                  stock: state.stock,
                  currentQty: state.qty,
                  onUpdate: (newQty) {
                    Navigator.of(context).pop();
                    context.read<StocktakeBloc>().add(
                      Stocktake(stock: state.stock, qty: newQty.toString()),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _EditQuantityForm extends StatefulWidget {
  final StockVO stock;
  final num currentQty;
  final double cost;
  final double sell;
  final num inStock;
  final Function(num newQty) onUpdate;

  const _EditQuantityForm({
    required this.stock,
    required this.currentQty,
    required this.onUpdate,
    required this.cost,
    required this.sell,
    required this.inStock
  });

  @override
  State<_EditQuantityForm> createState() => _EditQuantityFormState();
}

class _EditQuantityFormState extends State<_EditQuantityForm> {
  late TextEditingController _qtyController;
  final FocusNode _focusNode = FocusNode();

  String qty = "";

  @override
  void initState() {
    super.initState();
    String initialValue = (widget.currentQty % 1 == 0)
        ? widget.currentQty.toInt().toString()
        : widget.currentQty.toString();

    _qtyController = TextEditingController(text: initialValue);

    qty = (widget.inStock % 1 == 0)
        ? widget.inStock.toInt().toString()
        : widget.inStock.toString();


    // Auto-focus logic
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     _focusNode.requestFocus();
    //     _qtyController.selection = TextSelection(
    //       baseOffset: 0,
    //       extentOffset: _qtyController.text.length,
    //     );
    //   }
    // });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    context.read<StockCountUpdateBloc>().add(
      UpdateStockCountEvent(stock: widget.stock, qty: _qtyController.text),
    );

    context.read<FetchingStocktakeListBloc>().add(FetchStocktakeListEvent());

    context.navigateBack();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    children: [
                      Text(
                        "Stock Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                Text(
                  widget.stock.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? Colors.white : kThirdColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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

          // --- DETAILS LIST ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildDetailRow(Icons.qr_code, "Barcode", widget.stock.barcode),
                _buildDetailRow(
                  Icons.layers_outlined,
                  "Department",
                  widget.stock.deptName ?? "-",
                ),
                _buildDetailRow(
                  Icons.category_outlined,
                  "Categories",
                  "${widget.stock.category1 ?? '-'} / ${widget.stock.category2 ?? '-'} / ${widget.stock.category3 ?? '-'}",
                ),
                _buildDetailRow(
                  Icons.text_fields,
                  "Custom 1",
                  widget.stock.custom1 ?? "-",
                ),
                _buildDetailRow(
                  Icons.text_fields,
                  "Custom 2",
                  widget.stock.custom2 ?? "-",
                ),
                _buildDetailRow(
                  Icons.shopping_bag_outlined,
                  "Supplier",
                  widget.stock.supplier,
                ),
                _buildDetailRow(
                  Icons.attach_money,
                  "Cost Price",
                  FormattingUtils.formatCurrencyWithDecimals(widget.cost, 2),
                ),
                _buildDetailRow(
                  Icons.attach_money,
                  "Sell Price",
                  FormattingUtils.formatCurrencyWithDecimals(widget.sell, 2),
                ),
                _buildDetailRow(
                  CupertinoIcons.cube_box_fill,
                  "In-Stock",
                  qty,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white24 : null,
          ),

          // --- EDIT QUANTITY SECTION ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Update Count:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : kGreyColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.surfaceAlt
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _qtyController,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : kThirdColor,
                    ),
                    onEditingComplete: () {
                      final trimmedValue = _qtyController.text.trim();
                      if (_qtyController.text != trimmedValue) {
                        _qtyController.value = _qtyController.value.copyWith(
                          text: trimmedValue,
                          selection: TextSelection.collapsed(offset: trimmedValue.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 22,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _handleUpdate(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Update",
                          style: TextStyle(
                            color: isDark ? colors.onHero : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
        IosDoneBar(
          focusNode: _focusNode,
          onDone: () {
            _focusNode.unfocus();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1), // Icon background
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : kGreyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : kThirdColor,
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
