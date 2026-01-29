import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

class StockDetailsDialog extends StatelessWidget {
  const StockDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Dynamic height constraint (max 85% of screen height)
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: BlocBuilder<StockDetailsBloc, StockFetchingStates>(
          builder: (context, state) {
            // 1. Loading State
            if (state is StockDetailsLoading) {
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(radius: 15),
                    SizedBox(height: 15),
                    Text(
                      "Fetching details...",
                      style: TextStyle(color: kGreyColor),
                    ),
                  ],
                ),
              );
            }

            // 2. Error State
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
                      style: const TextStyle(color: kGreyColor),
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
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Loaded State - Show Details & Edit Form
            if (state is StockDetailsLoaded) {
              return _EditQuantityForm(
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
    );
  }
}

class _EditQuantityForm extends StatefulWidget {
  final StockVO stock;
  final num currentQty;
  final Function(num newQty) onUpdate;

  const _EditQuantityForm({
    required this.stock,
    required this.currentQty,
    required this.onUpdate,
  });

  @override
  State<_EditQuantityForm> createState() => _EditQuantityFormState();
}

class _EditQuantityFormState extends State<_EditQuantityForm> {
  late TextEditingController _qtyController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    String initialValue = (widget.currentQty % 1 == 0)
        ? widget.currentQty.toInt().toString()
        : widget.currentQty.toString();

    _qtyController = TextEditingController(text: initialValue);

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
    return Column(
      mainAxisSize: MainAxisSize.min, // Wrap content height
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
                style: const TextStyle(
                  color: kThirdColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // --- SCROLLABLE DETAILS LIST ---
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildDetailRow(Icons.qr_code, "Barcode", widget.stock.barcode),
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
                  Icons.layers_outlined,
                  "Stock ID",
                  widget.stock.stockID.toString(),
                ),
                _buildDetailRow(
                  Icons.attach_money,
                  "Sell Price",
                  "\$${widget.stock.sell.toStringAsFixed(2)}",
                ),

                // Add more fields here if needed from StockVO
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // --- EDIT QUANTITY SECTION (Fixed at bottom) ---
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Update Count:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kGreyColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _qtyController,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kThirdColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    //contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                      child: const Text(
                        "Update",
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: kGreyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kThirdColor,
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
