import 'dart:async';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stock_take_list_screen.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/widgets/duplicate_stock_dialog.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/widgets/stocktake_question_dialog.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/enums.dart';
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

//Screen Starts here
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final TextEditingController _bcController = TextEditingController();
  //Common Variables
  bool isTorchOn = false;
  bool isManualCount = true;
  bool isScan = false;
  StockVO? countingStock;

  late MobileScannerController scannerController;
  final TextEditingController qtyController = TextEditingController();
  final FocusNode qtyFocusNode = FocusNode();
  final FocusNode txtFieldFocusNode = FocusNode();

  String? _lastAutoBarcode;
  int _autoQty = 0;

  // Helper to handle saving the count
  void _submitCount() {
    if (countingStock == null) {
      if (isManualCount) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: "No valid stock selected!"),
        );
      }
      return;
    }

    final qtyText = qtyController.text.trim();
    if (qtyText.isEmpty) return;

    if (countingStock!.barcode == qtyText) {
      showDialog(
        context: context,
        builder: (context) => StocktakeQuestionDialog(
          title: "RetailManager Question",
          message:
              "The same number has been entered for Stock Code and Count. Is this correct?",
          onYesPressed: () {
            _dispatchStocktake(qtyText);
            context.navigateBack();
          },
          onNoPressed: () {
            context.navigateBack();
          },
        ),
      );
      return;
    }

    // Normal submission
    _dispatchStocktake(qtyText);
  }

  void _dispatchStocktake(String qty) {
    context.read<StocktakeBloc>().add(
      Stocktake(qty: qty, stock: countingStock!),
    );

    if (isManualCount) {
      qtyController.clear();
      setState(() {
        _bcController.clear();
        countingStock = null;
      });

      context.read<ScannerBloc>().add(ResetStocktakeEvent(ScannerInitial()));
    }
  }

  void _submitAutoCount() {
    if (countingStock == null) return;

    context.read<StocktakeBloc>().add(
      Stocktake(qty: "1", stock: countingStock!),
    );
  }

  String _formatLastSaleDate(String? rawValue) {
    final raw = (rawValue ?? "").trim();
    if (raw.isEmpty) return "-";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat("dd MMM yyyy, hh:mm a").format(parsed.toLocal());
  }

  @override
  void initState() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      returnImage: false,
    );
    super.initState();
  }

  @override
  void dispose() {
    scannerController.dispose();
    qtyController.dispose();
    qtyFocusNode.dispose();
    txtFieldFocusNode.dispose();
    _bcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isLandscape = media.orientation == Orientation.landscape;
    
    // Calculate adaptive padding similar to StockDetailsScreen
    final double cardHorizontalPadding = isTablet
        ? (media.size.width * (isLandscape ? 0.045 : 0.04)).clamp(24.0, 56.0)
        : 15.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            StocktakeAppbarSession(
                              onTorchToggle: () {
                                setState(() {
                                  scannerController.toggleTorch();
                                  isTorchOn = !isTorchOn;
                                });
                              },
                              isTorchOn: isTorchOn,
                            ),

                            Padding(
                              padding: EdgeInsets.only(
                                left: cardHorizontalPadding,
                                right: cardHorizontalPadding,
                                bottom: isTablet ? 15.0 : 10.0,
                                top: isTablet ? 15.0 : 5.0,
                              ),
                              child: ScanModeSelector(
                                onModeChanged: (newMode) {
                                  setState(() {
                                    isManualCount =
                                        (newMode == ScanMode.manualCount);

                                    qtyController.clear();
                                    _bcController.clear();
                                    countingStock = null;
                                    _lastAutoBarcode = null;
                                    _autoQty = 0;
                                    context.read<ScannerBloc>().add(
                                      ResetStocktakeEvent(ScannerInitial()),
                                    );
                                  });
                                },
                              ),
                            ),

                            Scanner(
                              constraints: constraints,
                              controller: scannerController,
                              isScan: isScan,
                              isManualCount: isManualCount,
                              horizontalPadding: cardHorizontalPadding,
                              onScan: (String barcode) {
                                context.read<ScannerBloc>().add(
                                  FetchStockDetails(barcode: barcode),
                                );

                                if (isManualCount) {
                                  qtyFocusNode.requestFocus();
                                  qtyController.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: qtyController.text.length,
                                  );
                                }
                              },
                            ),

                            Expanded(
                              child: BlocConsumer<ScannerBloc, ScannerStates>(
                                builder: (context, state) {
                                  if (state is StockLoaded) {
                                    return _buildProductDetailsPanel(
                                      state.stock,
                                      cardHorizontalPadding, // pass to panel
                                    );
                                  } else {
                                    return _buildProductDetailsPanel(
                                      null, 
                                      cardHorizontalPadding, // pass to panel
                                    );
                                  }
                                },
                                listener: (context, state) async {
                                  if (state is StockDuplicatesFound) {
                                    countingStock = null;

                                    final selected = await showDialog<StockVO>(
                                      context: context,
                                      builder: (_) => DuplicateStockDialog(
                                        matches: state.matches,
                                      ),
                                    );

                                    if (selected != null && mounted) {
                                      context.read<ScannerBloc>().add(
                                        SelectDuplicateStock(
                                          selected: selected,
                                        ),
                                      );

                                      qtyFocusNode.requestFocus();
                                      qtyController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: qtyController.text.length,
                                      );
                                    } else {
                                      context.read<ScannerBloc>().add(
                                        ResetStocktakeEvent(ScannerInitial()),
                                      );
                                    }
                                  }
                                  if (state is StockError) {
                                    countingStock = null;

                                    AlertInfo.show(
                                      context: context,
                                      text: 'Not Found!',
                                      typeInfo: TypeInfo.error,
                                      backgroundColor: kSecondaryColor,
                                      iconColor: kErrorColor,
                                      textColor: kErrorColor,
                                      position: MessagePosition.top,
                                      padding: 70,
                                    );
                                  }
                                  if (state is StockLoaded) {
                                    countingStock = state.stock;
                                    if (!isManualCount && isScan) {
                                      final barcode = state.stock.barcode;

                                      if (_lastAutoBarcode == barcode) {
                                        ++_autoQty;
                                      } else {
                                        _lastAutoBarcode = barcode;
                                        _autoQty = 1;
                                      }

                                      qtyController.text = _autoQty.toString();
                                      _submitAutoCount();
                                    }
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
            _iosDoneBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsPanel(StockVO? stock, double horizontalPadding) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isPortrait = media.orientation == Orientation.portrait;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    final double portraitBoost = isTablet && isPortrait
      ? (media.size.height / 900).clamp(1.05, 1.25)
      : 1.0;

    // Dynamic Spacing based on device
    final double sectionGap = (isTablet ? 16.0 : 8.0) * portraitBoost;
    final double panelVerticalPadding =
      (isTablet ? 30.0 : 14.0) * portraitBoost;
    final double panelHorizontalPadding = isTablet ? 24.0 : 12.0;

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
    final String lastSale = stock == null
        ? "-"
        : _formatLastSaleDate(stock.lastSaleDate);

    String totalString = (total % 1 == 0)
        ? total.toInt().toString()
        : double.parse(total.toStringAsFixed(2)).toString();

    return Padding(
      padding: EdgeInsets.only(
          bottom: (isTablet ? 20 : 8) * portraitBoost,
          left: horizontalPadding,
          right: horizontalPadding,
          top: (isTablet ? 20 : 8) * portraitBoost),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                vertical: panelVerticalPadding,
                horizontal: panelHorizontalPadding),
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
                          fontSize: isTablet ? 22 : 18, // Scale font up on tablet
                          color: kThirdColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 8,
                        vertical: isTablet ? 8 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: isTablet ? 30 : 25,
                            height: isTablet ? 30 : 25,
                            child: Image.asset(
                              "assets/images/qty_blue.png",
                              fit: BoxFit.fill,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Qty On-Hand: $qty",
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 20 : 10),

                _stockDetailsListTile(
                  image: "assets/images/desc_blue.png",
                  color: kPrimaryColor,
                  title: "Description",
                  icon: Icons.description,
                  value: stock == null
                      ? "RM - Stock Description"
                      : stock.description,
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/dept_blue.png",
                  color: kPrimaryColor,
                  title: "Department",
                  icon: Icons.description,
                  value: stock == null ? "-" : stock.deptName ?? "-",
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/cat_blue.png",
                  color: Colors.orangeAccent,
                  title: "Categories",
                  icon: Icons.category_outlined,
                  value: stock == null
                      ? "- / - / -"
                      : "${stock.category1} / ${stock.category2} / ${stock.category3}",
                ),

                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/cus1_blue.png",
                  color: Colors.blue,
                  title: "Custom 1",
                  icon: Icons.format_paint,
                  value: stock == null ? "-" : stock.custom1 ?? "-",
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/cus2_blue.png",
                  color: Colors.deepOrange,
                  title: "Custom 2",
                  icon: Icons.settings,
                  value: stock == null ? "-" : stock.custom2 ?? "-",
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/layby_blue.png",
                  color: Colors.purple,
                  title: "Lay-By",
                  icon: Icons.numbers,
                  value: layby,
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/so_blue.png",
                  color: Colors.yellow,
                  title: "Sales Order",
                  icon: Icons.history,
                  value: soQty,
                ),

                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/total_blue.png",
                  color: Colors.lightBlue,
                  title: "Total",
                  icon: Icons.check,
                  value: totalString,
                  isBold: true,
                ),
                SizedBox(height: sectionGap),
                _stockDetailsListTile(
                  image: "assets/images/so_blue.png",
                  color: Colors.yellow,
                  title: "Last Sale",
                  icon: Icons.schedule,
                  value: lastSale,
                ),
              ],
            ),
          ),

          Container(
            margin: EdgeInsets.symmetric(
                vertical: (isTablet ? 15 : 8) * portraitBoost),
            height: (isTablet ? 50 : 36) * uiScale * portraitBoost,
            child: CustomTextField(
              focusNode: txtFieldFocusNode,
              submitFunction: (_) {
                qtyFocusNode.requestFocus();
                qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: qtyController.text.length,
                );
              },
              hintText: 'Manual Barcode/Desc Entry',
              controller: _bcController,
              function: (value) {
                if (value.trim().isEmpty) {
                  return; // Do nothing
                }
                _debouncer.run(() {
                  context.read<ScannerBloc>().add(
                    FetchStockDetails(barcode: value),
                  );
                });
              },
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(
                vertical: isTablet ? 14 : 8,
                horizontal: isTablet ? 20 : 12),
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
                Text(
                  "Counted Qty : ",
                  style: TextStyle(
                      color: kGreyColor, fontSize: isTablet ? 16 : 14),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: (isTablet ? 45 : 33) * uiScale * portraitBoost,
                    width: 100,
                    child: CustomTextField(
                      submitFunction: (value) {
                        _submitCount();

                        if (!isScan) {
                          txtFieldFocusNode.requestFocus();
                          _bcController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _bcController.text.length,
                          );
                        }
                      },
                      controller: qtyController,
                      focusNode: qtyFocusNode,
                      hintText: "Qty",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      isEnabled: isManualCount,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: (isTablet ? 15 : 3) * portraitBoost),

          SizedBox(
            height: (isTablet ? 60 : 45) * uiScale * portraitBoost,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomStocktakeBtn(
                    function: () {
                      context.navigateToNext(const StockTakeListScreen());
                    },
                    icon: Icons.list,
                    bgColor: kPrimaryColor,
                    name: "LIST",
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),

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
                        countingStock = null;

                        _lastAutoBarcode = null;
                        _autoQty = 0;

                        txtFieldFocusNode.unfocus();
                        qtyFocusNode.unfocus();
                      });
                    },
                    icon: Icons.qr_code_scanner,
                    bgColor: isScan ? Colors.redAccent : Colors.lightGreen,
                    name: isScan ? "STOP" : "SCAN",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iosDoneBar() {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return const SizedBox();
    }

    return AnimatedBuilder(
      animation: qtyFocusNode,
      builder: (context, _) {
        if (!qtyFocusNode.hasFocus) return const SizedBox();

        return Container(
          height: (isTablet ? 48 : 44) * uiScale,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: const Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  qtyFocusNode.unfocus(); // hide keyboard
                  _submitCount(); // save qty
                  if (!isScan) {
                    txtFieldFocusNode.requestFocus();
                    _bcController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _bcController.text.length,
                    );
                  }
                },
                child: Text(
                  "Done",
                  style: TextStyle(
                      fontSize: isTablet ? 18 : 16, color: kThirdColor),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
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
          if (isManualCount) {
            AlertInfo.show(
              context: context,
              text: 'Successfully Counted!',
              typeInfo: TypeInfo.success,
              backgroundColor: kSecondaryColor,
              iconColor: kPrimaryColor,
              textColor: kThirdColor,
              padding: 70,
              position: MessagePosition.top,
            );
          }
        }
      },
      child: const SizedBox(),
    );
  }

  Widget _stockDetailsListTile({
    required String image,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    // Dynamic sizing based on device context
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double iconSize = isTablet ? 26.0 : 20.0;
    final double fontSize = isTablet ? 16.0 : 14.0;
    final double paddingSize = isTablet ? 8.0 : 5.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: paddingSize, vertical: paddingSize),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Image.asset(image, fit: BoxFit.fill),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              title,
              style: TextStyle(fontSize: fontSize, color: kGreyColor),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: fontSize,
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