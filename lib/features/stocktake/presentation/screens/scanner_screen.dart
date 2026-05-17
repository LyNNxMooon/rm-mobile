import 'dart:async';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stock_take_list_screen.dart';
import 'package:rmmobile/features/transactions/presentation/screens/stock_selection_screen.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_question_dialog.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/stock_lookup_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';
import '../../../../constants/colors.dart';
//import '../../../../constants/global_widgets.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/enums.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/tax_calculation_utils.dart';
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
  bool _isSearchLoading = false;
  Timer? _searchLoadingTimer;

  // Tax percentages for desktop display
  double _costTaxPercentage = 0.0;
  double _sellTaxPercentage = 0.0;

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

  void _toggleScan() {
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
      // Don't unfocus qty field - allow scanner and qty keyboard together
    });
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
    
    // Close scanner when text fields gain focus
    qtyFocusNode.addListener(_onFocusChange);
    txtFieldFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Only close scanner when manual barcode field gains focus.
    // Qty field should work alongside scanner.
    if (txtFieldFocusNode.hasFocus && isScan) {
      setState(() => isScan = false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    qtyFocusNode.removeListener(_onFocusChange);
    txtFieldFocusNode.removeListener(_onFocusChange);
    _searchLoadingTimer?.cancel();
    scannerController.dispose();
    qtyController.dispose();
    qtyFocusNode.dispose();
    txtFieldFocusNode.dispose();
    _bcController.dispose();
    super.dispose();
  }

  void _startSearchLoadingDelay() {
    _searchLoadingTimer?.cancel();
    _isSearchLoading = false;
    _searchLoadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (context.read<ScannerBloc>().state is StockLoading) {
        setState(() => _isSearchLoading = true);
      }
    });
  }

  void _stopSearchLoading() {
    _searchLoadingTimer?.cancel();
    if (_isSearchLoading && mounted) {
      setState(() => _isSearchLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool useDesktopNav = context.useDesktopNav;

    // Calculate adaptive padding similar to StockDetailsScreen
    final double cardHorizontalPadding = useDesktopNav
        ? 20.0
        : isTablet
            ? (media.size.width * (isLandscape ? 0.045 : 0.04)).clamp(24.0, 56.0)
            : 15.0;

    // Desktop layout - no scanner, cleaner UI
    if (useDesktopNav) {
      return _buildDesktopLayout(context, colors, isDark, cardHorizontalPadding);
    }

    // Mobile/tablet layout with scanner
    return _buildMobileLayout(context, colors, isDark, isTablet, isLandscape, cardHorizontalPadding);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    double cardHorizontalPadding,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Desktop App Bar - no torch icon
                _buildDesktopAppBar(colors, isDark),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mode selector
                              ScanModeSelector(
                                onModeChanged: (newMode) {
                                  setState(() {
                                    isManualCount = (newMode == ScanMode.manualCount);
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
                              const SizedBox(height: 16),

                              // Main content area - vertical layout on desktop
                              // Barcode and count entry on top
                              _buildDesktopInputPanel(isDark, colors),
                              const SizedBox(height: 16),

                              // Item details below
                              BlocConsumer<ScannerBloc, ScannerStates>(
                                builder: (context, state) {
                                  if (state is StockLoaded) {
                                    return _buildDesktopProductPanel(state.stock, isDark, colors);
                                  }
                                  return _buildDesktopProductPanel(null, isDark, colors);
                                },
                                listener: _handleScannerStateChanges,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Stock count save listener
                _stockCountSaveListener(),
              ],
            ),
            if (_isSearchLoading) _buildLoadingOverlay(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopAppBar(AppThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? colors.divider : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.navigateBack(),
            icon: Icon(
              Icons.arrow_back,
              color: colors.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Stocktake - ${(AppGlobals.instance.shopfront ?? "RM-Shopfront").split('\\').last}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProductPanel(StockVO? stock, bool isDark, AppThemeColors colors) {
    String qty = stock == null
        ? "..."
        : ((stock.quantity % 1 == 0)
              ? stock.quantity.toInt().toString()
              : double.parse(stock.quantity.toStringAsFixed(2)).toString());

    String layby = stock == null
        ? "-"
        : ((stock.laybyQuantity % 1 == 0)
              ? stock.laybyQuantity.toInt().toString()
              : double.parse(stock.laybyQuantity.toStringAsFixed(2)).toString());

    String soQty = stock == null
        ? "-"
        : ((stock.salesOrderQuantity % 1 == 0)
              ? stock.salesOrderQuantity.toInt().toString()
              : double.parse(stock.salesOrderQuantity.toStringAsFixed(2)).toString());

    num total = stock == null
        ? 0
        : (stock.quantity + stock.laybyQuantity + stock.salesOrderQuantity);
    final String lastSale = stock == null
        ? "-"
        : _formatLastSaleDate(stock.lastSaleDate);

    String totalString = (total % 1 == 0)
        ? total.toInt().toString()
        : double.parse(total.toStringAsFixed(2)).toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : kSecondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: isDark ? Border.all(color: Colors.white38, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stock == null ? "Stock Barcode" : stock.barcode,
                  style: getSmartTitle(
                    fontSize: 16,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset("assets/images/qty_blue.png", fit: BoxFit.fill),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Qty: $qty",
                      style: const TextStyle(
                        fontSize: 12,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildDesktopDetailRow("Description", stock?.description ?? "RM - Stock Description", isDark, colors),
          _buildDesktopDetailRow("Department", stock?.deptName ?? "-", isDark, colors),
          _buildDesktopDetailRow("Categories", stock == null ? "- / - / -" : "${stock.category1} / ${stock.category2} / ${stock.category3}", isDark, colors),
          _buildDesktopDetailRow(AppGlobals.instance.stockCustom1Label, stock?.custom1 ?? "-", isDark, colors),
          _buildDesktopDetailRow(AppGlobals.instance.stockCustom2Label, stock?.custom2 ?? "-", isDark, colors),
          _buildDesktopDetailRow("Lay-By", layby, isDark, colors),
          _buildDesktopDetailRow("Sales Order", soQty, isDark, colors),
          _buildDesktopDetailRow("Total", totalString, isDark, colors, isBold: true),
          _buildDesktopDetailRow("Last Sale", lastSale, isDark, colors),
          _buildDesktopDetailRow("Cost / Sell Tax", _formatTaxDisplay(stock), isDark, colors),
          _buildDesktopDetailRow("Ex Cost", stock?.costEx != null ? "\$${stock!.costEx!.toStringAsFixed(2)}" : "-", isDark, colors),
          _buildDesktopDetailRow("Inc Cost", stock?.costInc != null ? "\$${stock!.costInc!.toStringAsFixed(2)}" : "-", isDark, colors),
          _buildDesktopDetailRow("Ex RRP", stock?.sellEx != null ? "\$${stock!.sellEx!.toStringAsFixed(2)}" : "-", isDark, colors),
          _buildDesktopDetailRow("Inc RRP", stock?.sellInc != null ? "\$${stock!.sellInc!.toStringAsFixed(2)}" : "-", isDark, colors),
        ],
      ),
    );
  }

  Widget _buildDesktopDetailRow(String label, String value, bool isDark, AppThemeColors colors, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? kPrimaryColor : (isDark ? colors.onSurface : kThirdColor),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInputPanel(bool isDark, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? colors.cardShadow : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Enter Stock",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Barcode input
          TextField(
            controller: _bcController,
            focusNode: txtFieldFocusNode,
            scrollPhysics: const ClampingScrollPhysics(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'Barcode or Description',
              hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: IconButton(
                onPressed: () async {
                  StockVO? selectedStock;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StockLookupScreen(
                        showBackArrow: true,
                        selectionMode: true,
                        onStockSelected: (stock) {
                          selectedStock = stock;
                        },
                      ),
                    ),
                  );
                  if (selectedStock != null && mounted) {
                    setState(() {
                      countingStock = selectedStock;
                      _bcController.text = selectedStock!.barcode;
                    });
                    context.read<ScannerBloc>().add(
                      SelectDuplicateStock(selected: selectedStock!),
                    );
                    qtyFocusNode.requestFocus();
                  }
                },
                icon: const Icon(Icons.search, size: 18),
                color: kPrimaryColor,
              ),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                context.read<ScannerBloc>().add(FetchStockDetails(barcode: trimmed));
              }
              qtyFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 12),

          // Qty input
          TextField(
            controller: qtyController,
            focusNode: qtyFocusNode,
            scrollPhysics: const ClampingScrollPhysics(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: "Counted Qty",
              hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
              filled: true,
              fillColor: colors.surface,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: isManualCount,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              _submitCount();
              txtFieldFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isManualCount && countingStock != null
                  ? () {
                      _submitCount();
                      txtFieldFocusNode.requestFocus();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? colors.surface : Colors.grey.shade200,
                disabledForegroundColor: colors.onSurfaceMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text("Save Count", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),

          // List button
          SizedBox(
            height: 36,
            child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
              builder: (context, state) {
                final count = state is StocktakeListLoaded ? state.totalCount : 0;
                return OutlinedButton.icon(
                  onPressed: () => context.navigateToNext(const StockTakeListScreen()),
                  icon: const Icon(Icons.list, size: 16),
                  label: Text(
                    count > 0 ? "View List ($count)" : "View List",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannerStateChanges(BuildContext context, ScannerStates state) async {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (state is StockLoading) {
      _startSearchLoadingDelay();
    } else {
      _stopSearchLoading();
    }

    if (state is StockDuplicatesFound) {
      countingStock = null;
      final selected = await Navigator.push<StockVO>(
        context,
        MaterialPageRoute(
          builder: (_) => StockSelectionScreen(matches: state.matches),
        ),
      );

      if (selected != null && mounted) {
        context.read<ScannerBloc>().add(SelectDuplicateStock(selected: selected));
        qtyFocusNode.requestFocus();
      } else {
        context.read<ScannerBloc>().add(ResetStocktakeEvent(ScannerInitial()));
      }
    }

    if (state is StockError) {
      countingStock = null;
      AlertInfo.show(
        context: context,
        text: 'Not Found!',
        typeInfo: TypeInfo.error,
        backgroundColor: isDark ? colors.surface : kSecondaryColor,
        iconColor: kErrorColor,
        textColor: kErrorColor,
        position: MessagePosition.top,
        padding: 70,
      );
    }

    if (state is StockLoaded) {
      countingStock = state.stock;

      // Calculate tax percentages for desktop display
      _loadTaxPercentages(state.stock);

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
  }

  Future<void> _loadTaxPercentages(StockVO stock) async {
    try {
      final costResult = await TaxCalculationUtils.calculateCostTax(
        cost: stock.cost,
        goodsTax: stock.goodsTax,
      );
      final sellResult = await TaxCalculationUtils.calculateSellTax(
        sell: stock.sell,
        salesTax: stock.salesTax,
      );

      if (mounted) {
        setState(() {
          _costTaxPercentage = costResult.percentage;
          _sellTaxPercentage = sellResult.percentage;
        });
      }
    } catch (e) {
      // Fallback to 0 if tax calculation fails
      if (mounted) {
        setState(() {
          _costTaxPercentage = 0.0;
          _sellTaxPercentage = 0.0;
        });
      }
    }
  }

  String _formatTaxDisplay(StockVO? stock) {
    if (stock == null) return "- / -";
    
    String formatTaxLabel(String? code, double percentage) {
      final trimmed = (code ?? '').trim();
      if (trimmed.isEmpty) return '-';
      if (percentage <= 0) return trimmed;
      final displayPct = percentage % 1 == 0
          ? percentage.toInt().toString()
          : percentage.toStringAsFixed(2);
      return '$trimmed ($displayPct%)';
    }

    final costTax = formatTaxLabel(stock.goodsTax, _costTaxPercentage);
    final sellTax = formatTaxLabel(stock.salesTax, _sellTaxPercentage);
    return "$costTax / $sellTax";
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
    bool isLandscape,
    double cardHorizontalPadding,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                                  onStartScan: () {
                                    if (!isScan) {
                                      _toggleScan();
                                    }
                                  },
                                  onStopScan: () {
                                    if (isScan) {
                                      _toggleScan();
                                    }
                                  },
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
                                      if (state is StockLoading) {
                                        _startSearchLoadingDelay();
                                      } else {
                                        _stopSearchLoading();
                                      }

                                      if (state is StockDuplicatesFound) {
                                        countingStock = null;

                                        final selected = await Navigator.push<StockVO>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StockSelectionScreen(
                                              matches: state.matches,
                                            ),
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
                                          backgroundColor:
                                              isDark ? colors.surface : kSecondaryColor,
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
            if (_isSearchLoading) _buildLoadingOverlay(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark, AppThemeColors colors) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black45,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetailsPanel(StockVO? stock, double horizontalPadding) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isPortrait = media.orientation == Orientation.portrait;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    // Detect medium-sized tablets (iPad Mini, regular iPad) vs large tablets (iPad Pro 12.9")
    // Medium tablets in portrait typically have height < 1200, large tablets have 1300+
    final bool isMediumTabletPortrait =
        isTablet && isPortrait && media.size.height < 1200;

    // Use reduced portraitBoost for medium tablets to prevent overflow
    final double portraitBoost = isTablet && isPortrait
        ? (isMediumTabletPortrait
              ? (media.size.height / 1000).clamp(1.0, 1.08)
              : (media.size.height / 900).clamp(1.05, 1.25))
        : 1.0;

    // Dynamic Spacing based on device - reduce gaps for medium tablets
    final double sectionGap = isMediumTabletPortrait
      ? 10.0
      : (isTablet ? 16.0 : 8.0) * portraitBoost;
    // final double manualFieldHeight = isMediumTabletPortrait
    //   ? 42 * uiScale
    //   : (isTablet ? 50 : 36) * uiScale * portraitBoost;
  //  final bool isManualFieldFocused = txtFieldFocusNode.hasFocus;
    final double panelVerticalPadding = isMediumTabletPortrait
        ? 18.0
        : (isTablet ? 30.0 : 14.0) * portraitBoost;
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

    // Reduce outer padding for medium tablets
    final double outerVerticalPadding = isMediumTabletPortrait
        ? 10.0
        : (isTablet ? 20 : 8) * portraitBoost;

    return Padding(
      padding: EdgeInsets.only(
        bottom: outerVerticalPadding,
        left: horizontalPadding,
        right: horizontalPadding,
        top: context.isMediumTablet ? 14.0 : outerVerticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: panelVerticalPadding,
              horizontal: panelHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceAlt : kSecondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: isDark
                  ? Border.all(color: Colors.white38, width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? colors.cardShadow
                      : kThirdColor.withOpacity(0.05),
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
                          fontSize: isTablet
                              ? 22
                              : 18, // Scale font up on tablet
                          color: isDark ? colors.onSurface : kThirdColor,
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

          Padding(
            padding: EdgeInsets.only(
              top: isTablet ? 12 : 8,
              bottom: 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bcController,
                    focusNode: txtFieldFocusNode,
                    scrollPhysics: const ClampingScrollPhysics(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Manual Barcode/Desc Entry',
                      hintStyle: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kPrimaryColor),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          StockVO? selectedStock;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StockLookupScreen(
                                showBackArrow: true,
                                selectionMode: true,
                                onStockSelected: (stock) {
                                  selectedStock = stock;
                                },
                              ),
                            ),
                          );
                          if (selectedStock != null && mounted) {
                            setState(() {
                              countingStock = selectedStock;
                              _bcController.text = selectedStock!.barcode;
                            });
                            context.read<ScannerBloc>().add(
                              SelectDuplicateStock(selected: selectedStock!),
                            );
                            qtyFocusNode.requestFocus();
                            qtyController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: qtyController.text.length,
                            );
                          }
                        },
                        icon: const Icon(Icons.double_arrow_rounded),
                        color: kPrimaryColor,
                        iconSize: 22,
                      ),
                    ),
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty) {
                        context.read<ScannerBloc>().add(
                          FetchStockDetails(barcode: trimmed),
                        );
                      }
                      qtyFocusNode.requestFocus();
                      qtyController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: qtyController.text.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Gap between Manual Barcode Entry and Counted Qty
          SizedBox(height: isTablet ? 12 : 6),

          Padding(
            padding: EdgeInsets.only(
              top: isTablet ? 0 : 0,
              bottom: 0,
            ),
            child: TextField(
              controller: qtyController,
              focusNode: qtyFocusNode,
              scrollPhysics: const ClampingScrollPhysics(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Counted Qty",
                hintStyle: TextStyle(
                  color: colors.onSurfaceMuted,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: isManualCount,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _submitCount();
            
                if (!isScan) {
                  txtFieldFocusNode.requestFocus();
                  _bcController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _bcController.text.length,
                  );
                }
              },
            ),
          ),
          SizedBox(
            height: isTablet ? 4 : 6,
          ),

          SizedBox(
            height: isMediumTabletPortrait
                ? 42 * uiScale
                : (isTablet 
                    ? (isPortrait ? 46 * portraitBoost : 62) 
                    : 36 * portraitBoost) * uiScale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
                    builder: (context, state) {
                      final count = state is StocktakeListLoaded ? state.totalCount : 0;
                      return CustomStocktakeBtn(
                        function: () {
                          context.navigateToNext(const StockTakeListScreen());
                        },
                        icon: Icons.list,
                        bgColor: kPrimaryColor,
                        name: count > 0 ? "LIST ($count)" : "LIST",
                      );
                    },
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),

                Expanded(
                  child: CustomStocktakeBtn(
                    function: () {
                      _toggleScan();
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
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? colors.surfaceAlt : Colors.grey.shade200,
            border: Border(
              top: BorderSide(
                color: isDark ? colors.divider : Colors.black12,
              ),
            ),
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
                    fontSize: isTablet ? 18 : 16,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
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
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<StocktakeBloc, StocktakeStates>(
      listener: (context, state) {
        if (state is StocktakeError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );
        }

        if (state is StockTaken) {
          // Refresh the stocktake list count
          context.read<FetchingStocktakeListBloc>().add(FetchStocktakeListEvent());
          
          if (isManualCount) {
            AlertInfo.show(
              context: context,
              text: 'Successfully Counted!',
              typeInfo: TypeInfo.success,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kPrimaryColor,
              textColor: isDark ? colors.onSurface : kThirdColor,
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
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                horizontal: paddingSize,
                vertical: paddingSize,
              ),
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
              style: TextStyle(
                fontSize: fontSize,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
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
              color: isBold
                  ? kPrimaryColor
                  : (isDark ? colors.onSurface : kThirdColor),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
