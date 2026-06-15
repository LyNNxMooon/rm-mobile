// ignore_for_file: avoid_print

import 'dart:async';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/batch_commit_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stock_take_list_screen.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/edit_qty_dialog.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_trial_limit_info.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_search_and_filter_bar.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/batch_commit_progress_widget.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/transactions_detected_dialog.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_success_dialog.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_commit_error_dialog.dart';
import 'package:rmmobile/features/transactions/presentation/screens/stock_selection_screen.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stocktake_question_dialog.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/stock_lookup_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/local_db/sqlite/sqlite_constants.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../constants/images.dart';
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

  void dispose() {
    _timer?.cancel();
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

  // Selected items for deletion
  final Set<int> _selectedStockIds = {};

  // "Alert repeating counted stocks" setting (persistent, default off)
  bool _alertRepeatingCounts = false;

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

    _runRepeatCheckThen(() => _continueSubmitCount(qtyText));
  }

  void _continueSubmitCount(String qtyText) {
    if (countingStock == null) return;

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

    // Load stocktake list for desktop layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.useDesktopNav) {
        context.read<FetchingStocktakeListBloc>().add(FetchStocktakeListEvent(reset: true));
        context.read<StocktakeLimitBloc>().add(FetchStocktakeLimitEvent());
      }
    });

    _loadAlertRepeatingCountsSetting();
  }

  Future<void> _loadAlertRepeatingCountsSetting() async {
    final String? value = await LocalDbDAO.instance.getAppConfig(
      kStocktakeAlertRepeatedCountsKey,
    );
    if (!mounted) return;
    setState(() {
      _alertRepeatingCounts = value == "true";
    });
  }

  void _toggleAlertRepeatingCounts() {
    final bool newValue = !_alertRepeatingCounts;
    setState(() => _alertRepeatingCounts = newValue);
    LocalDbDAO.instance.saveAppConfig(
      kStocktakeAlertRepeatedCountsKey,
      newValue.toString(),
    );
  }

  /// When the "Alert repeating counted stocks" setting is on, checks whether the
  /// currently selected stock was already counted (in this session) or sent to
  /// the shopfront within the last 24 hours. If so, prompts the user before
  /// continuing; otherwise proceeds immediately.
  Future<void> _runRepeatCheckThen(
    VoidCallback proceed, {
    VoidCallback? onCancel,
  }) async {
    final StockVO? stock = countingStock;
    if (stock == null || !_alertRepeatingCounts) {
      proceed();
      return;
    }

    final Map<String, dynamic>? info = await LocalDbDAO.instance
        .getExistingStocktakeCount(
          stockId: stock.stockID.toInt(),
          shopfront: AppGlobals.instance.shopfront ?? "",
        );
    if (!mounted) return;

    if (info == null) {
      proceed();
      return;
    }

    final bool fromHistory = info['source'] == 'history';
    final String source = fromHistory ? 'sent to the shopfront' : 'counted';
    final num qty = info['quantity'] as num;

    showDialog(
      context: context,
      builder: (dialogContext) => StocktakeQuestionDialog(
        title: "RetailManager Question",
        message:
            "This item has already been $source with a count of $qty. Are you sure you want to count it again?",
        onYesPressed: () {
          Navigator.of(dialogContext).pop();
          proceed();
        },
        onNoPressed: () {
          Navigator.of(dialogContext).pop();
          onCancel?.call();
        },
      ),
    );
  }

  void _onFocusChange() {
    // Only close scanner when manual barcode field gains focus.
    if (txtFieldFocusNode.hasFocus && isScan) {
      setState(() => isScan = false);
    }
    
    // Pause scanner when qty field has focus, resume when unfocused
    if (qtyFocusNode.hasFocus && isScan) {
      // Pause scanning while user enters count
      scannerController.stop();
    } else if (!qtyFocusNode.hasFocus && isScan) {
      // Resume scanning when qty field loses focus
      scannerController.start();
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
    _desktopSearchDebouncer.dispose();
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

  // Desktop search query state
  String _desktopSearchQuery = "";
  final Debouncer _desktopSearchDebouncer = Debouncer(milliseconds: 500);

  Widget _buildDesktopLayout(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    double cardHorizontalPadding,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? Colors.black : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Desktop App Bar - no torch icon
                _buildDesktopAppBar(colors, isDark),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final leftPanelWidth = constraints.maxWidth * 0.45;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Input and stock details (45% width)
                          SizedBox(
                            width: leftPanelWidth,
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.all(16),
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

                                  // Barcode and count entry
                                  _buildDesktopInputPanelNoListButton(isDark, colors),
                                  const SizedBox(height: 16),

                                  // Item details - full panel
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

                          // Divider
                          Container(
                            width: 1,
                            color: isDark ? colors.divider : Colors.grey.shade200,
                          ),

                          // Right side - Stocktake list table
                          Expanded(
                            child: _buildDesktopStocktakeListPanel(isDark, colors),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Stock count save listener
                _stockCountSaveListener(),
                // Batch commit listener
                _batchCommitListener(),
                // Delete listener
                _stocktakeDeleteListener(),
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
              Icons.home_filled,
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
            // Disable autocorrect and predictive text
            autocorrect: false,
            enableSuggestions: false,
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
              child: const Text("Save Count", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),

          // List button
          SizedBox(
            height: 36,
            child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
              builder: (context, state) {
                final count = state is StocktakeListLoaded ? state.totalCount : 0;
                return ElevatedButton.icon(
                  onPressed: () => context.navigateToNext(const StockTakeListScreen()),
                  icon: const Icon(Icons.list, size: 16, color: Colors.white),
                  label: Text(
                    count > 0 ? "View List ($count)" : "View List",
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
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

  /// Compact input panel for desktop two-column layout
  /// Input panel for desktop two-column layout (no View List button)
  Widget _buildDesktopInputPanelNoListButton(bool isDark, AppThemeColors colors) {
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
            // Disable autocorrect and predictive text
            autocorrect: false,
            enableSuggestions: false,
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
        ],
      ),
    );
  }

  /// Desktop stocktake list panel with search, trial info, commit button, and table view
  Widget _buildDesktopStocktakeListPanel(bool isDark, AppThemeColors colors) {
    return Column(
      children: [
        // Header with title and history button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              Expanded(
                child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
                  builder: (context, state) {
                    final count = state is StocktakeListLoaded ? state.totalCount : 0;
                    return Text(
                      count > 0 ? "Counted Items ($count)" : "Counted Items",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () => context.navigateToNext(const StocktakeHistoryScreen()),
                icon: Icon(
                  Icons.history,
                  color: kPrimaryColor,
                  size: 20,
                ),
                tooltip: "View History",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),

        // Trial limit info
        const StocktakeTrialLimitInfo(),

        // Batch commit progress
        const BatchCommitProgressWidget(),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: StocktakeSearchAndFilterBar(
            onChanged: (value) {
              _desktopSearchQuery = value;
              _desktopSearchDebouncer.run(() {
                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(
                    reset: true,
                    query: _desktopSearchQuery,
                  ),
                );
              });
            },
            onFilterTap: () {},
          ),
        ),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : kSecondaryColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
            builder: (context, state) {
              final items = state is StocktakeListLoaded ? state.stocktakeList : <CountedStockVO>[];
              final allSelected = items.isNotEmpty && items.every((item) => _selectedStockIds.contains(item.stockID));
              return Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: allSelected,
                      onChanged: items.isEmpty ? null : (value) {
                        setState(() {
                          if (value == true) {
                            _selectedStockIds.addAll(items.map((e) => e.stockID));
                          } else {
                            _selectedStockIds.clear();
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Barcode',
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 12,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Cat1 / Cat2 / Cat3',
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Table rows
        Expanded(
          child: BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
            builder: (context, state) {
              if (state is LoadingStocktakeList) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (state is StocktakeListError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colors.onSurfaceMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Error: ${state.message}",
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (state is StocktakeListLoaded) {
                final items = state.stocktakeList;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: colors.onSurfaceMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No items counted yet",
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildStocktakeTableRow(item, isDark, colors, index);
                  },
                );
              }

              return Center(
                child: Text(
                  "Scan items to start counting",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceMuted,
                  ),
                ),
              );
            },
          ),
        ),

        // Commit button
        _buildDesktopCommitButton(isDark, colors),
      ],
    );
  }

  Widget _buildDesktopCommitButton(bool isDark, AppThemeColors colors) {
    final hasSelected = _selectedStockIds.isNotEmpty;
    return BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
      builder: (context, state) {
        final hasItems = state is StocktakeListLoaded && state.totalCount > 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? colors.surface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? colors.divider : Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              // Delete Selected button
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: hasSelected ? _handleDeleteSelectedStocktake : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    hasSelected ? "Delete (${_selectedStockIds.length})" : "Delete",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kErrorColor,
                    side: BorderSide(color: hasSelected ? kErrorColor : colors.onSurfaceMuted.withOpacity(0.3)),
                    disabledForegroundColor: colors.onSurfaceMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send to RM button
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: hasItems ? _handleDesktopCommit : null,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text(
                      "Send to RM",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? colors.surface : Colors.grey.shade200,
                      disabledForegroundColor: colors.onSurfaceMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDeleteSelectedStocktake() {
    final count = _selectedStockIds.length;
    showDialog(
      context: context,
      builder: (context) => StocktakeQuestionDialog(
        title: "RetailManager Question",
        message: "Are you sure you want to delete $count selected item${count > 1 ? 's' : ''}? This action cannot be undone.",
        onYesPressed: () {
          context.navigateBack();
          this.context.read<StocktakeDeleteBloc>().add(
            DeleteSelectedStocktakeEvent(_selectedStockIds.toList()),
          );
          setState(() {
            _selectedStockIds.clear();
          });
        },
        onNoPressed: () {
          context.navigateBack();
        },
      ),
    );
  }

  void _handleDesktopCommit() {
    context.read<BatchCommitBloc>().add(StartBatchCommitEvent());
  }

  Widget _batchCommitListener() {
    return BlocListener<BatchCommitBloc, BatchCommitState>(
      listener: (context, state) {
        if (state is BatchCommitAwaitingAuditDecision) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => TransactionsDetectedDialog(
              rows: state.audits,
              isBatchMode: true,
              currentBatchNumber: state.currentBatchNumber,
              totalBatches: state.totalBatches,
            ),
          );
        } else if (state is BatchCommitEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No unsynced stocks found."),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (state is BatchCommitFailed) {
          context.read<StocktakeLimitBloc>().add(FetchStocktakeLimitEvent());
          showDialog(
            context: context,
            builder: (_) => StocktakeCommitErrorDialog(message: state.message),
          );
        } else if (state is BatchCommitCompleted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StocktakeSuccessDialog(
              message: "The Stocktake has been sent to your Shopfront!\n\nTo finalise the stocktake, go to your Shopfront in RetailManager and open the Stocktake window, Run the Discrepancy Report, Make any changes if required and Commit the Stocktake.",
              onOkayPressed: () {
                Navigator.of(ctx).pop();
                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(reset: true),
                );
                context.read<StocktakeLimitBloc>().add(
                  FetchStocktakeLimitEvent(),
                );
                context.read<BatchCommitBloc>().add(CancelBatchCommitEvent());
              },
            ),
          );
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _stocktakeDeleteListener() {
    return BlocListener<StocktakeDeleteBloc, StocktakeDeleteStates>(
      listener: (context, state) {
        if (state is StocktakeDeleted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: state.message),
          );
          context.read<FetchingStocktakeListBloc>().add(
            FetchStocktakeListEvent(reset: true, query: _desktopSearchQuery),
          );
        } else if (state is StocktakeDeleteError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );
        }
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildStocktakeTableRow(CountedStockVO item, bool isDark, AppThemeColors colors, int index) {
    final isSelected = _selectedStockIds.contains(item.stockID);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditDialog(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? kPrimaryColor.withOpacity(0.15) : kPrimaryColor.withOpacity(0.08)) : null,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedStockIds.add(item.stockID);
                      } else {
                        _selectedStockIds.remove(item.stockID);
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.barcode,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  item.description,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatCategories(item),
                  style: TextStyle(
                    color: colors.onSurfaceMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  _formatQty(item.inStock),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  _formatQty(item.quantity),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(num qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
  }

  String _formatCategories(CountedStockVO item) {
    final cat1 = item.category1 ?? '-';
    final cat2 = item.category2 ?? '-';
    final cat3 = item.category3 ?? '-';
    return '$cat1 / $cat2 / $cat3';
  }

  void _showEditDialog(CountedStockVO item) {
    context.read<StockDetailsBloc>().add(
      FetchStockDetailsByID(
        stockId: item.stockID,
        qty: item.quantity,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => const StockDetailsDialog(),
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
          qtyController.text = _autoQty.toString();
          _submitAutoCount();
        } else {
          _lastAutoBarcode = barcode;
          _autoQty = 1;
          qtyController.text = _autoQty.toString();
          // First scan of this barcode this run: alert if already counted/sent.
          _runRepeatCheckThen(
            _submitAutoCount,
            onCancel: () {
              _lastAutoBarcode = null;
              _autoQty = 0;
              qtyController.clear();
            },
          );
        }
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
      backgroundColor: isDark ? Colors.black : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isTabletLandscape = isTablet && isLandscape;

                      final Widget scanModeSelector = ScanModeSelector(
                        vertical: isTabletLandscape,
                        fontSize: isTabletLandscape ? 16 : 12.5,
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
                      );

                      final Widget scannerWidget = Scanner(
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
                          print('📷 BARCODE SCANNED: $barcode');
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
                      );

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
                                  alertRepeatingCounts: _alertRepeatingCounts,
                                  onToggleAlertRepeatingCounts:
                                      _toggleAlertRepeatingCounts,
                                ),

                                if (isTabletLandscape) ...[
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: cardHorizontalPadding,
                                      right: cardHorizontalPadding,
                                      bottom: isTablet ? 15.0 : 10.0,
                                      top: isTablet ? 15.0 : 5.0,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20.0 : 12.0,
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          final double gap =
                                              isTablet ? 20.0 : 12.0;
                                          final double innerPad =
                                              isTablet ? 20.0 : 12.0;
                                          final double rowWidth =
                                              constraints.maxWidth -
                                                  2 * cardHorizontalPadding -
                                                  2 * innerPad;
                                          final double columnWidth =
                                              (rowWidth - 2 * gap) / 3;
                                          final double cameraWidth =
                                              columnWidth * 2 + gap;
                                          return IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(
                                                  width: cameraWidth,
                                                  child: scannerWidget,
                                                ),
                                                SizedBox(width: gap + 22),
                                                Expanded(
                                                  child: scanModeSelector,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  if (isTablet) SizedBox(height: 40),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: cardHorizontalPadding,
                                      right: cardHorizontalPadding,
                                      bottom: isTablet ? 15.0 : 10.0,
                                      top: isTablet ? 15.0 : 5.0,
                                    ),
                                    child: scanModeSelector,
                                  ),
                                  if (isTablet) SizedBox(height: 56),
                                  scannerWidget,
                                ],

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
                                            qtyController.text =
                                                _autoQty.toString();
                                            _submitAutoCount();
                                          } else {
                                            _lastAutoBarcode = barcode;
                                            _autoQty = 1;
                                            qtyController.text =
                                                _autoQty.toString();
                                            _runRepeatCheckThen(
                                              _submitAutoCount,
                                              onCancel: () {
                                                _lastAutoBarcode = null;
                                                _autoQty = 0;
                                                qtyController.clear();
                                              },
                                            );
                                          }
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
    final bool isTabletLandscape = isTablet && !isPortrait;
    //final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    //final double uiScale = isTablet
    //    ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
     //   : 1.0;

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

    // Label style matching the "EXT DESCRIPTION" header on stock_details_screen.
    final TextStyle sectionLabelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade500,
    );
    final TextStyle detailValueStyle = TextStyle(
      fontSize: isTablet ? 16 : 14,
      fontWeight: FontWeight.w500,
      color: isDark ? colors.onSurface : kThirdColor,
    );

    final String inStockDisp = stock == null ? "-" : qty;
    final String totalDisp = stock == null ? "-" : totalString;

    Widget expectedRow(String label, String value, {bool bold = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: sectionGap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? colors.onSurfaceMuted : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: isDark ? colors.onSurface : kThirdColor,
              ),
            ),
          ],
        ),
      );
    }

    Widget detailValue(String value) {
      return Padding(
        padding: EdgeInsets.only(bottom: sectionGap),
        child: Text(value, style: detailValueStyle),
      );
    }

    final Widget verticalDottedSeparator = CustomPaint(
      size: const Size(1.5, double.infinity),
      painter: _VerticalDottedLinePainter(color: colors.divider),
    );

    final Widget productImage = Builder(
      builder: (context) {
        final String imageUrl = (stock?.imageUrl ?? "").trim();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
              color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Image.asset(
                        overviewPlaceholder,
                        fit: BoxFit.contain,
                      ),
                      errorWidget: (_, _, _) => Image.asset(
                        overviewPlaceholder,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      overviewPlaceholder,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        );
      },
    );

    final Widget searchField = Padding(
      padding: EdgeInsets.only(
        top: isTablet ? 28 : 22,
        bottom: 0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _bcController,
              focusNode: txtFieldFocusNode,
              scrollPhysics: const ClampingScrollPhysics(),
              // Disable autocorrect and predictive text
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search Stock',
                hintStyle: TextStyle(
                  color: colors.onSurfaceMuted,
                  fontSize: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white24
                        : kPrimaryColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: const BorderSide(
                    color: kPrimaryColor,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white24
                        : kPrimaryColor.withOpacity(0.2),
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.black : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
    );

    final Widget qtyField = Padding(
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
          hintText: "Count Qty",
          hintStyle: TextStyle(
            color: colors.onSurfaceMuted,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white24
                  : kPrimaryColor.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: kPrimaryColor,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white24
                  : kPrimaryColor.withOpacity(0.2),
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.black : Colors.white,
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
    );

    final Widget listButton =
        BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
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
    );

    final Widget scanButton = CustomStocktakeBtn(
      function: () {
        _toggleScan();
      },
      icon: Icons.qr_code_scanner,
      bgColor: isScan ? Colors.redAccent : Colors.lightGreen,
      name: isScan ? "STOP" : "SCAN",
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: 20,
        left: horizontalPadding,
        right: horizontalPadding,
        top: (context.isMediumTablet ? 14.0 : outerVerticalPadding) +
            (isTablet ? 24.0 : 18.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20.0 : 12.0,
            ),
            child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isTabletLandscape && stock != null) ...[
                  // IMAGE COLUMN (tablet landscape only)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              "IMAGE",
                              textAlign: TextAlign.center,
                              style: sectionLabelStyle,
                            ),
                          ),
                          SizedBox(height: isTablet ? 28 : 22),
                          Expanded(
                            child: Center(child: productImage),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 12),
                  verticalDottedSeparator,
                  SizedBox(width: isTablet ? 20 : 12),
                ],
                // LEFT HALF - Stock Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "STOCK DETAILS",
                                textAlign: TextAlign.center,
                                style: sectionLabelStyle,
                              ),
                            ),
                            if (stock != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    qtyController.clear();
                                    _bcController.clear();
                                    countingStock = null;
                                  });
                                  context.read<ScannerBloc>().add(
                                    ResetStocktakeEvent(ScannerInitial()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kErrorColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: isTablet ? 18 : 16,
                                    color: kErrorColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 28 : 22),
                        if (stock == null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 24 : 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    isDark
                                        ? "assets/images/listempty-dark.png"
                                        : "assets/images/listempty-light.png",
                                    width: isTablet && isPortrait
                                        ? 130
                                        : (isTablet ? 100 : 90),
                                    height: isTablet && isPortrait
                                        ? 130
                                        : (isTablet ? 100 : 90),
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No stock is selected",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? colors.onSurfaceMuted
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: sectionGap),
                                child: Text(
                                  stock.barcode,
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              detailValue(stock.description),
                              detailValue(stock.deptName ?? "-"),
                              detailValue(
                                "${stock.category1} / ${stock.category2} / ${stock.category3}",
                              ),
                              detailValue(stock.custom1 ?? "-"),
                              detailValue(stock.custom2 ?? "-"),
                              detailValue(lastSale),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),
                verticalDottedSeparator,
                SizedBox(width: isTablet ? 20 : 12),
                // RIGHT HALF - Expected
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            "EXPECTED",
                            textAlign: TextAlign.center,
                            style: sectionLabelStyle,
                          ),
                        ),
                        SizedBox(height: isTablet ? 28 : 22),
                        expectedRow("In Stock", inStockDisp),
                        expectedRow("Lay-by", layby),
                        expectedRow("Sales Order", soQty),
                        expectedRow("Total", totalDisp, bold: true),
                        if (stock != null && !isTabletLandscape) ...[
                          SizedBox(height: isTablet ? 24 : 18),
                          productImage,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),

          const Spacer(),

          if (isTabletLandscape)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      searchField,
                      SizedBox(height: isTablet ? 12 : 6),
                      qtyField,
                    ],
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 12),
                Expanded(
                  flex: 35,
                  child: Padding(
                    padding: EdgeInsets.only(top: isTablet ? 28 : 22),
                    child: Column(
                      children: [
                        listButton,
                        SizedBox(height: isTablet ? 16 : 12),
                        scanButton,
                      ],
                    ),
                  ),
                ),
              ],
            )
          else ...[
            searchField,

            // Gap between Manual Barcode Entry and Counted Qty
            SizedBox(height: isTablet ? 12 : 6),

            qtyField,
            SizedBox(
              height: isTablet ? 16 : 14,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: listButton),
                SizedBox(width: isTablet ? 20 : 12),
                Expanded(child: scanButton),
              ],
            ),
          ],
        ]
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

}

class _VerticalDottedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 4;
    const double dashGap = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    double startY = 0;
    final double x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
