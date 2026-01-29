import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart'; // Adjust if needed
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart'; // Adjust if needed

class StockDetailsReadOnlyDialog extends StatelessWidget {
  const StockDetailsReadOnlyDialog({super.key});

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
        // We reuse the same BlocBuilder to fetch data, but show a different UI
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
                    Text("Fetching details...", style: TextStyle(color: kGreyColor)),
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
                    const Icon(Icons.error_outline, color: kErrorColor, size: 40),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Close", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            // 3. Loaded State - Show Read-Only View
            if (state is StockDetailsLoaded) {
              return _ReadOnlyDetailsView(
                stock: state.stock,
                currentQty: state.qty,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ReadOnlyDetailsView extends StatelessWidget {
  final StockVO stock;
  final num currentQty;

  const _ReadOnlyDetailsView({
    required this.stock,
    required this.currentQty,
  });

  @override
  Widget build(BuildContext context) {
    // Format quantity cleanly (e.g. 5 instead of 5.0)
    final String formattedQty = (currentQty % 1 == 0)
        ? currentQty.toInt().toString()
        : currentQty.toString();

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
                stock.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kThirdColor, fontWeight: FontWeight.w600, fontSize: 14),
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
                // Highlighted Counted Quantity at the top
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Counted Quantity:",
                        style: TextStyle(
                          color: kThirdColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formattedQty,
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildDetailRow(Icons.qr_code, "Barcode", stock.barcode),
                _buildDetailRow(
                    Icons.category_outlined,
                    "Categories",
                    "${stock.category1 ?? '-'} / ${stock.category2 ?? '-'} / ${stock.category3 ?? '-'}"),
                _buildDetailRow(
                    Icons.text_fields, "Custom 1", stock.custom1 ?? "-"),
                _buildDetailRow(
                    Icons.text_fields, "Custom 2", stock.custom2 ?? "-"),
                _buildDetailRow(Icons.shopping_bag_outlined, "Supplier",
                    stock.supplier),
                _buildDetailRow(Icons.layers_outlined, "Stock ID",
                    stock.stockID.toString()),
                _buildDetailRow(
                    Icons.attach_money,
                    "Sell Price",
                    "\$${stock.sell.toStringAsFixed(2)}"),
                
                // Add more fields if needed
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // --- OKAY BUTTON (Fixed at bottom) ---
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Okay",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
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