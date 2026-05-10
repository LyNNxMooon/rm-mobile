// ignore_for_file: unnecessary_underscores

import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:alert_info/alert_info.dart';
import 'package:rational/rational.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/sale_session_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/navigation_extension.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
import '../../../../utils/formatting_utils.dart';
import '../../domain/use_cases/save_sale_session.dart';
import '../BLoC/sales_bloc.dart';
import '../BLoC/sales_events.dart';
import '../BLoC/sales_states.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';
import '../../../../constants/standard_dialog.dart';
import 'stock_selection_screen.dart';
import 'customer_selection_screen.dart';
import '../widgets/finalise_sale_dialog.dart';
import '../widgets/sale_session_picker_dialog.dart';
import '../widgets/sales_widgets.dart';
import '../widgets/low_stock_warning_dialog.dart';
import '../widgets/not_permitted_dialog.dart';
import '../widgets/out_of_stock_finalise_dialog.dart';
import '../widgets/customer_comments_dialog.dart';
import '../../../customer_lookup/presentation/screens/customer_transactions_screen.dart';
import '../../../customer_lookup/presentation/screens/customer_create_screen.dart';
import '../../../customer_lookup/presentation/BLoC/customer_transactions_bloc.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../entities/vos/delivery_info_vo.dart';
import '../../../../utils/responsive_utils.dart';
import 'delivery_details_screen.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart';
import '../../../customer_lookup/presentation/screens/customer_lookup_screen.dart';

/// View mode options for cart (tablet only)
enum CartViewMode {
  list,
  gridMedium,
  largeIcons;

  String get displayName {
    switch (this) {
      case CartViewMode.list:
        return 'List';
      case CartViewMode.gridMedium:
        return 'Grid';
      case CartViewMode.largeIcons:
        return 'Large Icons';
    }
  }

  IconData get icon {
    switch (this) {
      case CartViewMode.list:
        return Icons.table_rows;
      case CartViewMode.gridMedium:
        return Icons.view_list;
      case CartViewMode.largeIcons:
        return Icons.grid_view;
    }
  }
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    this.title = "Sales",
    this.themeColor = Colors.green,
    this.icon = Icons.point_of_sale_outlined,
  });

  final String title;
  final Color themeColor;
  final IconData icon;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _discountController = TextEditingController(
    text: "0.00",
  );
  final FocusNode _searchFocusNode = FocusNode();

  // Scanner controller
  late MobileScannerController _scannerController;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final _beepSource = AssetSource('audio/beep.mp3');
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  bool _isTorchOn = false;

  // BLoC for cart management
  late SalesBloc _salesBloc;

  // Selected customer
  CustomerVO? _selectedCustomer;

  // Delivery info (stored until user leaves screen)
  DeliveryInfoVO? _deliveryInfo;

  // Committed delivery address for API payload (set when "Commit" in delivery_details_screen)
  DeliveryAddressData? _committedDeliveryAddress;

  // Email audit data for API payload (set when "Email & Commit" is selected)
  EmailAuditData? _emailAuditData;

  final bool _isPaymentMode = false;
  bool _showScanner = false;
  bool _isScannerOpening = false;
  bool _scannerAddedItem = false;
  bool _hadSearchFocusBeforeScan = false;
  bool _skipNextSearchFocus = false;
  bool _showActions = false;
  bool _isIncTax = true;
  bool _isCompactView = false;
  CartViewMode _cartViewMode = CartViewMode.list; // View mode for tablet
  final bool _showTaxDetails = false;
  final bool _showProfitDetails = false;
  String? _selectedOption;
  double _discountValue = 0.00;

  // Sales Settings
  bool _scanIndividualUnits = false;
  bool _skipSellPrice = false;
  bool _oneDisplayLinePerItem = true;
  bool _promptForEmailAtSale = false;
  final bool _skipCustomField = false;
  final bool _skipCustomerField = false;
  bool _scanIndividualUnitsForFractional = false;
  bool _preventAddIfNoStock = false;
  bool _preventFinaliseIfOutOfStock = false;
  bool _autoRemindLowStock = false;
  bool _promptScanIndividualFractional = false;
  bool _displayCustomerMessagesAsPrompt = false;

  // Payment amounts for each payment type
  final Map<String, double> _paymentAmounts = {};

  // Survey and Comment values
  String _surveyValue = '';
  String _commentValue = '';
  final TextEditingController _surveyController = TextEditingController();

  // Session tracking
  int? _currentSessionId;
  bool _sessionsChecked = false;
  final Map<String, double> _promptedQtyByCode = {};
  bool _isRestoringSession = false;
  bool _isFinaliseProcessing = false;
  bool _isPostSyncing = false;
  bool _postSaleSyncRequested = false;
  bool _postStockSyncing = false;
  bool _postCustomerSyncing = false;
  bool _isSearchLoading = false;
  Timer? _searchLoadingTimer;
  bool _isCustomerSearchLoading = false;
  Timer? _customerSearchLoadingTimer;
  bool _isNegativeSellPriceDialogOpen = false;
  bool _reminderShown = false;
  bool _salesPromptDialogOpen = false;
  bool _lowStockDialogOpen = false;
  DateTime? _lastSessionUpdatedAt;

  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;

  /// Gets the survey label from AppGlobals.salesCustom or defaults to "Add Survey"
  String get _surveyLabel =>
      AppGlobals.instance.salesCustom?.trim().isNotEmpty == true
      ? AppGlobals.instance.salesCustom!
      : "Add Survey";

  List<String> get _optionItems {
    final hideCostPriceAndProfit = AppGlobals.instance.restrictedPermissions
        .contains("Miscellaneous_HideCostPriceAndProfit");
    final items = <String>[
      _surveyLabel,
      "Comment",
      if (AppGlobals.instance.hasPermission("Miscellaneous_LockDiscount"))
        "Discount",
      "Delivery",
      "Tax",
      if (!hideCostPriceAndProfit) "Profit",
      "Save Session",
      "Clear Session",
    ];
    return items;
  }

  // Cart items from BLoC state
  List<CartItemVO> get _cartItems => _salesBloc.state.cartItems;

  /// Helper to convert double to Rational for precise calculations
  Rational _toRational(double value) => Rational.parse(value.toString());

  /// Helper to convert Rational to double with high precision
  double _fromRational(Rational value) =>
      value.toDecimal(scaleOnInfinitePrecision: 10).toDouble();

  /// Subtotal always uses inclusive price (actual sale amount) - calculated with precise Rational
  double get _subtotal {
    if (_cartItems.isEmpty) return 0.0;
    Rational sum = Rational.zero;
    for (final item in _cartItems) {
      sum += _toRational(item.extension);
    }
    return _fromRational(sum);
  }

  /// Calculate line GP with Rational precision: (sellEx - cost) * qty, cost based on taxType
  double _calcLineGp(CartItemVO item) {
    final sellExR = _toRational(item.exPrice);
    final costR = _toRational(
      item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
    );
    final qtyR = _toRational(item.qty);
    return _fromRational((sellExR - costR) * qtyR);
  }

  /// Total GP before discount (sum of line GPs) with Rational precision
  double get _totalGpBeforeDiscount {
    Rational totalGpR = Rational.zero;
    for (final item in _cartItems) {
      final sellExR = _toRational(item.exPrice);
      final costR = _toRational(
        item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
      );
      final qtyR = _toRational(item.qty);
      totalGpR += (sellExR - costR) * qtyR;
    }
    return _fromRational(totalGpR);
  }

  /// Calculate totals with discount distribution using GP ratio
  /// Returns (totalInc, totalEx, totalTax, totalGp) with precise Rational calculation
  /// Ex Tax: Sum(SellEx * qty), Tax: Sum((SellInc - SellEx) * qty), Inc Tax: Sum(SellInc * qty)
  ({double totalInc, double totalEx, double totalTax, double totalGp})
  get _calculatedTotals {
    if (_discount <= 0 || _cartItems.isEmpty) {
      // No discount - simple calculation with Rational precision
      Rational totalExR = Rational.zero;
      Rational totalTaxR = Rational.zero;
      Rational totalIncR = Rational.zero;
      Rational totalGpR = Rational.zero;

      for (final item in _cartItems) {
        final qtyR = _toRational(item.qty);
        final sellIncR = _toRational(item.incPrice);
        final sellExR = _toRational(item.exPrice);
        final costR = _toRational(
          item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
        );

        // Ex Tax: Sum += Sell Ex * qty
        totalExR += sellExR * qtyR;
        // Tax Amount: Sum += (Sell Inc - Sell Ex) * qty
        totalTaxR += (sellIncR - sellExR) * qtyR;
        // Inc Tax: Sum += Sell Inc * qty
        totalIncR += sellIncR * qtyR;
        // eGP: Sum += (Sell Ex - Cost) * qty
        totalGpR += (sellExR - costR) * qtyR;
      }

      return (
        totalInc: _fromRational(totalIncR),
        totalEx: _fromRational(totalExR),
        totalTax: _fromRational(totalTaxR),
        totalGp: _fromRational(totalGpR),
      );
    }

    // Has discount - distribute using GP ratio with Rational precision
    final totalGpBeforeDisc = _totalGpBeforeDiscount;
    final useGpRatio = totalGpBeforeDisc > 0 && totalGpBeforeDisc > _discount;

    Rational newTotalExR = Rational.zero;
    Rational newTotalTaxR = Rational.zero;
    Rational newTotalIncR = Rational.zero;
    Rational newTotalGpR = Rational.zero;

    for (final item in _cartItems) {
      final orgSellIncR = _toRational(item.incPrice);
      final orgSellExR = _toRational(item.exPrice);
      final qtyR = _toRational(item.qty);
      final lineGp = _calcLineGp(item);

      // Ratio = (Line GP OR Line Sell Inc * qty) / Total GP OR SubTotal
      Rational ratioR;
      if (useGpRatio) {
        ratioR = totalGpBeforeDisc > 0
            ? _toRational(lineGp) / _toRational(totalGpBeforeDisc)
            : Rational.zero;
      } else {
        ratioR = _subtotal > 0
            ? (orgSellIncR * qtyR) / _toRational(_subtotal)
            : Rational.zero;
      }

      // Line Discount = Sale's Discount * Ratio
      final lineDiscountR = _toRational(_discount) * ratioR;
      // New Sell Inc = Org Sell Inc - (Line Discount / qty)
      final newSellIncR = orgSellIncR - (lineDiscountR / qtyR);
      // New Sell Ex = New Sell Inc * (Org Sell Ex / Org Sell Inc)
      final newSellExR = orgSellIncR > Rational.zero
          ? newSellIncR * (orgSellExR / orgSellIncR)
          : newSellIncR;

      // Ex Tax: Sum += New Sell Ex * qty
      newTotalExR += newSellExR * qtyR;
      // Tax Amount: Sum += (New Sell Inc - New Sell Ex) * qty
      newTotalTaxR += (newSellIncR - newSellExR) * qtyR;
      // Inc Tax: Sum += New Sell Inc * qty
      newTotalIncR += newSellIncR * qtyR;

      // eGP: Sum += (New Sell Ex - Cost) * qty
      final costR = _toRational(
        item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
      );
      newTotalGpR += (newSellExR - costR) * qtyR;
    }

    return (
      totalInc: _fromRational(newTotalIncR),
      totalEx: _fromRational(newTotalExR),
      totalTax: _fromRational(newTotalTaxR),
      totalGp: _fromRational(newTotalGpR),
    );
  }

  /// Subtotal Ex (before discount) - calculated with precise Rational
  double get _subtotalEx {
    if (_cartItems.isEmpty) return 0.0;
    Rational totalTaxR = Rational.zero;
    final oneHundred = Rational.fromInt(100);
    for (final item in _cartItems) {
      final extensionIncR = _toRational(item.extension);
      final rateR = _toRational(item.taxPercentage);
      if (item.taxPercentage > 0) {
        // lineTax = extensionInc * rate / (100 + rate)
        final lineTaxR = extensionIncR * rateR / (oneHundred + rateR);
        totalTaxR += lineTaxR;
      }
    }
    final subtotalR = _toRational(_subtotal);
    return _fromRational(subtotalR - totalTaxR);
  }

  /// Calculate totals with a specific discount (for live preview in dialogs)
  /// Ex Tax: Sum(SellEx * qty), Tax: Sum((SellInc - SellEx) * qty), Inc Tax: Sum(SellInc * qty)
  ({double totalInc, double totalEx, double totalTax, double totalGp})
  _calcTotalsWithDiscount(double discount) {
    if (discount <= 0 || _cartItems.isEmpty) {
      // No discount - simple calculation with Rational precision
      Rational totalExR = Rational.zero;
      Rational totalTaxR = Rational.zero;
      Rational totalIncR = Rational.zero;
      Rational totalGpR = Rational.zero;

      for (final item in _cartItems) {
        final qtyR = _toRational(item.qty);
        final sellIncR = _toRational(item.incPrice);
        final sellExR = _toRational(item.exPrice);
        final costR = _toRational(
          item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
        );

        // Ex Tax: Sum += Sell Ex * qty
        totalExR += sellExR * qtyR;
        // Tax Amount: Sum += (Sell Inc - Sell Ex) * qty
        totalTaxR += (sellIncR - sellExR) * qtyR;
        // Inc Tax: Sum += Sell Inc * qty
        totalIncR += sellIncR * qtyR;
        // eGP: Sum += (Sell Ex - Cost) * qty
        totalGpR += (sellExR - costR) * qtyR;
      }

      return (
        totalInc: _fromRational(totalIncR),
        totalEx: _fromRational(totalExR),
        totalTax: _fromRational(totalTaxR),
        totalGp: _fromRational(totalGpR),
      );
    }

    // Has discount - distribute using GP ratio with Rational precision
    final totalGpBeforeDisc = _totalGpBeforeDiscount;
    final useGpRatio = totalGpBeforeDisc > 0 && totalGpBeforeDisc > discount;

    Rational newTotalExR = Rational.zero;
    Rational newTotalTaxR = Rational.zero;
    Rational newTotalIncR = Rational.zero;
    Rational newTotalGpR = Rational.zero;

    for (final item in _cartItems) {
      final orgSellIncR = _toRational(item.incPrice);
      final orgSellExR = _toRational(item.exPrice);
      final qtyR = _toRational(item.qty);
      final lineGp = _calcLineGp(item);

      // Ratio = (Line GP OR Line Sell Inc * qty) / Total GP OR SubTotal
      Rational ratioR;
      if (useGpRatio) {
        ratioR = totalGpBeforeDisc > 0
            ? _toRational(lineGp) / _toRational(totalGpBeforeDisc)
            : Rational.zero;
      } else {
        ratioR = _subtotal > 0
            ? (orgSellIncR * qtyR) / _toRational(_subtotal)
            : Rational.zero;
      }

      // Line Discount = Sale's Discount * Ratio
      final lineDiscountR = _toRational(discount) * ratioR;
      // New Sell Inc = Org Sell Inc - (Line Discount / qty)
      final newSellIncR = orgSellIncR - (lineDiscountR / qtyR);
      // New Sell Ex = New Sell Inc * (Org Sell Ex / Org Sell Inc)
      final newSellExR = orgSellIncR > Rational.zero
          ? newSellIncR * (orgSellExR / orgSellIncR)
          : newSellIncR;

      // Ex Tax: Sum += New Sell Ex * qty
      newTotalExR += newSellExR * qtyR;
      // Tax Amount: Sum += (New Sell Inc - New Sell Ex) * qty
      newTotalTaxR += (newSellIncR - newSellExR) * qtyR;
      // Inc Tax: Sum += New Sell Inc * qty
      newTotalIncR += newSellIncR * qtyR;

      // eGP: Sum += (New Sell Ex - Cost) * qty
      final costR = _toRational(
        item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
      );
      newTotalGpR += (newSellExR - costR) * qtyR;
    }

    return (
      totalInc: _fromRational(newTotalIncR),
      totalEx: _fromRational(newTotalExR),
      totalTax: _fromRational(newTotalTaxR),
      totalGp: _fromRational(newTotalGpR),
    );
  }

  /// Display subtotal respects the tax toggle - calculated with precise Rational
  double get _displaySubtotal {
    if (_isIncTax) {
      return _subtotal; // Already uses Rational
    }
    return _subtotalEx;
  }

  double get _discount => _discountValue;
  double get _rounding => 0.00; // Placeholder

  /// Total calculated with precise Rational: subtotal - discount + rounding
  double get _total {
    final subtotalR = _toRational(_subtotal);
    final discountR = _toRational(_discount);
    final roundingR = _toRational(_rounding);
    return _fromRational(subtotalR - discountR + roundingR);
  }

  /// Total Ex with discount distribution (display 2dp with cascading rounding)
  double get _totalEx =>
      double.parse(_calculatedTotals.totalEx.toStringAsFixed(2));

  /// Total cost with Rational precision based on sales_tax taxType:
  /// If taxType == 0 -> use ex-taxed cost (computedCostEx)
  /// If taxType != 0 -> use inc-taxed cost (computedCostInc)
  double get _totalCost {
    Rational totalCostR = Rational.zero;
    for (final item in _cartItems) {
      final costR = _toRational(
        item.taxType == 0 ? item.computedCostEx : item.computedCostInc,
      );
      final qtyR = _toRational(item.qty);
      totalCostR += costR * qtyR;
    }
    return _fromRational(totalCostR);
  }

  /// Display total respects the tax toggle - calculated with precise Rational
  double get _displayTotal {
    final displaySubtotalR = _toRational(_displaySubtotal);
    final discountR = _toRational(_discount);
    final roundingR = _toRational(_rounding);
    return _fromRational(displaySubtotalR - discountR + roundingR);
  }

  double get _totalPaid =>
      _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);

  /// Closes the scanner if open - call before showing dialogs that need keyboard
  void _closeScanner() {
    if (_showScanner) {
      setState(() => _showScanner = false);
    }
    _isScannerOpening = false;
    _hadSearchFocusBeforeScan = false;
    _scannerAddedItem = false;
  }

  void _focusSearchField({bool force = false}) {
    if (!mounted) return;
    if (_showScanner || _isScannerOpening) {
      return;
    }
    if (!force) {
      final hasEditingItem = _cartItems.any((item) => item.isEditing);
      if (_skipNextSearchFocus) {
        _skipNextSearchFocus = false;
        return;
      }
      if (_scannerAddedItem) {
        if (_showScanner) {
          return;
        }
        _scannerAddedItem = false;
      }
      if (hasEditingItem ||
          _isFinaliseProcessing ||
          _salesPromptDialogOpen ||
          _lowStockDialogOpen) {
        return;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (force || !_searchFocusNode.hasFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  /// Toggles the scanner with proper keyboard dismissal to prevent overflow
  Future<void> _toggleScanner() async {
    if (_showScanner) {
      // Closing scanner - do it immediately
      setState(() => _showScanner = false);
      _isScannerOpening = false;
      _hadSearchFocusBeforeScan = false;
      _scannerAddedItem = false;
    } else {
      // Opening scanner - first dismiss keyboard, wait for animation, then open
      _isScannerOpening = true;
      _hadSearchFocusBeforeScan = _searchFocusNode.hasFocus;
      FocusScope.of(context).unfocus();
      // Wait for keyboard to close to prevent overflow during transition
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() => _showScanner = true);
        _isScannerOpening = false;
      }
    }
  }

  Future<bool> _showBelowCostPrompt(AppThemeColors colors, bool isDark) async {
    final bool isTablet = context.isTablet;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StandardDialog(
          title: "RetailManager Question",
          colors: colors,
          isDark: isDark,
          maxWidth: isTablet ? 450 : double.infinity,
          onClose: () => Navigator.of(dialogContext).pop(false),
          content: Text(
            "Selling Price should be greater than Cost, continue?",
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            DialogTextAction(
              label: "No",
              style: DialogActionStyle.outline,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            DialogTextAction(
              label: "Yes",
              style: DialogActionStyle.primary,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _promptBelowCostOnAddIfNeeded(
    List<CartItemVO> items,
    AppThemeColors colors,
    bool isDark,
  ) async {
    final currentCodes = items.map((item) => item.code).toSet();
    _promptedQtyByCode.removeWhere((code, _) => !currentCodes.contains(code));

    for (final item in items) {
      if (item.isEditing) continue;

      final prevQty = _promptedQtyByCode[item.code] ?? 0;
      if (item.qty <= prevQty) {
        _promptedQtyByCode[item.code] = item.qty;
        continue;
      }

      final costEx = item.stock?.costEx ?? item.stock?.cost ?? item.costPrice;
      if (costEx == null) {
        _promptedQtyByCode[item.code] = item.qty;
        continue;
      }

      if (item.exPrice < costEx) {
        final proceed = await _showBelowCostPrompt(colors, isDark);
        if (!proceed) {
          final index = items.indexWhere(
            (element) => element.code == item.code,
          );
          if (index != -1) {
            _salesBloc.add(RemoveCartItem(index: index));
          }
          _promptedQtyByCode.remove(item.code);
          return;
        }
      }

      _promptedQtyByCode[item.code] = item.qty;
    }
  }

  Future<bool> _promptBelowCostOnSave(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) async {
    final costEx = item.stock?.costEx ?? item.stock?.cost ?? item.costPrice;
    if (costEx == null) return true;

    if (item.exPrice >= costEx) {
      _promptedQtyByCode[item.code] = item.qty;
      return true;
    }

    final proceed = await _showBelowCostPrompt(colors, isDark);
    if (!proceed) {
      _salesBloc.add(RemoveCartItem(index: index));
      _promptedQtyByCode.remove(item.code);
      return false;
    }

    _promptedQtyByCode[item.code] = item.qty;

    return proceed;
  }

  @override
  void initState() {
    super.initState();
    _salesBloc = context.read<SalesBloc>();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      returnImage: false,
    );
    _actionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionsAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeOutCubic,
    );
    // Close scanner when search field is focused
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        if (_showScanner || _isScannerOpening) {
          _searchFocusNode.unfocus();
          return;
        }
        _closeScanner();
      }
    });
    _loadSalesSettings();

    // Check for saved sessions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSavedSessions();
    });
  }

  Future<void> _maybeShowShopfrontReminder() async {
    if (_reminderShown || !mounted) return;
    final reminder = AppGlobals.instance.shopfrontReminder?.trim() ?? '';
    if (reminder.isEmpty) return;

    _reminderShown = true;
    final colors = context.appColors;
    final isDark = colors.isDark;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StandardDialog(
          title: "Reminder",
          colors: colors,
          isDark: isDark,
          onClose: () => Navigator.of(ctx).pop(),
          content: Text(
            reminder,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            DialogTextAction(
              label: "OK",
              style: DialogActionStyle.primary,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSalesPromptDialog(
    String message,
    AppThemeColors colors,
    bool isDark,
  ) async {
    if (_salesPromptDialogOpen || !mounted) return;
    _salesPromptDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StandardDialog(
          title: "Sales Prompt",
          colors: colors,
          isDark: isDark,
          onClose: () => Navigator.of(ctx).pop(),
          content: Text(
            message,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            DialogTextAction(
              label: "OK",
              style: DialogActionStyle.primary,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
    _salesPromptDialogOpen = false;
  }

  Future<void> _checkSavedSessions() async {
    if (_sessionsChecked) return;
    _sessionsChecked = true;

    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) return;

    final sessions = await _salesBloc.getSaleSessions(
      shopfront: shopfront,
      sessionType: widget.title,
    );

    if (sessions.isEmpty || !mounted) {
      await _maybeShowShopfrontReminder();
      return;
    }

    final result = await SaleSessionPickerDialog.show(
      context: context,
      sessions: sessions,
      sessionType: widget.title,
    );

    if (result == null || result.result == SessionPickerResult.cancelled) {
      return;
    }

    if (result.result == SessionPickerResult.continueSession &&
        result.session != null) {
      await _restoreSession(result.session!);
    } else if (result.result == SessionPickerResult.newSale) {
      // Starting new sale - optionally clear old sessions
      // For now, we keep them so user can continue later
    }

    await _maybeShowShopfrontReminder();
  }

  Future<void> _restoreSession(SaleSessionVO session) async {
    _isRestoringSession = true;
    _currentSessionId = session.id;
    _lastSessionUpdatedAt = session.updatedAt;

    final shopfront = AppGlobals.instance.shopfront ?? '';
    final restoreResult = await _salesBloc.restoreSaleSession(
      session: session,
      shopfront: shopfront,
    );

    // Restore cart items
    _salesBloc.add(ClearCart());
    _promptedQtyByCode.clear();
    for (final cartItem in restoreResult.cartItems) {
      _salesBloc.add(AddCartItemDirect(cartItem: cartItem));
    }

    for (final cartItem in restoreResult.cartItems) {
      _promptedQtyByCode[cartItem.code] = cartItem.qty;
    }

    // Restore customer
    if (restoreResult.customer != null) {
      _salesBloc.add(SelectCustomer(customer: restoreResult.customer!));
    } else {
      _salesBloc.add(ClearCustomer());
    }

    // Restore other values
    setState(() {
      _discountValue = restoreResult.discount;
      _discountController.text = restoreResult.discount.toStringAsFixed(2);
      _paymentAmounts.clear();
      _paymentAmounts.addAll(restoreResult.paymentAmounts);
      _surveyValue = restoreResult.surveyValue;
      _surveyController.text = _surveyValue;
      _commentValue = restoreResult.commentValue;
      _committedDeliveryAddress = restoreResult.deliveryAddress;
      _deliveryInfo = restoreResult.deliveryAddress?.toDeliveryInfo(
        customerId: restoreResult.customer?.customerId,
      );
      _emailAuditData = restoreResult.emailAudit;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isRestoringSession = false;
        _focusSearchField(force: true);
      }
    });
  }

  Future<void> _saveCurrentSession() async {
    // Only save if there are items in the cart
    if (_cartItems.isEmpty) {
      // If session exists but cart is now empty, delete it
      if (_currentSessionId != null) {
        await _salesBloc.deleteSaleSession(sessionId: _currentSessionId!);
        _currentSessionId = null;
        _lastSessionUpdatedAt = null;
      }
      return;
    }

    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) return;

    // Get cash drawer from local db
    final drawer = await _salesBloc.fetchCashDrawerIdentifier(fallback: 'M');

    // Get calculated totals with discount distribution (4dp precision)
    final totals = _calculatedTotals;

    // For Account Sales, use customer's owner_id as staff_id (fallback to logged-in staff if no owner)
    final int? staffId =
        widget.title == 'Account Sales' && _selectedCustomer != null
        ? (_selectedCustomer!.ownerId > 0
              ? _selectedCustomer!.ownerId
              : AppGlobals.instance.staffId)
        : AppGlobals.instance.staffId;

    final params = SaveSessionParams(
      existingSessionId: _currentSessionId,
      sessionType: widget.title,
      shopfront: shopfront,
      cartItems: _cartItems,
      customer: _selectedCustomer,
      staffId: staffId,
      subtotal: _subtotal,
      discount: _discountValue,
      totalInc: _total,
      totalEx: totals.totalEx, // Store raw precision
      totalGp: totals.totalGp, // Store raw precision
      paymentAmounts: _paymentAmounts,
      surveyValue: _surveyValue,
      commentValue: _commentValue,
      drawer: drawer,
      deliveryAddress: _committedDeliveryAddress,
      emailAudit: _emailAuditData,
      buildCustomerDisplayName: _buildCustomerDisplayName,
    );

    _currentSessionId = await _salesBloc.saveSaleSession(params);
    _lastSessionUpdatedAt = DateTime.now();
  }

  Future<void> _deleteCurrentSession() async {
    if (_currentSessionId != null) {
      await _salesBloc.deleteSaleSession(sessionId: _currentSessionId!);
      _currentSessionId = null;
    }
  }

  Future<void> _loadSalesSettings() async {
    final settings = await _salesBloc.loadSalesSettings();
    if (mounted) {
      setState(() {
        _scanIndividualUnits = settings.scanIndividualUnits;
        _skipSellPrice = settings.skipSellPrice;
        _oneDisplayLinePerItem = settings.oneDisplayLinePerItem;
        _promptForEmailAtSale = settings.promptForEmailAtSale;
        _autoRemindLowStock = settings.autoRemindLowStock;
        _preventAddIfNoStock = settings.preventAddIfNoStock;
        _preventFinaliseIfOutOfStock = settings.preventFinaliseIfOutOfStock;
        _displayCustomerMessagesAsPrompt =
            settings.displayCustomerMessagesAsPrompt;
        _scanIndividualUnitsForFractional =
            settings.scanIndividualUnitsForFractional;
        _promptScanIndividualFractional =
            settings.promptScanIndividualFractional;
      });
    }
  }

  @override
  void dispose() {
    _searchLoadingTimer?.cancel();
    _customerSearchLoadingTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _discountController.dispose();
    _searchFocusNode.dispose();
    _actionsAnimationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startSearchLoadingDelay() {
    _searchLoadingTimer?.cancel();
    _isSearchLoading = false;
    _searchLoadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (_salesBloc.state is StockSearching) {
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

  void _startCustomerSearchLoadingDelay() {
    _customerSearchLoadingTimer?.cancel();
    _isCustomerSearchLoading = false;
    _customerSearchLoadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (_salesBloc.state is CustomerSearching) {
        setState(() => _isCustomerSearchLoading = true);
      }
    });
  }

  void _stopCustomerSearchLoading() {
    _customerSearchLoadingTimer?.cancel();
    if (_isCustomerSearchLoading && mounted) {
      setState(() => _isCustomerSearchLoading = false);
    }
  }

  void _onBarcodeScanned(String barcode) async {
    // Debounce: prevent double processing of same frame
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1000 &&
        barcode == _lastScannedBarcode) {
      return;
    }
    _lastScanTime = now;
    _lastScannedBarcode = barcode;

    // Feedback
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
    await _audioPlayer.stop();
    _audioPlayer.play(_beepSource);

    if (_hadSearchFocusBeforeScan) {
      _skipNextSearchFocus = true;
    }
    _scannerAddedItem = true;

    // Search for stock
    _salesBloc.add(
      SearchStock(
        query: barcode,
        skipEditMode: _scanIndividualUnits && _skipSellPrice,
        autoRemindLowStock: _autoRemindLowStock,
        preventAddIfNoStock: _preventAddIfNoStock,
        oneDisplayLinePerItem: _oneDisplayLinePerItem,
      ),
    );
  }

  String _buildCustomerDisplayName(CustomerVO customer) {
    final parts = <String>[];
    if (customer.givenNames.isNotEmpty) parts.add(customer.givenNames);
    if (customer.surname.isNotEmpty) parts.add(customer.surname);

    if (parts.isEmpty && customer.company.isNotEmpty) {
      return customer.company;
    }

    return parts.isEmpty ? "Unknown Customer" : parts.join(' ');
  }

  /// Handle fractional item based on settings
  Future<void> _handleFractionalItem(
    StockVO stock,
    AppThemeColors colors,
    bool isDark,
  ) async {
    // If "Scan Individual Units for Fractional Quantities" is ON, auto-add like normal items
    if (_scanIndividualUnitsForFractional) {
      _salesBloc.add(
        SelectStock(
          stock: stock,
          skipEditMode: true,
          skipFractionalCheck: true,
          autoRemindLowStock: _autoRemindLowStock,
          preventAddIfNoStock: _preventAddIfNoStock,
          oneDisplayLinePerItem: _oneDisplayLinePerItem,
        ),
      );
      return;
    }

    // Default: add with expanded edit mode (skipEditMode = false)
    // This allows user to enter the fractional quantity manually
    _salesBloc.add(
      SelectStock(
        stock: stock,
        skipEditMode: false,
        skipFractionalCheck: true,
        autoRemindLowStock: _autoRemindLowStock,
        preventAddIfNoStock: _preventAddIfNoStock,
        oneDisplayLinePerItem: _oneDisplayLinePerItem,
      ),
    );
  }

  /// Show prompt dialog for fractional item handling
  Future<bool?> _showFractionalPromptDialog(
    AppThemeColors colors,
    bool isDark,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StandardDialog(
          title: "Fractional Quantity Item",
          colors: colors,
          isDark: isDark,
          showClose: true,
          onClose: () => Navigator.of(dialogContext).pop(false),
          content: Text(
            "Would you like to Scan Individual Units for Fractional Quantity Items?",
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            DialogTextAction(
              label: "No",
              style: DialogActionStyle.outline,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            DialogTextAction(
              label: "Yes",
              style: DialogActionStyle.primary,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocProvider.value(
      value: _salesBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SalesBloc, SalesState>(
            listener: (context, state) async {
              if (state is StockSearching) {
                _startSearchLoadingDelay();
              } else {
                _stopSearchLoading();
              }

              if (state is CustomerSearching) {
                _startCustomerSearchLoadingDelay();
              } else {
                _stopCustomerSearchLoading();
              }

              if (state is StockDuplicatesFound) {
                // Navigate to stock selection screen
                final selected = await Navigator.push<StockVO>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StockSelectionScreen(matches: state.matches),
                  ),
                );

                if (selected != null && mounted) {
                  _salesBloc.add(
                    SelectStock(
                      stock: selected,
                      skipEditMode: _scanIndividualUnits && _skipSellPrice,
                      autoRemindLowStock: _autoRemindLowStock,
                      preventAddIfNoStock: _preventAddIfNoStock,
                      oneDisplayLinePerItem: _oneDisplayLinePerItem,
                    ),
                  );
                } else {
                  _salesBloc.add(ResetSearchState());
                }
              } else if (state is StockNotFound) {
                AlertInfo.show(
                  context: context,
                  text: state.message,
                  typeInfo: TypeInfo.error,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kErrorColor,
                  textColor: kErrorColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
              } else if (state is StockSearchError) {
                AlertInfo.show(
                  context: context,
                  text: state.error,
                  typeInfo: TypeInfo.error,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kErrorColor,
                  textColor: kErrorColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
              } else if (state is StockNotPermitted) {
                NotPermittedDialog.show(
                  context: context,
                  message: state.message,
                  colors: colors,
                  isDark: isDark,
                );
              } else if (state is NegativeSellPriceFound) {
                _showNegativeSellPriceError();
              } else if (state is FractionalItemFound) {
                // Handle fractional item based on settings
                await _handleFractionalItem(state.stock, colors, isDark);
              } else if (state is CartUpdated && state.message != null) {
                AlertInfo.show(
                  context: context,
                  text: state.message!,
                  typeInfo: TypeInfo.success,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kPrimaryColor,
                  textColor: kPrimaryColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
              }

              if (state is CartItemSaved) {
                final savedItem = state.cartItems[state.index];
                final proceed = await _promptBelowCostOnSave(
                  savedItem,
                  state.index,
                  colors,
                  isDark,
                );
                if (!proceed) return;
                _focusSearchField();
              } else if (state is CartUpdated) {
                if (_isRestoringSession) return;
                // Save session immediately when cart is updated
                _saveCurrentSession();
                await _promptBelowCostOnAddIfNeeded(
                  state.cartItems,
                  colors,
                  isDark,
                );

                final salesPrompt = state.salesPrompt?.trim() ?? '';
                if (salesPrompt.isNotEmpty) {
                  await _showSalesPromptDialog(salesPrompt, colors, isDark);
                }
              }

              // Handle low stock warning (show after CartUpdated or CartItemSaved)
              if ((state is CartUpdated || state is CartItemSaved) &&
                  state.lowStockWarning != null &&
                  state.lowStockWarning!.hasWarning) {
                _lowStockDialogOpen = true;
                await LowStockWarningDialog.show(
                  context: context,
                  message: state.lowStockWarning!.message ?? '',
                  colors: colors,
                  isDark: isDark,
                );
                _lowStockDialogOpen = false;
              }

              if (state is CartUpdated && state.cartItems.isNotEmpty) {
                _focusSearchField();
              }

              if (state is CustomerDuplicatesFound) {
                // Navigate to customer selection screen
                final selected = await Navigator.push<CustomerVO>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerSelectionScreen(matches: state.matches),
                  ),
                );

                if (selected != null && mounted) {
                  // For Account Sales, validate customer is an account customer
                  if (widget.title == "Account Sales" && !selected.account) {
                    AlertInfo.show(
                      context: context,
                      text: "This customer is not an account customer",
                      typeInfo: TypeInfo.error,
                      backgroundColor: isDark
                          ? colors.surface
                          : kSecondaryColor,
                      iconColor: kErrorColor,
                      textColor: kErrorColor,
                      position: MessagePosition.top,
                      padding: 70,
                    );
                    _salesBloc.add(ResetSearchState());
                  } else {
                    _salesBloc.add(SelectCustomer(customer: selected));
                    setState(() => _selectedCustomer = selected);
                    // Note: Don't call _checkAndShowCustomerComments here -
                    // it will be triggered by CustomerSelected state listener
                  }
                } else {
                  _salesBloc.add(ResetSearchState());
                }
              } else if (state is CustomerSelected) {
                // For Account Sales, validate customer is an account customer
                if (widget.title == "Account Sales" &&
                    !(state.selectedCustomer?.account ?? false)) {
                  AlertInfo.show(
                    context: context,
                    text: "This customer is not an account customer",
                    typeInfo: TypeInfo.error,
                    backgroundColor: isDark ? colors.surface : kSecondaryColor,
                    iconColor: kErrorColor,
                    textColor: kErrorColor,
                    position: MessagePosition.top,
                    padding: 70,
                  );
                } else {
                  setState(() => _selectedCustomer = state.selectedCustomer);
                  _checkAndShowCustomerComments(state.selectedCustomer);
                  // Focus the stock search field after customer selection
                  _focusSearchField(force: true);
                }
              } else if (state is CustomerNotFound) {
                AlertInfo.show(
                  context: context,
                  text: state.message,
                  typeInfo: TypeInfo.error,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kErrorColor,
                  textColor: kErrorColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
              } else if (state is CustomerSearchError) {
                AlertInfo.show(
                  context: context,
                  text: state.error,
                  typeInfo: TypeInfo.error,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kErrorColor,
                  textColor: kErrorColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
              }
            },
          ),
          BlocListener<FetchStockBloc, FetchStockStates>(
            listener: (context, state) {
              if (!_postSaleSyncRequested) return;
              if (state is FetchStockProgress) {
                _postStockSyncing = true;
              } else if (state is FetchStockSuccess ||
                  state is FetchStockError) {
                _postStockSyncing = false;
              }
              _updatePostSyncing();
            },
          ),
          BlocListener<FetchCustomerBloc, FetchCustomerStates>(
            listener: (context, state) {
              if (!_postSaleSyncRequested) return;
              if (state is FetchCustomerProgress) {
                _postCustomerSyncing = true;
              } else if (state is FetchCustomerSuccess ||
                  state is FetchCustomerFailure) {
                _postCustomerSyncing = false;
              }
              _updatePostSyncing();
            },
          ),
        ],
        child: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            return Stack(
              children: [
                PopScope(
                  canPop: true,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) {
                      // Save session when leaving the screen
                      await _saveCurrentSession();
                    }
                  },
                  child: Scaffold(
                    backgroundColor: isDark ? colors.bg : kBgColor,
                    appBar: _buildAppBar(colors, isDark),
                    body: SafeArea(
                      child: Column(
                        children: [
                          // Top Section: Customer, Staff, Date
                          SalesTopHeader(
                            isIncTax: _isIncTax,
                            onTaxModeChanged: (value) =>
                                setState(() => _isIncTax = value),
                            staffName:
                                AppGlobals.instance.staffName ??
                                "Unknown Staff",
                            hasCustomer: _selectedCustomer != null,
                            customerBarcode: _selectedCustomer?.barcode,
                            customerName: _selectedCustomer != null
                                ? _buildCustomerDisplayName(_selectedCustomer!)
                                : null,
                            customerGrade: _selectedCustomer?.grade,
                            autoFocusCustomer: widget.title != "Sales",
                            onCustomerSearch: (query) {
                              _salesBloc.add(SearchCustomer(query: query));
                            },
                            onCustomerClear: () {
                              _salesBloc.add(ClearCustomer());
                              setState(() => _selectedCustomer = null);
                            },
                            onViewCustomerTransactions:
                                _selectedCustomer != null
                                ? () => _openCustomerTransactions()
                                : null,
                            viewMode: isTablet ? _cartViewMode : null,
                            onViewModeChanged: isTablet
                                ? (mode) => setState(() => _cartViewMode = mode)
                                : null,
                            onCustomerFieldFocus: _closeScanner,
                            onGoToCustomerLookup: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerLookupScreen(
                                    showBackArrow: true,
                                    selectionMode: true,
                                    onCustomerSelected: (customer) {
                                      _salesBloc.add(SelectCustomer(customer: customer));
                                    },
                                  ),
                                ),
                              );
                            },
                            onCreateCustomer: _selectedCustomer == null
                                ? _openCustomerCreate
                                : null,
                            onCustomerSearchEmpty: () => _focusSearchField(force: true),
                          ),
                          // Scanner Area
                          if (_showScanner)
                            SalesScannerArea(
                              scannerController: _scannerController,
                              onBarcodeScanned: _onBarcodeScanned,
                            ),

                          // Middle Section: Cart Items - Expanded takes remaining space
                          Expanded(
                            child: _buildCartArea(colors, isDark, isTablet),
                          ),

                          // Search Bar (moved to bottom)
                          SalesSearchBar(
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            showScanner: _showScanner,
                            isTorchOn: _isTorchOn,
                            onScannerToggle: () => _toggleScanner(),
                            onTorchToggle: () {
                              setState(() {
                                _scannerController.toggleTorch();
                                _isTorchOn = !_isTorchOn;
                              });
                            },
                            onSearch: (query) {
                              _salesBloc.add(
                                SearchStock(
                                  query: query,
                                  skipEditMode:
                                      _scanIndividualUnits && _skipSellPrice,
                                  autoRemindLowStock: _autoRemindLowStock,
                                  preventAddIfNoStock: _preventAddIfNoStock,
                                  oneDisplayLinePerItem: _oneDisplayLinePerItem,
                                ),
                              );
                            },
                            onGoToStockLookup: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StockLookupScreen(
                                    showBackArrow: true,
                                    selectionMode: true,
                                    onStockSelected: (stock) {
                                      _salesBloc.add(
                                        SelectStock(
                                          stock: stock,
                                          skipEditMode: _scanIndividualUnits && _skipSellPrice,
                                          autoRemindLowStock: _autoRemindLowStock,
                                          preventAddIfNoStock: _preventAddIfNoStock,
                                          oneDisplayLinePerItem: _oneDisplayLinePerItem,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                          // Bottom Section: Summary, Payment & Commit
                          // Hide on tablet landscape when keyboard is visible to prevent overflow
                          if (!(isTablet && isLandscape && isKeyboardVisible))
                            _buildBottomSummary(colors, isDark, isTablet),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isFinaliseProcessing)
                  _buildBlockingOverlay(
                    colors: colors,
                    isDark: isDark,
                    message: "Processing...",
                  ),
                if (_isSearchLoading || _isCustomerSearchLoading)
                  _buildBlockingOverlay(
                    colors: colors,
                    isDark: isDark,
                    message: "",
                  ),
                if (_isPostSyncing)
                  _buildBlockingOverlay(
                    colors: colors,
                    isDark: isDark,
                    message: "Re-syncing...",
                    showPanel: true,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeColors colors, bool isDark) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 40,
      backgroundColor: widget.themeColor,
      centerTitle: true,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.white,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => context.navigateBack(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 6),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'default') {
              setState(() => _isCompactView = false);
            } else if (value == 'compact') {
              setState(() => _isCompactView = true);
            } else if (value == 'settings') {
              if (!AppGlobals.instance.hasPermission("Setup_Options")) {
                showTopSnackBar(
                  Overlay.of(context),
                  const CustomSnackBar.error(
                    message:
                        "You do not have permission to access Sales Settings.",
                  ),
                );
                return;
              }
              _showSalesSettingsDialog(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(
                    _isCompactView
                        ? Icons.radio_button_off
                        : Icons.radio_button_checked,
                    size: 18,
                    color: _isCompactView ? Colors.grey : kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Default View'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'compact',
              child: Row(
                children: [
                  Icon(
                    _isCompactView
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: _isCompactView ? kPrimaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Compact View'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartArea(AppThemeColors colors, bool isDark, bool isTablet) {
    if (_cartItems.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                      color: colors.onSurfaceMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Cart is empty",
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.onSurfaceMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan an item to begin.",
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceMuted.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Check if any item is in edit mode - if so, use list view for the edit form
    final bool hasEditingItem = _cartItems.any((item) => item.isEditing);

    // Use different views based on cart view mode (tablet only)
    // But switch to list view if any item is being edited (edit form needs space)
    if (isTablet &&
        !hasEditingItem &&
        _cartViewMode == CartViewMode.gridMedium) {
      return _buildCartGridView(colors, isDark);
    } else if (isTablet &&
        !hasEditingItem &&
        _cartViewMode == CartViewMode.largeIcons) {
      return _buildCartLargeIconView(colors, isDark);
    }

    // Default list view - use CustomScrollView so header scrolls with content
    // This prevents overflow when keyboard appears on tablets
    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Optional Tablet Header Row mimicking the desktop grid (not shown in compact view)
          if (isTablet && !_isCompactView)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey.shade200,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Space for thumbnail
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: _buildGridHeader("Code", colors)),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 4,
                      child: _buildGridHeader("Description", colors),
                    ),
                    SizedBox(
                      width: 120,
                      child: _buildGridHeader(
                        "Price",
                        colors,
                        alignRight: true,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Center(child: _buildGridHeader("Qty", colors)),
                    ),
                    SizedBox(
                      width: 130,
                      child: _buildGridHeader("Ext", colors, alignRight: true),
                    ),
                  ],
                ),
              ),
            ),

          // Cart List
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: _isCompactView ? 2 : 6,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _cartItems[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _cartItems.length - 1
                        ? (_isCompactView ? 0 : 4)
                        : 0,
                  ),
                  child: AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: _buildCartTileWithEditMode(
                          item,
                          index,
                          colors,
                          isDark,
                          isTablet,
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: _cartItems.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockingOverlay({
    required AppThemeColors colors,
    required bool isDark,
    required String message,
    bool showPanel = true,
  }) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black45,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: showPanel
                      ? Container(
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
                          child: _buildBlockingContent(message, isDark),
                        )
                      : _buildBlockingContent(message, isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockingContent(String message, bool isDark) {
    final hasMessage = message.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
        ),
        if (hasMessage) ...[
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }

  void _updatePostSyncing() {
    if (!mounted) return;
    final syncing = _postStockSyncing || _postCustomerSyncing;
    setState(() => _isPostSyncing = syncing);
    if (!syncing) {
      _postSaleSyncRequested = false;
    }
  }

  Widget _buildGridHeader(
    String title,
    AppThemeColors colors, {
    bool alignRight = false,
  }) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceMuted,
      ),
    );
  }

  /// Grid view for cart items (2 columns, horizontal tiles)
  Widget _buildCartGridView(AppThemeColors colors, bool isDark) {
    final bool isMediumTablet = context.isMediumTablet;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isLargeTablet = !isMediumTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);

    // Calculate aspect ratio based on content needs (higher = shorter tiles)
    // Large tablets get taller tiles (lower aspect ratio)
    final double childAspectRatio = isLandscape
        ? (isMediumTablet ? 5.5 : (isLargeTablet ? 5.8 : 5.2))
        : (isMediumTablet ? 3.4 : (isLargeTablet ? 4.0 : 3.2));

    return AnimationLimiter(
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildCartGridTile(item, index, colors, isDark, uiScale),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Large icon view for cart items (3-4 columns, vertical tiles with larger thumbnails)
  Widget _buildCartLargeIconView(AppThemeColors colors, bool isDark) {
    final bool isMediumTablet = context.isMediumTablet;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isLargeTablet = !isMediumTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);

    // More columns for medium tablets, and in landscape mode use 6 columns with smaller cards
    final int crossAxisCount = isLandscape ? 6 : (isMediumTablet ? 5 : 4);
    // Landscape: higher aspect ratio for smaller cards, Portrait: lower for taller cards
    final double childAspectRatio = isLandscape
        ? (isMediumTablet ? 0.88 : 0.95)
        : (isMediumTablet ? 0.65 : 0.60);
    // More spacing in landscape, less in portrait
    final double spacing = isLandscape ? 14 : 8;

    // For large tablets, use Wrap with flexible height cards
    if (isLargeTablet) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double horizontalPadding = 24; // 12 left + 12 right
      final double totalSpacing = spacing * (crossAxisCount - 1);
      final double cardWidth =
          (screenWidth - horizontalPadding - totalSpacing) / crossAxisCount;

      return AnimationLimiter(
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 80,
            ),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: _cartItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  columnCount: crossAxisCount,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: SizedBox(
                        width: cardWidth,
                        child: _buildCartLargeIconTileFlexible(
                          item,
                          index,
                          colors,
                          isDark,
                          uiScale,
                          isLandscape,
                          cardWidth,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    // For medium tablets and phones, use GridView with fixed aspect ratio
    return AnimationLimiter(
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildCartLargeIconTile(
                  item,
                  index,
                  colors,
                  isDark,
                  uiScale,
                  isLandscape,
                  false, // isLargeTabletPortrait - not used for medium tablets
                  false, // isLargeTablet
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Grid tile for cart item (horizontal layout)
  Widget _buildCartGridTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
    double uiScale,
  ) {
    final bool isMediumTablet = context.isMediumTablet;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isLargeTablet = !isMediumTablet;
    // Wider thumbnail in landscape, even wider for large tablets
    final double thumbnailSize = isLandscape
        ? (isMediumTablet ? 115 : (isLargeTablet ? 140 : 125))
        : (isMediumTablet ? 95 : (isLargeTablet ? 130 : 105));
    final double displayPrice = _isIncTax ? item.incPrice : item.exPrice;
    final double displayExt = _isIncTax ? item.extension : item.extensionEx;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _salesBloc.add(EditCartItem(index: index));
      },
      child: Dismissible(
        key: Key('cart_grid_${item.code}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        onDismissed: (_) {
          _salesBloc.add(RemoveCartItem(index: index));
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.lerp(colors.surface, Colors.white, 0.06)
                : kSecondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.18))
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : kThirdColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: thumbnailSize,
                height: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: item.stock?.imageUrl != null
                      ? Image.network(
                          item.stock!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            overviewPlaceholder,
                            fit: BoxFit.fill,
                          ),
                        )
                      : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                ),
              ),
              // Item details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 6,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Description
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 14 : 13 * uiScale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : kThirdColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Code/Barcode
                        Text(
                          item.code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isLargeTablet ? 13 : 11 * uiScale,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Price and Qty row - fully scrollable
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              Text(
                                FormattingUtils.formatCurrencyWithDecimals(
                                  displayPrice,
                                  2,
                                ),
                                style: TextStyle(
                                  fontSize: 12 * uiScale,
                                  color: colors.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colors.surface
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "x ${formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false)}",
                                  style: TextStyle(
                                    fontSize: 11 * uiScale,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.blueGrey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "=",
                                style: TextStyle(
                                  fontSize: 12 * uiScale,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Extension price
                              Text(
                                FormattingUtils.formatCurrencyWithDecimals(
                                  displayExt,
                                  2,
                                ),
                                style: TextStyle(
                                  fontSize: 13 * uiScale,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Large icon tile for cart item (vertical layout with larger thumbnail)
  Widget _buildCartLargeIconTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
    double uiScale,
    bool isLandscape,
    bool isLargeTabletPortrait,
    bool isLargeTablet,
  ) {
    // final double displayPrice = _isIncTax
    //     ? item.incPrice
    //     : item.exPrice;
    final double displayExt = _isIncTax ? item.extension : item.extensionEx;

    // Flex ratios: large tablets get higher thumbnail ratio to preserve image size with shorter cards
    final int thumbnailFlex = isLargeTablet
        ? (isLargeTabletPortrait ? 11 : 13)
        : 13;
    final int detailsFlex = isLargeTablet ? (isLargeTabletPortrait ? 4 : 5) : 7;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _salesBloc.add(EditCartItem(index: index));
      },
      child: Dismissible(
        key: Key('cart_largeicon_${item.code}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        onDismissed: (_) {
          _salesBloc.add(RemoveCartItem(index: index));
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.lerp(colors.surface, Colors.white, 0.06)
                : kSecondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.18))
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : kThirdColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail (larger, takes most space)
              Expanded(
                flex: thumbnailFlex,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    // color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.stock?.imageUrl != null
                            ? Image.network(
                                item.stock!.imageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  overviewPlaceholder,
                                  fit: BoxFit.fill,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Image.asset(
                                overviewPlaceholder,
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      // Qty badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "x ${formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false)}",
                            style: TextStyle(
                              fontSize: 11 * uiScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Item details
              Expanded(
                flex: detailsFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Description
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 14 : 12 * uiScale,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : kThirdColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        // Code/Barcode
                        Text(
                          item.code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isLargeTablet ? 13 : 10 * uiScale,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        // Extension
                        Text(
                          FormattingUtils.formatCurrencyWithDecimals(
                            displayExt,
                            2,
                          ),
                          style: TextStyle(
                            fontSize: 13 * uiScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Large icon tile with flexible height for large tablets (content-based height)
  Widget _buildCartLargeIconTileFlexible(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
    double uiScale,
    bool isLandscape,
    double cardWidth,
  ) {
    final double displayExt = _isIncTax ? item.extension : item.extensionEx;

    // Calculate thumbnail height based on card width (square-ish with some ratio)
    final double thumbnailHeight = isLandscape ? cardWidth * 0.85 : cardWidth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _salesBloc.add(EditCartItem(index: index));
      },
      child: Dismissible(
        key: Key('cart_largeicon_flex_${item.code}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        onDismissed: (_) {
          _salesBloc.add(RemoveCartItem(index: index));
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.lerp(colors.surface, Colors.white, 0.06)
                : kSecondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.18))
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : kThirdColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Allow content-based height
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail with fixed height based on card width
              Container(
                width: double.infinity,
                height: thumbnailHeight,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.stock?.imageUrl != null
                          ? Image.network(
                              item.stock!.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                overviewPlaceholder,
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Image.asset(
                              overviewPlaceholder,
                              fit: BoxFit.fill,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    // Qty badge
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "x ${formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false)}",
                          style: TextStyle(
                            fontSize: 11 * uiScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Item details - flexible height content
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : kThirdColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    // Code/Barcode
                    Text(
                      item.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    // Extension (price)
                    Text(
                      FormattingUtils.formatCurrencyWithDecimals(displayExt, 2),
                      style: TextStyle(
                        fontSize: 13 * uiScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a cart tile based on edit mode state
  Widget _buildCartTileWithEditMode(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    // If item is in edit mode, show expanded edit tile
    if (item.isEditing) {
      return ExpandedEditCartTile(
        item: item,
        index: index,
        colors: colors,
        isDark: isDark,
        isTablet: isTablet,
        isIncTax: _isIncTax,
        allowPriceEdit: AppGlobals.instance.hasPermission(
          "Miscellaneous_LockSellPrice",
        ),
        hideSerialButton: widget.title == "Quotes",
        onQtyChanged: (qty) {
          _salesBloc.add(UpdateCartItemQty(index: index, qty: qty));
        },
        onPriceChanged: (price) {
          if (price < 0) {
            _showNegativeSellPriceError();
            return;
          }
          _salesBloc.add(
            UpdateCartItemPrice(
              index: index,
              price: price,
              isIncPrice: _isIncTax,
            ),
          );
        },
        onSerialChanged: (serials) {
          _salesBloc.add(
            UpdateCartItemSerial(index: index, serialNumbers: serials),
          );
        },
        onDescriptionChanged: (description) {
          _salesBloc.add(
            UpdateCartItemDescription(index: index, description: description),
          );
        },
        onSave: () {
          _salesBloc.add(
            SaveCartItem(
              index: index,
              autoRemindLowStock: _autoRemindLowStock,
              oneDisplayLinePerItem: _oneDisplayLinePerItem,
            ),
          );
        },
        onDelete: () {
          _salesBloc.add(RemoveCartItem(index: index));
        },
      );
    }

    final Widget tile = _isCompactView
        ? _buildCompactCartTile(item, index, colors, isDark)
        : (isTablet
            ? _buildTabletCartTile(item, index, colors, isDark)
            : _buildMobileCartTile(item, index, colors, isDark));

    // Wrap with slide-to-delete and tap to edit
    return DismissibleCartTile(
      isDark: isDark,
      colors: colors,
      onDelete: () {
        _salesBloc.add(RemoveCartItem(index: index));
      },
      child: GestureDetector(
        onTap: () {
          _salesBloc.add(EditCartItem(index: index));
        },
        child: tile,
      ),
    );
  }

  Widget _buildMobileCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return MobileCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildTabletCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return TabletCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildCompactCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return CompactCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildBottomSummary(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Totals Row
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actions Button and Finalise Button (left column)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Actions Button - offset upward
                        Transform.translate(
                          offset: Offset(0, isTablet ? -8 : -6),
                          child: _buildActionsButton(colors, isDark, isTablet),
                        ),
                        const SizedBox(height: 12),
                        // Finalise Button
                        _buildFinaliseButton(colors, isDark, isTablet),
                      ],
                    ),

                    SizedBox(width: isTablet ? 38 : 5),

                    // Balance display
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(isTablet ? -32 : 0, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Balance label
                              Text(
                                "Balance",
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12.5,
                                  color: colors.onSurfaceMuted,
                                ),
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              // Balance amount in border
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 8,
                                  vertical: isTablet ? 2 : 7,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  FormattingUtils.formatCurrencyWithDecimals(
                                    _totalPaid >= _total
                                        ? 0.0
                                        : _total - _totalPaid,
                                    2,
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 18,
                                    letterSpacing: -0.5,
                                    color: isDark
                                        ? Colors.white
                                        : colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isTablet ? 0 : 5),

                    Transform.translate(
                      offset: Offset(isTablet ? -10 : 0, 0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 200 : 110,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isTablet ? 'Subtotal' : 'Sub'}: ${FormattingUtils.formatCurrencyWithDecimals(_displaySubtotal, 2)}",
                              style: TextStyle(
                                color: colors.onSurfaceMuted,
                                fontSize: isTablet ? 14 : 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 6 : 8),
                            Text(
                              "${isTablet ? 'Discount' : 'Dis'}: ${FormattingUtils.formatCurrencyWithDecimals(_discount, 2)}",
                              style: TextStyle(
                                color: _discount > 0
                                    ? kPrimaryColor
                                    : colors.onSurfaceMuted,
                                fontSize: isTablet ? 14 : 12.5,
                                fontWeight: _discount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 6 : 8),
                            Text(
                              "Rounding: ${FormattingUtils.formatCurrencyWithDecimals(_rounding, 2)}",
                              style: TextStyle(
                                color: colors.onSurfaceMuted,
                                fontSize: isTablet ? 14 : 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 14 : 22),
                            Transform.translate(
                              offset: Offset(0, isTablet ? 0 : -8),
                              child: Text(
                                FormattingUtils.formatCurrencyWithDecimals(
                                  _displayTotal,
                                  2,
                                ),
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFinaliseDialog() async {
    final isAccountSales = widget.title == "Account Sales";
    final isSalesOrder = widget.title == "Sales Order";
    final isQuotes = widget.title == "Quotes";
    final isLayby = widget.title == "Lay-bys";
    final isSales = widget.title == "Sales";

    final hasIncompleteSerials = _cartItems.any((item) {
      if (!item.trackSerial) return false;
      final requiredQty = item.qty.toInt();
      if (requiredQty <= 0) return false;
      final assignedCount = item.serialNumbers
          .where((serial) => serial.number.trim().isNotEmpty)
          .length;
      return assignedCount < requiredQty;
    });

    if (hasIncompleteSerials && !isQuotes) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final colors = context.appColors;
          final isDark = colors.isDark;
          return StandardDialog(
            title: "RetailManager Question",
            colors: colors,
            isDark: isDark,
            onClose: () => Navigator.pop(ctx, false),
            content: Text(
              "You have not selected or entered all required serial numbers\n\nContinue?",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 15,
              ),
            ),
            actions: [
              DialogTextAction(
                label: "No",
                style: DialogActionStyle.outline,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              DialogTextAction(
                label: "Yes",
                style: DialogActionStyle.primary,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      );
      if (shouldContinue != true) {
        return;
      }
    }

    // Check if sale is at a loss and prompt for confirmation
    final totals = _calculatedTotals;
    if (totals.totalGp < 0) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final colors = context.appColors;
          final isDark = colors.isDark;
          return StandardDialog(
            title: "Selling at Loss",
            colors: colors,
            isDark: isDark,
            onClose: () => Navigator.pop(ctx, false),
            content: Text(
              "The item(s) are being sold at a loss, continue?",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 15,
              ),
            ),
            actions: [
              DialogTextAction(
                label: "Cancel",
                style: DialogActionStyle.cancelOutline,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              DialogTextAction(
                label: "Continue",
                style: DialogActionStyle.primary,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      );
      if (shouldContinue != true) {
        return;
      }
    }

    // Check for out of stock items if in Account Sales and setting is enabled
    if (isAccountSales && _preventFinaliseIfOutOfStock) {
      final outOfStockItems = _getOutOfStockItems();
      if (outOfStockItems.isNotEmpty) {
        final colors = context.appColors;
        OutOfStockFinaliseDialog.show(
          context: context,
          outOfStockItems: outOfStockItems,
          colors: colors,
          isDark: colors.isDark,
        );
        return;
      }
    }

    final result = await FinaliseSaleDialog.show(
      context: context,
      customer: _selectedCustomer,
      total: _total,
      initialPaymentAmounts: Map.from(_paymentAmounts),
      promptForEmail: _promptForEmailAtSale,
      showPayments: isSales,
      title: widget.title,
    );

    if (result == null) {
      return;
    }

    // Always update payment amounts from dialog (even on cancel)
    if (result.paymentData != null) {
      setState(() {
        _paymentAmounts.clear();
        _paymentAmounts.addAll(result.paymentData!.paymentAmounts);
      });
    }

    if (result.result == FinaliseSaleResult.cancelled) {
      return;
    }

    if (isAccountSales || isSalesOrder || isQuotes || isLayby) {
      _setFinaliseProcessing(true);
      try {
        final includeEmailAudit = result.result == FinaliseSaleResult.email;
        _emailAuditData = includeEmailAudit
            ? EmailAuditData(
                auditDate: DateTime.now(),
                status: 0,
                subject: '',
                message: '',
              )
            : null;

        if (includeEmailAudit) {
          final enteredEmail = result.emailData?.email.trim() ?? '';
          final updated = await _maybeUpdateCustomerEmail(enteredEmail);
          if (!updated) {
            return;
          }
        }

        final sent = isSalesOrder
            ? await _sendSalesOrder(includeEmailAudit: includeEmailAudit)
            : isQuotes
            ? await _sendQuote(includeEmailAudit: includeEmailAudit)
            : isLayby
            ? await _sendLayby(includeEmailAudit: includeEmailAudit)
            : await _sendAccountInvoice(includeEmailAudit: includeEmailAudit);
        if (!sent) {
          return;
        }
      } finally {
        _setFinaliseProcessing(false);
      }
    }

    // Clear everything
    _clearSale();
  }

  Future<bool> _sendAccountInvoice({required bool includeEmailAudit}) async {
    if (widget.title != "Account Sales") return true;

    if (_selectedCustomer == null) {
      _showAccountSalesError("Please select a customer for Account Sales.");
      return false;
    }

    try {
      final payload = await _buildAccountInvoicePayload(
        includeEmailAudit: includeEmailAudit,
      );
      _printInChunks('Account invoice payload: ${jsonEncode(payload)}');

      final response = await _salesBloc.createAccountInvoice(payload);
      if (!response.success) {
        _showAccountSalesError(
          response.message.isNotEmpty
              ? response.message
              : "Failed to create account invoice.",
        );
        return false;
      }

      _showAccountSalesSuccess(
        response.message.isNotEmpty
            ? response.message
            : "Account invoice sent.",
      );
      return true;
    } catch (error) {
      _showAccountSalesError("Failed to send account invoice: $error");
      return false;
    }
  }

  Future<bool> _sendSalesOrder({required bool includeEmailAudit}) async {
    if (widget.title != "Sales Order") return true;

    if (_selectedCustomer == null) {
      _showAccountSalesError("Please select a customer for Sales Order.");
      return false;
    }

    try {
      final payload = await _buildSalesOrderPayload(
        includeEmailAudit: includeEmailAudit,
      );
      _printInChunks('Sales order payload: ${jsonEncode(payload)}');

      final response = await _salesBloc.createSalesOrder(payload);
      if (!response.success) {
        _showAccountSalesError(
          response.message.isNotEmpty
              ? response.message
              : "Failed to create sales order.",
        );
        return false;
      }

      _showAccountSalesSuccess(
        response.message.isNotEmpty ? response.message : "Sales order sent.",
      );
      return true;
    } catch (error) {
      _showAccountSalesError("Failed to send sales order: $error");
      return false;
    }
  }

  Future<bool> _sendQuote({required bool includeEmailAudit}) async {
    if (widget.title != "Quotes") return true;

    if (_selectedCustomer == null) {
      _showAccountSalesError("Please select a customer for Quote.");
      return false;
    }

    try {
      final payload = await _buildQuotePayload(
        includeEmailAudit: includeEmailAudit,
      );
      _printInChunks('Quote payload: ${jsonEncode(payload)}');

      final response = await _salesBloc.createQuote(payload);
      if (!response.success) {
        _showAccountSalesError(
          response.message.isNotEmpty
              ? response.message
              : "Failed to create quote.",
        );
        return false;
      }

      _showAccountSalesSuccess(
        response.message.isNotEmpty ? response.message : "Quote sent.",
      );
      return true;
    } catch (error) {
      _showAccountSalesError("Failed to send quote: $error");
      return false;
    }
  }

  Future<bool> _sendLayby({required bool includeEmailAudit}) async {
    if (widget.title != "Lay-bys") return true;

    if (_selectedCustomer == null) {
      _showAccountSalesError("Please select a customer for Lay-by.");
      return false;
    }

    try {
      final payload = await _buildLaybyPayload(
        includeEmailAudit: includeEmailAudit,
      );
      _printInChunks('Lay-by payload: ${jsonEncode(payload)}');

      final response = await _salesBloc.createLayby(payload);
      if (!response.success) {
        _showAccountSalesError(
          response.message.isNotEmpty
              ? response.message
              : "Failed to create lay-by.",
        );
        return false;
      }

      _showAccountSalesSuccess(
        response.message.isNotEmpty ? response.message : "Lay-by sent.",
      );
      return true;
    } catch (error) {
      _showAccountSalesError("Failed to send lay-by: $error");
      return false;
    }
  }

  Future<bool> _maybeUpdateCustomerEmail(String email) async {
    if (_selectedCustomer == null) {
      _showAccountSalesError("Please select a customer for Account Sales.");
      return false;
    }

    final customer = _selectedCustomer!;
    final currentEmail = customer.email.trim();
    final updatedEmail = email.trim();
    final shouldUpdate = updatedEmail != currentEmail || currentEmail.isEmpty;

    if (!shouldUpdate) {
      return true;
    }

    final body = _buildCustomerEmailUpdateBody(customer, updatedEmail);
    try {
      final response = await _salesBloc.updateCustomerDetails(body);
      if (!response.success) {
        _showAccountSalesError(
          response.message.isNotEmpty
              ? response.message
              : "Failed to update customer email.",
        );
        return false;
      }
      return true;
    } catch (error) {
      _showAccountSalesError("Failed to update customer email: $error");
      return false;
    }
  }

  Map<String, dynamic> _buildCustomerEmailUpdateBody(
    CustomerVO customer,
    String email,
  ) {
    final Map<String, dynamic> item = <String, dynamic>{
      'customerId': customer.customerId,
      'barcode': customer.barcode,
      'date_modified': customer.dateModified,
      'surname': customer.surname,
      'givenNames': customer.givenNames,
      'grade': customer.grade,
      'company': customer.company,
      'position': customer.position,
      'salutation': customer.salutation,
      'status': customer.status,
      'inactive': customer.inactive,
      'account': customer.account,
      'overseas': customer.overseas,
      'abn': customer.abn,
      'addr1': customer.addr1,
      'addr2': customer.addr2,
      'addr3': customer.addr3,
      'suburb': customer.suburb,
      'state': customer.state,
      'postcode': customer.postcode,
      'country': customer.country,
      'phone': customer.phone,
      'fax': customer.fax,
      'mobile': customer.mobile,
      'email': email,
      'openedId': customer.openedId,
      'opened_id': customer.openedId,
      'ownerId': customer.ownerId,
      'owner_id': customer.ownerId,
      'fromEOM': customer.fromEOM,
      'days': customer.days,
      'limit': customer.limit,
      'defaultDeliveryAddress': customer.defaultDeliveryAddress,
      'documentDeliveryType': customer.documentDeliveryType,
      'custom1': customer.custom1,
      'custom2': customer.custom2,
      'notes': customer.notes,
      'comments': customer.comments,
    };

    return <String, dynamic>{
      'items': [item],
    };
  }

  Future<Map<String, dynamic>> _buildAccountInvoicePayload({
    required bool includeEmailAudit,
  }) async {
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) {
      return Future.error(
        "Missing shopfront setup. Please reconnect to a host and shopfront.",
      );
    }

    final cartItemsData = await Future.wait(
      _cartItems.map(
        (item) => CartItemData.fromCartItemAsync(item, shopfront: shopfront),
      ),
    );

    final lines = cartItemsData
        .where((item) => item.isPackage != true)
        .map(_buildInvoiceLine)
        .toList();

    final packages = cartItemsData
        .where((item) => item.isPackage == true)
        .map(_buildInvoicePackage)
        .toList();

    final drawer = await _salesBloc.fetchCashDrawerIdentifier(fallback: 'M');

    final totals = _calculatedTotals;

    final int? customerId = _selectedCustomer?.customerId;
    if (customerId == null || customerId <= 0) {
      return Future.error("Missing customer for Account Sales.");
    }

    // For Account Sales, use customer's owner_id (fallback to logged-in staff if no owner)
    final int? staffId =
        widget.title == 'Account Sales' && _selectedCustomer != null
        ? (_selectedCustomer!.ownerId > 0
              ? _selectedCustomer!.ownerId
              : AppGlobals.instance.staffId)
        : AppGlobals.instance.staffId;

    if (staffId == null || staffId <= 0) {
      return Future.error("Missing staff id.");
    }

    final payload = <String, dynamic>{
      'customerId': customerId,
      'staffId': staffId,
      'transactionDate':
          _lastSessionUpdatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'custom': _surveyValue,
      'comments': _commentValue,
      'drawer': drawer,
      'origin': 0,
      'subtotal': _subtotal,
      'discount': _discountValue,
      'rounding': _rounding,
      'totalEx': totals.totalEx,
      'totalInc': _total,
      'gp': totals.totalGp,
      'lines': lines,
      'packages': packages,
    };

    if (_committedDeliveryAddress != null) {
      payload['deliveryAddress'] = _committedDeliveryAddress!.toApiPayload();
    }

    if (includeEmailAudit && _emailAuditData != null) {
      payload['emailAudit'] = _emailAuditData!.toApiPayload();
    }

    return payload;
  }

  Future<Map<String, dynamic>> _buildSalesOrderPayload({
    required bool includeEmailAudit,
  }) async {
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) {
      return Future.error(
        "Missing shopfront setup. Please reconnect to a host and shopfront.",
      );
    }

    final cartItemsData = await Future.wait(
      _cartItems.map(
        (item) => CartItemData.fromCartItemAsync(item, shopfront: shopfront),
      ),
    );

    final drawer = await _salesBloc.fetchCashDrawerIdentifier(fallback: 'M');

    final totals = _calculatedTotals;

    final int? customerId = _selectedCustomer?.customerId;
    if (customerId == null || customerId <= 0) {
      return Future.error("Missing customer for Sales Order.");
    }

    // For Sales Order, always use logged-in staff
    final int? staffId = AppGlobals.instance.staffId;

    if (staffId == null || staffId <= 0) {
      return Future.error("Missing staff id.");
    }

    final payload = <String, dynamic>{
      'transactionType': 'SO',
      'customerId': customerId,
      'staffId': staffId,
      'transactionDate':
          _lastSessionUpdatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'custom': _surveyValue,
      'comments': _commentValue,
      'drawer': drawer,
      'subtotal': _subtotal,
      'discount': _discountValue,
      'rounding': _rounding,
      'totalEx': totals.totalEx,
      'totalInc': _total,
      'status': 0,
      'lines': cartItemsData
          .map((item) => _buildSalesOrderLine(item, includeSerialNumbers: true))
          .toList(growable: false),
    };

    if (_committedDeliveryAddress != null) {
      payload['deliveryAddress'] = _committedDeliveryAddress!.toApiPayload();
    }

    if (includeEmailAudit && _emailAuditData != null) {
      payload['emailAudit'] = _emailAuditData!.toApiPayload();
    }

    return payload;
  }

  Future<Map<String, dynamic>> _buildQuotePayload({
    required bool includeEmailAudit,
  }) async {
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) {
      return Future.error(
        "Missing shopfront setup. Please reconnect to a host and shopfront.",
      );
    }

    final cartItemsData = await Future.wait(
      _cartItems.map(
        (item) => CartItemData.fromCartItemAsync(item, shopfront: shopfront),
      ),
    );

    final totals = _calculatedTotals;

    final int? customerId = _selectedCustomer?.customerId;
    if (customerId == null || customerId <= 0) {
      return Future.error("Missing customer for Quote.");
    }

    final int? staffId = AppGlobals.instance.staffId;
    if (staffId == null || staffId <= 0) {
      return Future.error("Missing staff id.");
    }

    final payload = <String, dynamic>{
      'transactionType': 'QU',
      'customerId': customerId,
      'staffId': staffId,
      'transactionDate':
          _lastSessionUpdatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'custom': _surveyValue,
      'comments': _commentValue,
      'subtotal': _subtotal,
      'discount': _discountValue,
      'rounding': _rounding,
      'totalEx': totals.totalEx,
      'totalInc': _total,
      'status': 3,
      'lines': cartItemsData
          .map(
            (item) => _buildSalesOrderLine(item, includeSerialNumbers: false),
          )
          .toList(growable: false),
    };

    if (_committedDeliveryAddress != null) {
      payload['deliveryAddress'] = _committedDeliveryAddress!.toApiPayload();
    }

    if (includeEmailAudit && _emailAuditData != null) {
      payload['emailAudit'] = _emailAuditData!.toApiPayload();
    }

    return payload;
  }

  Future<Map<String, dynamic>> _buildLaybyPayload({
    required bool includeEmailAudit,
  }) async {
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) {
      return Future.error(
        "Missing shopfront setup. Please reconnect to a host and shopfront.",
      );
    }

    final cartItemsData = await Future.wait(
      _cartItems.map(
        (item) => CartItemData.fromCartItemAsync(item, shopfront: shopfront),
      ),
    );

    final lines = cartItemsData
        .where((item) => item.isPackage != true)
        .map(_buildInvoiceLine)
        .toList();

    final packages = cartItemsData
        .where((item) => item.isPackage == true)
        .map(_buildInvoicePackage)
        .toList();

    final drawer = await _salesBloc.fetchCashDrawerIdentifier(fallback: 'M');

    final totals = _calculatedTotals;

    final int? customerId = _selectedCustomer?.customerId;
    if (customerId == null || customerId <= 0) {
      return Future.error("Missing customer for Lay-by.");
    }

    // For Lay-by, always use logged-in staff
    final int? staffId = AppGlobals.instance.staffId;
    if (staffId == null || staffId <= 0) {
      return Future.error("Missing staff id.");
    }

    final payload = <String, dynamic>{
      'customerId': customerId,
      'staffId': staffId,
      'transactionDate':
          _lastSessionUpdatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'custom': _surveyValue,
      'comments': _commentValue,
      'drawer': drawer,
      'subtotal': _subtotal,
      'discount': _discountValue,
      'rounding': _rounding,
      'totalEx': totals.totalEx,
      'totalInc': _total,
      'gp': totals.totalGp,
      'lines': lines,
      'packages': packages,
    };

    if (_committedDeliveryAddress != null) {
      payload['deliveryAddress'] = _committedDeliveryAddress!.toApiPayload();
    }

    if (includeEmailAudit && _emailAuditData != null) {
      payload['emailAudit'] = _emailAuditData!.toApiPayload();
    }

    return payload;
  }

  Map<String, dynamic> _buildInvoiceLine(CartItemData item) {
    final payload = <String, dynamic>{
      'stockId': item.stockId ?? 0,
      'quantity': item.qty,
      'costEx': item.costEx,
      'costInc': item.costInc,
      'salesTax': item.salesTax ?? '',
      'sellEx': item.sellEx,
      'sellInc': item.sellInc,
      'rrp': item.rrp ?? item.sellInc,
      'gp': item.gp,
      'unitOfMeasure': item.unitOfMeasure ?? 0,
      'isFreight': item.isFreight,
      'isStatic': item.isStatic,
    };

    final serialNumbers = _serialNumbersPayload(item);
    if (serialNumbers != null) {
      payload['serial_numbers'] = serialNumbers;
    }

    if (item.description?.isNotEmpty == true) {
      payload['description'] = item.description;
    }

    if (item.isPromotion) {
      payload['isPromotion'] = true;
    }

    return payload;
  }

  Map<String, dynamic> _buildSalesOrderComponentLine(CartItemData item) {
    final payload = <String, dynamic>{
      'stockId': item.stockId ?? 0,
      'quantity': item.qty,
      'costEx': item.costEx,
      'costInc': item.costInc,
      'salesTax': item.salesTax ?? '',
      'sellEx': item.sellEx,
      'sellInc': item.sellInc,
      'rrp': item.rrp ?? item.sellInc,
      'gp': item.gp,
      'unitOfMeasure': item.unitOfMeasure ?? 0,
      'isFreight': item.isFreight,
      'isStatic': item.isStatic,
      'isPromotion': item.isPromotion,
      'isPackage': false,
    };

    if (item.description?.isNotEmpty == true) {
      payload['description'] = item.description;
    }

    return payload;
  }

  Map<String, dynamic> _buildSalesOrderLine(
    CartItemData item, {
    required bool includeSerialNumbers,
  }) {
    final payload = <String, dynamic>{
      'stockId': item.stockId ?? 0,
      'quantity': item.qty,
      'costEx': item.costEx,
      'costInc': item.costInc,
      'salesTax': item.salesTax ?? '',
      'sellEx': item.sellEx,
      'sellInc': item.sellInc,
      'rrp': item.rrp ?? item.sellInc,
      'gp': item.gp,
      'unitOfMeasure': item.unitOfMeasure ?? 0,
      'isFreight': item.isFreight,
      'isStatic': item.isStatic,
      'isPromotion': item.isPromotion,
      'isPackage': item.isPackage,
    };

    if (includeSerialNumbers) {
      final serialNumbers = _serialNumbersPayload(item);
      if (serialNumbers != null) {
        payload['serial_numbers'] = serialNumbers;
      }
    }

    if (item.description?.isNotEmpty == true) {
      payload['description'] = item.description;
    }

    if (item.isPackage && item.packageComponents != null) {
      payload['components'] = item.packageComponents!
          .map(_buildSalesOrderComponentLine)
          .toList(growable: false);
    }

    return payload;
  }

  Map<String, dynamic> _buildInvoiceComponentLine(CartItemData item) {
    final payload = <String, dynamic>{
      'stockId': item.stockId ?? 0,
      'quantity': item.qty,
      'costEx': item.costEx,
      'costInc': item.costInc,
      'salesTax': item.salesTax ?? '',
      'sellEx': item.sellEx,
      'sellInc': item.sellInc,
      'rrp': item.rrp ?? item.sellInc,
      'gp': item.gp,
      'unitOfMeasure': item.unitOfMeasure ?? 0,
      'isFreight': item.isFreight,
      'isStatic': item.isStatic,
    };

    if (item.description?.isNotEmpty == true) {
      payload['description'] = item.description;
    }

    return payload;
  }

  Map<String, dynamic> _buildInvoicePackage(CartItemData item) {
    final components = item.packageComponents ?? const <CartItemData>[];

    final payload = <String, dynamic>{
      'packageId': item.stockId ?? 0,
      'quantity': item.qty,
      'salesTax': item.salesTax ?? '',
      'costEx': item.costEx,
      'costInc': item.costInc,
      'sellEx': item.sellEx,
      'sellInc': item.sellInc,
      'rrp': item.rrp ?? item.sellInc,
      'gp': item.gp,
      'componentLines': components
          .map(_buildInvoiceComponentLine)
          .toList(growable: false),
    };

    final serialNumbers = _serialNumbersPayload(item);
    if (serialNumbers != null) {
      payload['serial_numbers'] = serialNumbers;
    }

    if (item.description?.isNotEmpty == true) {
      payload['description'] = item.description;
    }

    return payload;
  }

  List<Map<String, dynamic>>? _serialNumbersPayload(CartItemData item) {
    if (item.serialNumbers.isEmpty) return null;
    final serials = item.serialNumbers
        .where((serial) => serial.number.trim().isNotEmpty)
        .map((serial) => serial.toApiPayload())
        .toList();
    if (serials.isEmpty) return null;
    return serials;
  }

  void _showAccountSalesError(String message) {
    if (!mounted) return;
    final colors = context.appColors;
    final isDark = colors.isDark;
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.error,
      backgroundColor: isDark ? colors.surface : kSecondaryColor,
      iconColor: kErrorColor,
      textColor: kErrorColor,
      position: MessagePosition.top,
      padding: 70,
    );
  }

  void _showAccountSalesSuccess(String message) {
    if (!mounted) return;
    final colors = context.appColors;
    final isDark = colors.isDark;
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.success,
      backgroundColor: isDark ? colors.surface : kSecondaryColor,
      iconColor: kPrimaryColor,
      textColor: kPrimaryColor,
      position: MessagePosition.top,
      padding: 70,
    );
  }

  void _showNegativeSellPriceError() {
    if (!mounted || _isNegativeSellPriceDialogOpen) return;
    _isNegativeSellPriceDialogOpen = true;

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.appColors;
        final isDark = colors.isDark;
        return StandardDialog(
          title: "RetailManager Error",
          colors: colors,
          isDark: isDark,
          onClose: () => Navigator.pop(ctx),
          content: Text(
            "Sell price cannot be negative.",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            DialogTextAction(
              label: "OK",
              style: DialogActionStyle.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isNegativeSellPriceDialogOpen = false;
    });
  }

  void _setFinaliseProcessing(bool value) {
    if (!mounted) return;
    setState(() => _isFinaliseProcessing = value);
  }

  void _printInChunks(String message, {int chunkSize = 800}) {
    if (message.length <= chunkSize) {
      // ignore: avoid_print
      print(message);
      return;
    }

    for (var i = 0; i < message.length; i += chunkSize) {
      final end = (i + chunkSize < message.length)
          ? i + chunkSize
          : message.length;
      // ignore: avoid_print
      print(message.substring(i, end));
    }
  }

  void _clearSale() {
    // Delete the current session since sale was committed
    _deleteCurrentSession();

    setState(() {
      _salesBloc.add(ClearCart());
      _selectedCustomer = null;
      _deliveryInfo = null;
      _committedDeliveryAddress = null;
      _emailAuditData = null;
      _paymentAmounts.clear();
      _discountValue = 0.00;
      _discountController.text = "0.00";
      _searchController.clear();
      _surveyValue = '';
      _surveyController.clear();
      _commentValue = '';
      _lastSessionUpdatedAt = null;
    });

    _runPostSaleDeltaSync();
  }

  void _runPostSaleDeltaSync() {
    if (!mounted) return;

    _postSaleSyncRequested = true;
    _postStockSyncing = true;
    _postCustomerSyncing = false;
    _updatePostSyncing();

    // Trigger delta sync for stocks after successful sale
    context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
  }

  void _showSurveyScannerDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final isTablet = context.isTablet;
    final scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      returnImage: false,
    );
    String? scannedValue;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? colors.surface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: isTablet ? 400 : 300,
                height: isTablet ? 320 : 260,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 16 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: kPrimaryColor,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Text(
                              "Scan for $_surveyLabel",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              scannerController.dispose();
                              Navigator.pop(ctx);
                            },
                            child: Icon(
                              Icons.close,
                              color: isDark ? Colors.white54 : Colors.black45,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scanner or scanned value
                    Expanded(
                      child: scannedValue == null
                          ? Container(
                              margin: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: MobileScanner(
                                controller: scannerController,
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  if (barcodes.isNotEmpty) {
                                    final code = barcodes.first.rawValue;
                                    if (code != null &&
                                        code.isNotEmpty &&
                                        scannedValue == null) {
                                      setDialogState(() {
                                        scannedValue = code;
                                      });
                                    }
                                  }
                                },
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: kPrimaryColor,
                                    size: isTablet ? 48 : 40,
                                  ),
                                  SizedBox(height: isTablet ? 16 : 12),
                                  Text(
                                    "Scanned Value:",
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 8 : 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 12,
                                      vertical: isTablet ? 12 : 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? colors.surface
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      scannedValue!,
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 20 : 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            scannedValue = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: kPrimaryColor,
                                          side: const BorderSide(
                                            color: kPrimaryColor,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 16,
                                            vertical: isTablet ? 12 : 10,
                                          ),
                                        ),
                                        child: Text(
                                          "Rescan",
                                          style: TextStyle(
                                            fontSize: isTablet ? 14 : 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 16 : 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          scannerController.dispose();
                                          Navigator.pop(ctx);
                                          setState(() {
                                            _surveyValue = scannedValue!;
                                            _surveyController.text =
                                                scannedValue!;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 24 : 20,
                                            vertical: isTablet ? 12 : 10,
                                          ),
                                        ),
                                        child: Text(
                                          "Save",
                                          style: TextStyle(
                                            fontSize: isTablet ? 14 : 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSurveyMenuItem(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          onExpandChanged(false);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.poll_outlined,
                              size: isTablet ? 22 : 18,
                              color: kPrimaryColor,
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Text(
                              _surveyLabel,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.blueGrey.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: isTablet ? 15 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showSurveyScannerDialog(context, colors, isDark),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 8 : 6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: isTablet ? 20 : 16,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isTablet ? 48 : 32,
                        child: isTablet
                            ? MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(textScaler: TextScaler.noScaling),
                                child: TextField(
                                  controller: _surveyController,
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Enter...",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? colors.surface
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 0,
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _surveyValue = value.trim();
                                    });
                                    onExpandChanged(false);
                                  },
                                ),
                              )
                            : TextField(
                                controller: _surveyController,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter...",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colors.surface
                                      : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  setState(() {
                                    _surveyValue = value.trim();
                                  });
                                  onExpandChanged(false);
                                },
                              ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _surveyValue = _surveyController.text.trim();
                        });
                        onExpandChanged(false);
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 10 : 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                    ),
                    if (_surveyValue.isNotEmpty) ...[
                      SizedBox(width: isTablet ? 8 : 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _surveyValue = '';
                            _surveyController.clear();
                          });
                          onExpandChanged(false);
                        },
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 10 : 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: isTablet ? 20 : 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: () {
                onExpandChanged(true);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: isTablet ? 22 : 18,
                    color: kPrimaryColor,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _surveyLabel,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 15 : 13,
                          ),
                        ),
                        if (_surveyValue.isNotEmpty) ...[
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            _surveyValue,
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 13 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCommentDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    _closeScanner();
    final controller = TextEditingController(text: _commentValue);
    final isTablet = context.isTablet;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: isTablet ? 520 : MediaQuery.of(context).size.width * 0.92,
                  padding: EdgeInsets.all(isTablet ? 24 : 18),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Comment",
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Icon(
                              Icons.close,
                              size: isTablet ? 24 : 22,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Content
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLines: 4,
                        maxLength: 225,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter comment...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark ? colors.surface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          counterStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_commentValue.isNotEmpty) ...[
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _commentValue = '';
                                });
                                Navigator.of(dialogContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Remove"),
                            ),
                            const SizedBox(width: 12),
                          ],
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white38 : Colors.black38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _commentValue = controller.text.trim();
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSalesCustomerDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    _closeScanner();
    _surveyController.text = _surveyValue;
    final isTablet = context.isTablet;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: isTablet ? 520 : MediaQuery.of(context).size.width * 0.92,
                  padding: EdgeInsets.all(isTablet ? 24 : 18),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _surveyLabel,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Icon(
                              Icons.close,
                              size: isTablet ? 24 : 22,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Content
                      TextField(
                        controller: _surveyController,
                        autofocus: true,
                        maxLines: 1,
                        maxLength: 20,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter value...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark ? colors.surface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          counterStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _surveyValue = value.trim();
                          });
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showSurveyScannerDialog(context, colors, isDark);
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text("Scan"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(color: kPrimaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_surveyValue.isNotEmpty) ...[
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _surveyValue = '';
                                  _surveyController.clear();
                                });
                                Navigator.of(dialogContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Remove"),
                            ),
                            const SizedBox(width: 12),
                          ],
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white38 : Colors.black38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _surveyValue = _surveyController.text.trim();
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns a list of cart items where sale qty exceeds stock qty
  /// Uses the ValidateOutOfStockItems use case from the BLoC
  List<CartItemVO> _getOutOfStockItems() {
    return _salesBloc.validateOutOfStockItems(cartItems: _cartItems);
  }

  void _checkAndShowCustomerComments(CustomerVO? customer) {
    if (!_displayCustomerMessagesAsPrompt) return;
    if (customer == null) return;
    if (customer.comments.isEmpty) return;

    final colors = context.appColors;
    CustomerCommentsDialog.show(
      context: context,
      customer: customer,
      colors: colors,
      isDark: colors.isDark,
    );
  }

  Future<void> _openCustomerTransactions() async {
    if (_selectedCustomer == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
    );

    final isOnline = await InternetConnectionUtils.instance
        .checkInternetConnection();
    if (!mounted) return;

    if (!isOnline) {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerTransactionsScreen(customer: _selectedCustomer!),
        ),
      );
      return;
    }

    try {
      await context.read<CustomerTransactionsBloc>().syncCustomerTransactions(
        _selectedCustomer!.customerId,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerTransactionsScreen(customer: _selectedCustomer!),
        ),
      );
    } catch (error) {
      debugPrint('Error fetching customer transactions: $error');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerTransactionsScreen(customer: _selectedCustomer!),
        ),
      );
    }
  }

  Future<void> _openCustomerCreate() async {
    final createdCustomer = await Navigator.of(context).push<CustomerVO>(
      MaterialPageRoute(
        builder: (_) => const CustomerCreateScreen(returnCreatedCustomer: true),
      ),
    );

    if (!mounted || createdCustomer == null) return;

    if (widget.title == "Account Sales" && !createdCustomer.account) {
      AlertInfo.show(
        context: context,
        text: "This customer is not an account customer",
        typeInfo: TypeInfo.error,
        backgroundColor: context.appColors.isDark
            ? context.appColors.surface
            : kSecondaryColor,
        iconColor: kErrorColor,
        textColor: kErrorColor,
        position: MessagePosition.top,
        padding: 70,
      );
      return;
    }

    _salesBloc.add(SelectCustomer(customer: createdCustomer));
    setState(() => _selectedCustomer = createdCustomer);
  }

  void _showSalesSettingsDialog(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return StandardDialog(
              title: 'Sales Settings',
              subtitle: 'Configure your sales preferences',
              colors: colors,
              isDark: isDark,
              maxWidth: isTablet ? 600 : double.infinity,
              onClose: () => Navigator.pop(dialogContext),
              content: Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tools Section
                        _buildSettingsGroupHeader(
                          'Tools',
                          Icons.build_outlined,
                          isDark,
                        ),
                        _buildSettingsGroupContainer(isDark, colors, [
                          _buildSettingsSwitch(
                            'Scan Individual Units',
                            _scanIndividualUnits,
                            (v) async {
                              setDialogState(() => _scanIndividualUnits = v);
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesScanIndividualUnitsKey,
                                value: v,
                              );

                              // When turning ON and prompt setting is enabled, show fractional prompt
                              if (v && _promptScanIndividualFractional) {
                                final result =
                                    await _showFractionalPromptDialog(
                                      colors,
                                      isDark,
                                    );
                                setDialogState(() {
                                  _scanIndividualUnitsForFractional =
                                      result == true;
                                });
                                setState(() {});
                                _salesBloc.saveSalesSetting(
                                  key:
                                      kSalesScanIndividualUnitsForFractionalKey,
                                  value: result == true,
                                );
                              }
                            },
                            isDark,
                            colors,
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Skip Fields Section
                        _buildSettingsGroupHeader(
                          'Skip Fields',
                          Icons.skip_next_outlined,
                          isDark,
                        ),
                        _buildSettingsGroupContainer(isDark, colors, [
                          _buildSettingsSwitch(
                            'Skip Sell Price',
                            _skipSellPrice,
                            (v) {
                              setDialogState(() => _skipSellPrice = v);
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesSkipSellPriceKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                          _buildSettingsSwitch(
                            'One display line per item',
                            _oneDisplayLinePerItem,
                            (v) {
                              setDialogState(
                                () => _oneDisplayLinePerItem = v,
                              );
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesOneDisplayLinePerItemKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Sales Window Section
                        _buildSettingsGroupHeader(
                          'Sales Window',
                          Icons.storefront_outlined,
                          isDark,
                        ),
                        _buildSettingsGroupContainer(isDark, colors, [
                          _buildSettingsSwitch(
                            'Prompt for Email at Time of Sale',
                            _promptForEmailAtSale,
                            (v) {
                              setDialogState(() => _promptForEmailAtSale = v);
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesPromptForEmailKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                          _buildSettingsSwitch(
                            'Scan Individual Units for Fractional Quantities',
                            _scanIndividualUnitsForFractional,
                            (v) {
                              setDialogState(
                                () => _scanIndividualUnitsForFractional = v,
                              );
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesScanIndividualUnitsForFractionalKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                          _buildSettingsSwitch(
                            'Prevent adding item to any sale transaction if there is no stock on hand',
                            _preventAddIfNoStock,
                            (v) {
                              setDialogState(() => _preventAddIfNoStock = v);
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesPreventAddIfNoStockKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                          _buildSettingsSwitch(
                            'Prevent finalising IV when any item is out of stock - SO, & LB Allowed',
                            _preventFinaliseIfOutOfStock,
                            (v) {
                              setDialogState(
                                () => _preventFinaliseIfOutOfStock = v,
                              );
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesPreventFinaliseIfOutOfStockKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Other Section
                        _buildSettingsGroupHeader(
                          'Other',
                          Icons.more_horiz,
                          isDark,
                        ),
                        _buildSettingsGroupContainer(isDark, colors, [
                          _buildSettingsSwitch(
                            'Auto Remind - Low Stock',
                            _autoRemindLowStock,
                            (v) {
                              setDialogState(() => _autoRemindLowStock = v);
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesAutoRemindLowStockKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Alerts Section
                        _buildSettingsGroupHeader(
                          'Alerts',
                          Icons.notifications_outlined,
                          isDark,
                        ),
                        _buildSettingsGroupContainer(isDark, colors, [
                          _buildSettingsSwitch(
                            'Prompt for Scan Individual Units for Fractional Quantities',
                            _promptScanIndividualFractional,
                            (v) {
                              setDialogState(
                                () => _promptScanIndividualFractional = v,
                              );
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesPromptScanIndividualFractionalKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                          _buildSettingsSwitch(
                            'Display customer messages as a Prompt during sale',
                            _displayCustomerMessagesAsPrompt,
                            (v) {
                              setDialogState(
                                () => _displayCustomerMessagesAsPrompt = v,
                              );
                              setState(() {});
                              _salesBloc.saveSalesSetting(
                                key: kSalesDisplayCustomerMessagesKey,
                                value: v,
                              );
                            },
                            isDark,
                            colors,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                DialogTextAction(
                  label: 'Done',
                  style: DialogActionStyle.primary,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsGroupHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroupContainer(
    bool isDark,
    AppThemeColors colors,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    AppThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
    bool isDark,
    AppThemeColors colors,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      activeColor: kPrimaryColor,
      checkColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _showTaxDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final isTablet = context.isTablet;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(isTablet ? 28 : 24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tax Breakdown",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Icon(
                          Icons.close,
                          size: isTablet ? 26 : 24,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildTaxBreakdown(colors, isDark),
                  SizedBox(height: isTablet ? 16 : 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfitDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final isTablet = context.isTablet;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(isTablet ? 28 : 24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profit Breakdown",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Icon(
                          Icons.close,
                          size: isTablet ? 26 : 24,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildProfitBreakdown(colors, isDark),
                  SizedBox(height: isTablet ? 16 : 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Parse discount input and calculate the actual discount value
  /// Supports: "$20" or "20" for fixed amount, "20%" or "%20" for percentage, "T200" or "t200" for target total
  /// Uses precise Rational arithmetic for calculations
  double _parseDiscountInput(String input, double subtotal) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 0.0;

    final subtotalR = _toRational(subtotal);

    // Target total format: T200 or t200
    if (trimmed.toUpperCase().startsWith('T')) {
      final targetTotal = double.tryParse(trimmed.substring(1));
      if (targetTotal != null && targetTotal >= 0 && targetTotal < subtotal) {
        // discount = subtotal - targetTotal (precise Rational)
        final targetR = _toRational(targetTotal);
        return _fromRational(subtotalR - targetR);
      }
      return 0.0;
    }

    // Percentage format: 20% or %20
    if (trimmed.contains('%')) {
      final numStr = trimmed.replaceAll('%', '').trim();
      final percent = double.tryParse(numStr);
      if (percent != null && percent >= 0 && percent <= 100) {
        // discount = subtotal * (percent / 100) (precise Rational)
        final percentR = _toRational(percent);
        final oneHundred = Rational.fromInt(100);
        return _fromRational(subtotalR * percentR / oneHundred);
      }
      return 0.0;
    }

    // Fixed dollar amount (with or without $)
    final numStr = trimmed.replaceAll('\$', '').trim();
    return double.tryParse(numStr) ?? 0.0;
  }

  void _showDiscountDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    _closeScanner();
    final isTablet = context.isTablet;
    final discountController = TextEditingController(
      text: _discountValue > 0 ? _discountValue.toStringAsFixed(2) : '',
    );
    double tempDiscount = _discountValue;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Calculate profit with temp discount for live preview (using GP ratio distribution)
            final tempTotals = _calcTotalsWithDiscount(tempDiscount);
            final double totalEx = double.parse(
              tempTotals.totalEx.toStringAsFixed(4),
            );
            final double egp = double.parse(
              tempTotals.totalGp.toStringAsFixed(4),
            );
            final double egpPercent = totalEx > 0 ? (egp / totalEx) * 100 : 0;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Center(
                child: SingleChildScrollView(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: isTablet
                          ? 600
                          : MediaQuery.of(context).size.width * 0.92,
                      padding: EdgeInsets.all(isTablet ? 28 : 20),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Discount",
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(dialogContext).pop(),
                                child: Icon(
                                  Icons.close,
                                  size: isTablet ? 26 : 24,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 20 : 16),

                          // Main content row: Discount input + Profit breakdown
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Discount input section
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Discount Amount",
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.blueGrey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 10 : 8),
                                    TextField(
                                      controller: discountController,
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: isTablet ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "0.00",
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.grey.shade400,
                                          fontSize: isTablet ? 24 : 20,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? colors.surface
                                            : Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 16 : 14,
                                          vertical: isTablet ? 16 : 14,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          tempDiscount = _parseDiscountInput(
                                            value,
                                            _subtotal,
                                          );
                                        });
                                      },
                                      onSubmitted: (value) {
                                        final discount = _parseDiscountInput(
                                          value,
                                          _subtotal,
                                        );
                                        setState(() {
                                          _discountValue = discount;
                                          _discountController.text = discount
                                              .toStringAsFixed(2);
                                        });
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    SizedBox(height: isTablet ? 12 : 10),
                                    // Current discount display
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Discount:",
                                            style: TextStyle(
                                              fontSize: isTablet ? 15 : 13,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.blueGrey.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              reverse: true,
                                              child: Text(
                                                FormattingUtils.formatCurrencyWithDecimals(
                                                  tempDiscount,
                                                  2,
                                                ),
                                                style: TextStyle(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: kPrimaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 6),
                                    // New total display
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? colors.surface
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "New Total:",
                                            style: TextStyle(
                                              fontSize: isTablet ? 15 : 13,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.blueGrey.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              reverse: true,
                                              child: Text(
                                                FormattingUtils.formatCurrencyWithDecimals(
                                                  _subtotal - tempDiscount,
                                                  2,
                                                ),
                                                style: TextStyle(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isTablet ? 24 : 16),
                              // Profit breakdown section
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: isTablet ? 32 : 24,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? colors.surface
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white12
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Profit Preview",
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.blueGrey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 18 : 14),
                                        _buildProfitRow(
                                          "Cost:",
                                          _totalCost,
                                          isDark,
                                          isTablet,
                                        ),
                                        SizedBox(height: isTablet ? 14 : 12),
                                        _buildProfitRow(
                                          "eGP:",
                                          egp,
                                          isDark,
                                          isTablet,
                                          highlight: true,
                                        ),
                                        SizedBox(height: isTablet ? 14 : 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "eGP%:",
                                              style: TextStyle(
                                                fontSize: isTablet ? 16 : 14,
                                                color: egp < 0
                                                    ? Colors.redAccent
                                                    : const Color(0xFF30B24C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                reverse: true,
                                                child: Text(
                                                  "${egpPercent.toStringAsFixed(2)}%",
                                                  style: TextStyle(
                                                    fontSize: isTablet
                                                        ? 16
                                                        : 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: egp < 0
                                                        ? Colors.redAccent
                                                        : const Color(
                                                            0xFF30B24C,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 24 : 20),

                          // Action buttons
                          Row(
                            children: [
                              if (_discountValue > 0) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _discountValue = 0.0;
                                        _discountController.text = "0.00";
                                      });
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 14 : 12,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Clear Discount",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 15 : 14,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                              ],
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final discount = _parseDiscountInput(
                                      discountController.text,
                                      _subtotal,
                                    );
                                    setState(() {
                                      _discountValue = discount;
                                      _discountController.text = discount
                                          .toStringAsFixed(2);
                                    });
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isTablet ? 14 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Apply Discount",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 15 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfitRow(
    String label,
    double amount,
    bool isDark,
    bool isTablet, {
    bool highlight = false,
  }) {
    final isNegative = amount < 0;
    final highlightColor = isNegative
        ? Colors.redAccent
        : const Color(0xFF30B24C);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: highlight
                ? highlightColor
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              FormattingUtils.formatCurrencyWithDecimals(amount, 4),
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: highlight
                    ? highlightColor
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showActionsMenu(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    bool surveyExpanded = false;
    _surveyController.text = _surveyValue;
    final isTablet = context.isTablet;
    final gridWidth = isTablet ? 440.0 : 360.0;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Actions Menu",
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInQuart,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              children: [
                Positioned(
                  left: 12,
                  bottom:
                      MediaQuery.of(context).size.height -
                      buttonPosition.dy +
                      8,
                  child: Material(
                    color: Colors.transparent,
                    child: AnimatedBuilder(
                      animation: curvedAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: curvedAnimation.value,
                            child: Opacity(
                              opacity: curvedAnimation.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: gridWidth,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1: Sales Customer | Add Discount
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    _surveyLabel,
                                    isSurvey: true,
                                    surveyExpanded: surveyExpanded,
                                    onSurveyExpandChanged: (expanded) {
                                      setDialogState(
                                        () => surveyExpanded = expanded,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                      AppGlobals.instance.hasPermission(
                                        "Miscellaneous_LockDiscount",
                                      )
                                      ? _buildGridActionTile(
                                          context,
                                          colors,
                                          isDark,
                                          "Discount",
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 2: Comment | Tax
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    "Comment",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    "Tax",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 3: Delivery | Profit
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    "Delivery",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                      !AppGlobals.instance.restrictedPermissions
                                          .contains(
                                            "Miscellaneous_HideCostPriceAndProfit",
                                          )
                                      ? _buildGridActionTile(
                                          context,
                                          colors,
                                          isDark,
                                          "Profit",
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 4: Save Session | Clear Session
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    "Save Session",
                                    tileColor: kPrimaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildGridActionTile(
                                    context,
                                    colors,
                                    isDark,
                                    "Clear Session",
                                    tileColor: kErrorColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _showActions = false;
          _actionsAnimationController.reverse();
        });
      }
    });
  }

  Widget _buildActionsButton(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    final size = isTablet ? 70.0 : 50.0;
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          setState(() {
            _showActions = !_showActions;
            if (_showActions) {
              _actionsAnimationController.forward();
              _showActionsMenu(context, colors, isDark);
            } else {
              _actionsAnimationController.reverse();
            }
          });
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            Icons.menu,
            color: kPrimaryColor,
            size: isTablet ? 34 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFinaliseButton(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    final isSales = widget.title == "Sales";
    final requiresCustomer = !isSales && _selectedCustomer == null;
    final isDisabled = _cartItems.isEmpty || requiresCustomer;

    return GestureDetector(
      onTap: isDisabled ? null : () => _showFinaliseDialog(),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 10 : 14,
            horizontal: isTablet ? 52 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: isTablet ? 22 : 16,
              ),
              const SizedBox(width: 8),
              Text(
                "FINALISE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 15 : 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action == _surveyLabel) {
      return Icons.poll_outlined;
    }
    switch (action) {
      case "Comment":
        return Icons.comment_outlined;
      case "Discount":
        return Icons.discount_outlined;
      case "Delivery":
        return Icons.local_shipping_outlined;
      case "Tax":
        return Icons.receipt_long_outlined;
      case "Profit":
        return Icons.trending_up_outlined;
      case "Save Session":
        return Icons.save_outlined;
      case "Clear Session":
        return Icons.delete_outline;
      case "Finalise":
        return Icons.check_circle_outline;
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildGridActionTile(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    String item, {
    Color? tileColor,
    bool isSurvey = false,
    bool surveyExpanded = false,
    Function(bool)? onSurveyExpandChanged,
  }) {
    final isTablet = context.isTablet;
    // When tileColor is set (Save/Clear Session), use white for icon and text
    final iconColor = tileColor != null ? Colors.white : kPrimaryColor;
    final textColor = tileColor != null
        ? Colors.white
        : (isDark ? Colors.white : Colors.blueGrey.shade800);

    if (isSurvey) {
      return _buildSurveyGridTile(
        context,
        colors,
        isDark,
        surveyExpanded,
        onSurveyExpandChanged!,
      );
    }

    return InkWell(
      onTap: () => _handleGridActionTap(context, colors, isDark, item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: tileColor ?? (isDark ? const Color(0xFF1E2733) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getActionIcon(item),
              size: isTablet ? 24 : 22,
              color: iconColor,
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item == "Discount" && _discountValue > 0)
                    Text(
                      FormattingUtils.formatCurrencyWithDecimals(
                        _discountValue,
                        2,
                      ),
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 13 : 11,
                      ),
                    ),
                ],
              ),
            ),
            if (item == "Comment" && _commentValue.isNotEmpty)
              Icon(
                Icons.check_circle,
                size: isTablet ? 18 : 16,
                color: kPrimaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyGridTile(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = context.isTablet;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _showActions = false;
          _actionsAnimationController.reverse();
        });
        Future.microtask(() {
          if (mounted) {
            _showSalesCustomerDialog(this.context, colors, isDark);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2733) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.poll_outlined,
              size: isTablet ? 24 : 22,
              color: kPrimaryColor,
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _surveyLabel,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.blueGrey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_surveyValue.isNotEmpty)
                    Text(
                      _surveyValue,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 13 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (_surveyValue.isNotEmpty)
              Icon(
                Icons.check_circle,
                size: isTablet ? 18 : 16,
                color: kPrimaryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _handleGridActionTap(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    String item,
  ) {
    Navigator.of(context).pop();
    setState(() {
      _showActions = false;
      _actionsAnimationController.reverse();
    });

    if (item == "Comment") {
      Future.microtask(() {
        if (mounted) {
          _showCommentDialog(this.context, colors, isDark);
        }
      });
    } else if (item == "Discount") {
      _showDiscountDialog(this.context, colors, isDark);
    } else if (item == "Delivery") {
      if (_selectedCustomer == null) {
        Future.microtask(() {
          if (mounted) {
            AlertInfo.show(
              context: this.context,
              text: "Please select a customer before adding delivery details",
              typeInfo: TypeInfo.warning,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: Colors.orange,
              textColor: Colors.orange,
              position: MessagePosition.top,
              padding: 70,
            );
          }
        });
        return;
      }
      Future.microtask(() async {
        if (mounted) {
          final result = await Navigator.of(this.context).push<DeliveryInfoVO>(
            MaterialPageRoute(
              builder: (ctx) => DeliveryDetailsScreen(
                initialCustomer: _selectedCustomer,
                existingDelivery: _deliveryInfo,
              ),
            ),
          );
          if (result != null && mounted) {
            setState(() {
              _deliveryInfo = result;
              // Convert to DeliveryAddressData for persistence
              _committedDeliveryAddress = DeliveryAddressData.fromDeliveryInfo(
                result,
                companyName: _selectedCustomer?.company,
              );
            });
            // Save to session immediately
            _saveCurrentSession();
          }
        }
      });
    } else if (item == "Tax") {
      _showTaxDialog(this.context, colors, isDark);
    } else if (item == "Profit") {
      _showProfitDialog(this.context, colors, isDark);
    } else if (item == "Save Session") {
      _saveAndShowConfirmation();
    } else if (item == "Clear Session") {
      _showClearSessionDialog(colors, isDark);
    }
  }

  Future<void> _saveAndShowConfirmation() async {
    // Session is auto-saved, this button just provides user assurance
    if (mounted) {
      AlertInfo.show(
        context: context,
        text: "Session saved",
        typeInfo: TypeInfo.success,
        backgroundColor: context.appColors.surface,
        iconColor: kPrimaryColor,
        textColor: kPrimaryColor,
        position: MessagePosition.top,
        padding: 70,
      );
    }
  }

  void _showClearSessionDialog(AppThemeColors colors, bool isDark) {
    if (_cartItems.isEmpty && _currentSessionId == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => StandardDialog(
        title: "Clear Session",
        colors: colors,
        isDark: isDark,
        onClose: () => Navigator.pop(ctx),
        content: Text(
          "Are you sure you want to clear this session? This will delete it permanently.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          DialogTextAction(
            label: "Cancel",
            style: DialogActionStyle.cancelOutline,
            onPressed: () => Navigator.pop(ctx),
          ),
          DialogTextAction(
            label: "Clear",
            style: DialogActionStyle.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              // Delete session from database
              if (_currentSessionId != null) {
                await _salesBloc.deleteSaleSession(
                  sessionId: _currentSessionId!,
                );
              }
              // Clear cart and reset all state
              _salesBloc.add(ClearCart());
              setState(() {
                _selectedCustomer = null;
                _deliveryInfo = null;
                _committedDeliveryAddress = null;
                _emailAuditData = null;
                _currentSessionId = null;
                _paymentAmounts.clear();
                _discountValue = 0.00;
                _discountController.text = "0.00";
                _searchController.clear();
                _surveyValue = '';
                _surveyController.clear();
                _commentValue = '';
                _lastSessionUpdatedAt = null;
              });
              if (mounted) {
                AlertInfo.show(
                  context: context,
                  text: "Session cleared",
                  typeInfo: TypeInfo.info,
                  backgroundColor: colors.surface,
                  iconColor: kPrimaryColor,
                  textColor: colors.onSurface,
                  position: MessagePosition.top,
                  padding: 70,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdown(AppThemeColors colors, bool isDark) {
    // Use calculated totals with discount distribution and Rational precision
    final totals = _calculatedTotals;

    // Display with 4dp precision (cascade rounding)
    return TaxBreakdownWidget(
      incTotal: double.parse(totals.totalInc.toStringAsFixed(4)),
      exTotal: double.parse(totals.totalEx.toStringAsFixed(4)),
      taxAmount: double.parse(totals.totalTax.toStringAsFixed(4)),
      colors: colors,
      isDark: isDark,
    );
  }

  Widget _buildProfitBreakdown(AppThemeColors colors, bool isDark) {
    // Use calculated totals with discount distribution and Rational precision
    final totals = _calculatedTotals;

    // Display with 4dp precision (cascade rounding)
    return ProfitBreakdownWidget(
      totalEx: double.parse(totals.totalEx.toStringAsFixed(4)),
      totalCost: double.parse(_totalCost.toStringAsFixed(4)),
      totalGp: double.parse(totals.totalGp.toStringAsFixed(4)),
      colors: colors,
      isDark: isDark,
    );
  }
}
