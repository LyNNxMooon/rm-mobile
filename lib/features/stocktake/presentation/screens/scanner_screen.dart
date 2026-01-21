import 'dart:async';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stock_take_list_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/enums.dart';
import '../../../../utils/log_utils.dart';
import '../BLoC/stocktake_events.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/custom_btn.dart';
import '../widgets/scanner.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

//Common Variables
bool isTorchOn = false;
bool isManualCount = true;
bool isScan = false;
StockVO? countingStock;

final MobileScannerController scannerController = MobileScannerController(
  detectionSpeed: DetectionSpeed.normal,
  detectionTimeoutMs: 1000,
  returnImage: false,
);
final TextEditingController qtyController = TextEditingController();
final FocusNode qtyFocusNode = FocusNode();

//Screen Starts here
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final TextEditingController _bcController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      scannerController.dispose();
      qtyController.dispose();
      qtyFocusNode.dispose();
      _bcController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kBgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const StocktakeAppbarSession(),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 25.0,
                          right: 25,
                          bottom: 10.0,
                          top: 5,
                        ),
                        child: ScanModeSelector(
                          onModeChanged: (newMode) {
                            setState(
                              () => isManualCount =
                                  (newMode == ScanMode.manualCount),
                            );
                          },
                        ),
                      ),

                      Scanner(constraints: constraints),

                      Expanded(
                        child: BlocConsumer<ScannerBloc, ScannerStates>(
                          builder: (context, state) {
                            if (state is StockLoaded) {
                              countingStock = state.stock;

                              return _buildProductDetailsPanel(state.stock);
                            } else {
                              countingStock = null;
                              return _buildProductDetailsPanel(null);
                            }
                          },
                          listener: (context, state) {
                            if (state is StockError) {
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.error(message: state.message),
                              );
                            }
                          },
                        ),
                      ),

                      //Listener for stock count states
                      _stockCountSaveListener(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductDetailsPanel(StockVO? stock) {
    String qty = stock == null
        ? "..."
        : ((stock.quantity % 1 == 0)
              ? stock.quantity.toInt().toString()
              : double.parse(stock.quantity.toStringAsFixed(2)).toString());

    String layby = stock == null
        ? "-"
        : ((stock.laybyQuantity % 1 == 0)
              ? stock.laybyQuantity.toInt().toString()
              : double.parse(
                  stock.laybyQuantity.toStringAsFixed(2),
                ).toString());

    String soQty = stock == null
        ? "-"
        : ((stock.salesOrderQuantity % 1 == 0)
              ? stock.salesOrderQuantity.toInt().toString()
              : double.parse(
                  stock.salesOrderQuantity.toStringAsFixed(2),
                ).toString());
    num total = stock == null
        ? 0
        : (stock.quantity + stock.laybyQuantity + stock.salesOrderQuantity);

    String totalString = (total % 1 == 0)
        ? total.toInt().toString()
        : double.parse(total.toStringAsFixed(2)).toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 25, right: 25, top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),

              boxShadow: [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stock == null ? "Stock Barcode" : stock.barcode,
                        style: getSmartTitle(
                          fontSize: 18,
                          color: kThirdColor,
                        ), // Larger Font
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "In System: $qty",
                        style: const TextStyle(
                          fontSize: 13,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _stockDetailsListTile(
                  color: Colors.green,
                  title: "Description",
                  icon: Icons.description,
                  value: stock == null
                      ? "RM - Stock Description"
                      : stock.description,
                ),
                const SizedBox(height: 8), // Increased Spacing
                _stockDetailsListTile(
                  color: Colors.orangeAccent,
                  title: "Categories",
                  icon: Icons.category_outlined,
                  value: stock == null
                      ? "- / - / -"
                      : "${stock.category1} / ${stock.category2} / ${stock.category3}",
                ),

                const SizedBox(height: 8),
                _stockDetailsListTile(
                  color: Colors.blue,
                  title: "Custom 1",
                  icon: Icons.format_paint,
                  value: stock == null ? "-" : stock.custom1 ?? "-",
                ),
                const SizedBox(height: 8),
                _stockDetailsListTile(
                  color: Colors.deepOrange,
                  title: "Custom 2",
                  icon: Icons.settings,
                  value: stock == null ? "-" : stock.custom2 ?? "-",
                ),
                const SizedBox(height: 8),
                _stockDetailsListTile(
                  color: Colors.purple,
                  title: "Lay-By",
                  icon: Icons.numbers,
                  value: layby,
                ),
                const SizedBox(height: 8),
                _stockDetailsListTile(
                  color: Colors.yellow,
                  title: "Sales Order",
                  icon: Icons.history,
                  value: soQty,
                ),

                const SizedBox(height: 8),
                _stockDetailsListTile(
                  color: Colors.lightBlue,
                  title: "Total",
                  icon: Icons.check,
                  value: totalString,
                  isBold: true, // Make Total Stand Out
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            height: 40, // Taller Input
            child: CustomTextField(
              hintText: 'Manual Barcode Entry',
              controller: _bcController,
              function: (value) {
                _debouncer.run(() {
                  context.read<ScannerBloc>().add(
                    FetchStockDetails(barcode: value),
                  );
                });
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),

              boxShadow: [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  "Counted Qty : ",
                  style: TextStyle(color: kGreyColor, fontSize: 14),
                ), // Larger Label
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 35, // Taller Input
                    width: 100,
                    child: CustomTextField(
                      submitFunction: (value) {
                        if (countingStock != null) {
                          if (context.mounted) {
                            context.read<StocktakeBloc>().add(
                              Stocktake(
                                qty: qtyController.text,
                                stock: countingStock!,
                              ),
                            );
                          }
                        }
                        logger.d("Stocktake saved with: ${qtyController.text}");

                        qtyController.clear();

                        context.read<ScannerBloc>().add(
                          ResetStocktakeEvent(ScannerInitial()),
                        );

                        setState(() {
                          _bcController.text = "";
                        });
                      },
                      controller: qtyController,
                      focusNode: qtyFocusNode,
                      hintText: "Qty",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      isEnabled: isManualCount,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomStocktakeBtn(
                  function: () {
                    context.read<FetchingStocktakeListBloc>().add(
                      FetchStocktakeListEvent(),
                    );
                    context.navigateToNext(const StockTakeListScreen());
                  },
                  icon: Icons.list,
                  bgColor: kPrimaryColor,
                  name: "LIST",
                ),
              ),
              const SizedBox(width: 15),

              Expanded(
                child: CustomStocktakeBtn(
                  function: () {
                    qtyController.clear();
                    context.read<ScannerBloc>().add(
                      ResetStocktakeEvent(ScannerInitial()),
                    );

                    setState(() {
                      isScan = !isScan;
                      _bcController.text = "";
                    });
                  },
                  icon: Icons.qr_code_scanner,
                  bgColor: Colors.lightGreen,
                  name: isScan ? "CLOSE" : "SCAN",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockCountSaveListener() {
    return BlocListener<StocktakeBloc, StocktakeStates>(
      listener: (context, state) {
        if (state is StocktakeError) {
          showTopSnackBar(
            Overlay.of(context),

            CustomSnackBar.error(message: state.message),
          );
        }

        if (state is StockTaken) {
          qtyController.clear();

          if (isManualCount) {
            AlertInfo.show(
              context: context,

              text: 'Successfully Counted!',

              typeInfo: TypeInfo.success,

              backgroundColor: kSecondaryColor,

              iconColor: kPrimaryColor,

              textColor: kThirdColor,
            );
          }
        }
      },

      child: const SizedBox(),
    );
  }

  Widget _stockDetailsListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 16, color: color), // Icon Size bump
            ),

            const SizedBox(width: 8),

            Text(
              title,
              style: const TextStyle(fontSize: 13, color: kGreyColor),
            ), // Increased Font
          ],
        ),

        // Flexible Value Text to avoid overflow
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14, // Increased Font
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? kPrimaryColor : kThirdColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
