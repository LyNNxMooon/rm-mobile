// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

import 'package:alert_info/alert_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';

import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/dialog_size_utils.dart';
import 'package:rmmobile/utils/internet_connection_utils.dart';
import 'package:rmmobile/utils/log_utils.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/ios_done_bar.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../utils/tax_calculation_utils.dart';
import '../widgets/detailed_lower_glass.dart';
import '../widgets/price_calculator_dialog.dart';
import '../widgets/pricing_dialog.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
import 'package_components_screen.dart';
import 'stock_activity_screen.dart';

class StockDetailsScreen extends StatefulWidget {
  const StockDetailsScreen({super.key, required this.stock});

  final StockVO stock;

  @override
  State<StockDetailsScreen> createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> {
  double sell = 0.00;
  double cost = 0.00;
  double exSell = 0.00;
  double exCost = 0.00;
  double sellTaxPercentage = 0.0;
  double costTaxPercentage = 0.0;
  int sellTaxType = 0;
  int costTaxType = 0;
  bool _taxLoaded = false;
  String? _localSelectedImagePath;
  bool _shouldSyncOnExit = false;
  int _descriptionCharLimit = 40; // Default limit, changes to 100 for RM 14+

  late final LanguageToolController _descriptionController;
  late final TextEditingController _custom1Controller;
  late final TextEditingController _custom2Controller;
  List<FocusNode> _priceFocusNodes = [];

  @override
  void initState() {
    context.read<SettingsBloc>().add(LoadRmVersionEvent());
    
    _descriptionController = LanguageToolController();
    _descriptionController.text = widget.stock.description;
    _descriptionController.addListener(_enforceDescriptionLimit);

    _custom1Controller = TextEditingController(
      text: widget.stock.custom1 ?? "",
    );
    _custom1Controller.addListener(() => _enforceCharLimit(_custom1Controller, 50));
    
    _custom2Controller = TextEditingController(
      text: widget.stock.custom2 ?? "",
    );
    _custom2Controller.addListener(() => _enforceCharLimit(_custom2Controller, 50));
    // Old setup disabled:
    // final pic = widget.stock.pictureFileName;
    // if (pic != null && pic.isNotEmpty) {
    //   context.read<FullImageBloc>().add(
    //     RequestFullImageEvent(
    //       stockId: widget.stock.stockID,
    //       pictureFileName: pic,
    //     ),
    //   );
    // }

    // Initialize with base values, then calculate tax async
    sell = widget.stock.sell;
    cost = widget.stock.cost;
    exSell = widget.stock.sell;
    exCost = widget.stock.cost;
    _calculateTaxAsync();

    // Log order threshold and quantity for debugging
    logger.i('Stock Details - ${widget.stock.description}');
    logger.i('  orderThreshold: ${widget.stock.orderThreshold}');
    logger.i('  orderQuantity: ${widget.stock.orderQuantity}');
    logger.i('  quantity (in stock): ${widget.stock.quantity}');

    super.initState();
  }

  void _applyRmVersion(String? version) {
    if (version == null || version.isEmpty) return;
    final majorVersion = int.tryParse(version.split('.').first) ?? 0;
    if (majorVersion >= 14) {
      setState(() {
        _descriptionCharLimit = 100;
      });
    }
  }

  void _enforceDescriptionLimit() {
    if (_descriptionController.text.length > _descriptionCharLimit) {
      final truncated = _descriptionController.text.substring(0, _descriptionCharLimit);
      _descriptionController.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
  }

  void _enforceCharLimit(TextEditingController controller, int limit) {
    if (controller.text.length > limit) {
      final truncated = controller.text.substring(0, limit);
      controller.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
  }

  Future<void> _calculateTaxAsync() async {
    try {
      // Check if server provides pre-calculated values for all prices
      final hasSellPrices = widget.stock.sellEx != null && widget.stock.sellInc != null;
      final hasCostPrices = widget.stock.costEx != null && widget.stock.costInc != null;

      if (hasSellPrices && hasCostPrices) {
        // Use pre-calculated values from server (available for all items now)
        logger.i('=== Using Pre-calculated Prices from Server ===');
        logger.i('Stock ID: ${widget.stock.stockID}, Description: ${widget.stock.description}');
        logger.i('  Sell Ex: ${widget.stock.sellEx}, Sell Inc: ${widget.stock.sellInc}');
        logger.i('  Cost Ex: ${widget.stock.costEx}, Cost Inc: ${widget.stock.costInc}');

        // Still load tax percentage from the tax code table for edit calculations
        final sellResult = await TaxCalculationUtils.calculateSellTax(
          sell: widget.stock.sell,
          salesTax: widget.stock.salesTax,
        );
        final costResult = await TaxCalculationUtils.calculateCostTax(
          cost: widget.stock.cost,
          goodsTax: widget.stock.goodsTax,
        );

        if (mounted) {
          setState(() {
            sell = widget.stock.sellInc!;
            exSell = widget.stock.sellEx!;
            cost = widget.stock.costInc!;
            exCost = widget.stock.costEx!;
            sellTaxPercentage = sellResult.percentage;
            sellTaxType = sellResult.taxType;
            costTaxPercentage = costResult.percentage;
            costTaxType = costResult.taxType;
            _taxLoaded = true;
          });
        }
        return;
      }

      // Fallback: Calculate tax when server values are not available
      // Uses precise Rational arithmetic internally, rounds to 4 decimals at output
      logger.i('=== Fallback: Calculating Tax Locally ===');
      logger.i('Stock ID: ${widget.stock.stockID}, Description: ${widget.stock.description}');

      // Calculate sell price tax (uses sales_tax)
      final sellResult = await TaxCalculationUtils.calculateSellTax(
        sell: widget.stock.sell,
        salesTax: widget.stock.salesTax,
      );

      // Calculate cost tax (uses goods_tax)
      final costResult = await TaxCalculationUtils.calculateCostTax(
        cost: widget.stock.cost,
        goodsTax: widget.stock.goodsTax,
      );

      logger.i('--- Sell Tax (salesTax code: ${widget.stock.salesTax}) ---');
      logger.i('  Ex Price: ${sellResult.exPrice}, Inc Price: ${sellResult.incPrice}');
      logger.i('  Tax %: ${sellResult.percentage}, Tax Type: ${sellResult.taxType}');
      logger.i('--- Cost Tax (goodsTax code: ${widget.stock.goodsTax}) ---');
      logger.i('  Ex Price: ${costResult.exPrice}, Inc Price: ${costResult.incPrice}');
      logger.i('  Tax %: ${costResult.percentage}, Tax Type: ${costResult.taxType}');

      if (mounted) {
        setState(() {
          sell = sellResult.incPrice;
          exSell = sellResult.exPrice;
          sellTaxPercentage = sellResult.percentage;
          sellTaxType = sellResult.taxType;

          cost = costResult.incPrice;
          exCost = costResult.exPrice;
          costTaxPercentage = costResult.percentage;
          costTaxType = costResult.taxType;

          _taxLoaded = true;
        });
      }
    } catch (e) {
      logger.e('Error calculating tax: $e');
      // Fall back to no tax calculation
      if (mounted) {
        setState(() {
          _taxLoaded = true;
        });
      }
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _onCameraTap() async {
    final bool useDesktopNav = context.useDesktopNav;
    
    // On desktop, directly pick from gallery (no camera)
    if (useDesktopNav) {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (x != null) _previewAndUpload(x.path);
      return;
    }
    
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPadding),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? colors.surface : kSecondaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: kPrimaryColor,
                ),
                title: Text(
                  "Take Photo",
                  style: TextStyle(
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final x = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 95,
                  );
                  if (x != null) _previewAndUpload(x.path);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: kPrimaryColor,
                ),
                title: Text(
                  "Choose from Gallery",
                  style: TextStyle(
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final x = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (x != null) _previewAndUpload(x.path);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _previewAndUpload(String path) async {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final media = MediaQuery.of(context);
    final bool useDesktopNav = context.useDesktopNav;
    
    // Desktop-specific sizing
    final double previewHeight = useDesktopNav
        ? (media.size.height * 0.35).clamp(180.0, 280.0)
        : (media.size.height * 0.42).clamp(190.0, 340.0);
    final double dialogPadding = useDesktopNav ? 16.0 : 20.0;
    final double titleFontSize = useDesktopNav ? 14.0 : 18.0;
    final double buttonFontSize = useDesktopNav ? 12.0 : 14.0;
    final double buttonVerticalPadding = useDesktopNav ? 10.0 : 14.0;
    final double spacingAfterTitle = useDesktopNav ? 12.0 : 15.0;
    final double spacingAfterImage = useDesktopNav ? 16.0 : 25.0;
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(useDesktopNav ? 12 : 20)),
        backgroundColor: isDark ? colors.surface : kSecondaryColor,
        elevation: 10,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: useDesktopNav ? 360 : 500,
          ),
          child: Padding(
            padding: EdgeInsets.all(dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Confirm Upload",
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: spacingAfterTitle),

                Container(
                  height: previewHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(useDesktopNav ? 10 : 15),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.cardShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(useDesktopNav ? 9 : 14),
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return const Center(
                              child: CupertinoActivityIndicator(
                                radius: 14,
                                color: kPrimaryColor,
                              ),
                            );
                          },

                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: isDark ? colors.onSurfaceMuted : kGreyColor,
                            size: useDesktopNav ? 32 : 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: spacingAfterImage),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(useDesktopNav ? 8 : 12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          BlocBuilder<
                            StockImageUploadBloc,
                            StockImageUploadState
                          >(
                            builder: (context, state) {
                              final bool isUploading =
                                  state is StockImageUploading;
                              return ElevatedButton(
                                onPressed: isUploading
                                    ? null
                                    : () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  disabledBackgroundColor: kPrimaryColor
                                      .withOpacity(0.85),
                                  padding: EdgeInsets.symmetric(
                                    vertical: buttonVerticalPadding,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(useDesktopNav ? 8 : 12),
                                  ),
                                ),
                                child: isUploading
                                    ? CupertinoActivityIndicator(
                                        radius: useDesktopNav ? 9 : 11,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "Upload",
                                        style: TextStyle(
                                          fontSize: buttonFontSize,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _localSelectedImagePath = path;
    });

    if (mounted) {
      context.read<StockImageUploadBloc>().add(
        UploadStockImageEvent(
          stockId: widget.stock.stockID.toInt(),
          imagePath: path,
        ),
      );
    }
  }

  Future<void> _refreshImagesWithRetry() async {
    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return;

    final String imageUrl = (widget.stock.imageUrl ?? "").trim();
    if (imageUrl.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(imageUrl);
    }
    setState(() {});
  }

  Future<void> _triggerSyncIfNeeded() async {
    if (!_shouldSyncOnExit) return;

    final isOnline =
        await InternetConnectionUtils.instance.checkInternetConnection();

    if (!isOnline) {
      final stockState = context.read<StockListBloc>().state;
      if (stockState is StockListLoaded) {
        context.read<StockListBloc>().add(
          FetchFirstPageEvent(
            query: stockState.currentQuery,
            filterColumn: stockState.currentFilterCol,
            sortColumn: stockState.currentSortCol,
            filters: stockState.activeFilters,
            shouldToggleSort: false,
          ),
        );
      } else {
        context.read<StockListBloc>().add(
          FetchFirstPageEvent(shouldToggleSort: false),
        );
      }
      context.read<FilterOptionsBloc>().add(LoadFilterOptionsEvent());
      context.read<PendingStockUpdatesBloc>().add(
        LoadPendingStockUpdatesCountEvent(),
      );
      _shouldSyncOnExit = false;
      return;
    }

    context.read<FetchStockBloc>().add(
      StartSyncEvent(ipAddress: ""),
    );
    _shouldSyncOnExit = false;
  }

  String _formatLastSaleDate(String? rawValue) {
    final raw = (rawValue ?? "").trim();
    if (raw.isEmpty) return "-";

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat("dd MMM yyyy, hh:mm a").format(parsed.toLocal());
    }

    return raw;
  }

  String _formatTaxLabel(String? code, double percentage) {
    final trimmed = (code ?? '').trim();
    if (trimmed.isEmpty) return '-';

    if (percentage <= 0) {
      return trimmed;
    }

    final displayPct = percentage % 1 == 0
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(2);
    return '$trimmed ($displayPct%)';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _custom1Controller.dispose();
    _custom2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final bool isLandscape = context.isLandscape;
    final double screenHeight = media.size.height;
    final double screenWidth = media.size.width;

    // Desktop-specific sizing
    final double imageHeight = useDesktopNav 
        ? (screenHeight * 0.35).clamp(200.0, 350.0)
        : isTablet
            ? (isLandscape
                  ? (screenHeight * 0.44).clamp(320.0, 520.0)
                  : (screenHeight * 0.42).clamp(360.0, 620.0))
            : (screenHeight * 0.42).clamp(250.0, 400.0);

    final double cardHorizontalPadding = useDesktopNav
        ? (screenWidth * 0.03).clamp(20.0, 40.0)
        : isTablet
            ? (screenWidth * (isLandscape ? 0.045 : 0.04)).clamp(24.0, 56.0)
            : 20.0;
    final double sectionGap = useDesktopNav ? 18.0 : (isTablet ? (isLandscape ? 24.0 : 30.0) : 30.0);
    //final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    //final double bottomGap = (useDesktopNav ? 30.0 : (isTablet ? 40.0 : 100.0)) + bottomSafeArea;

    final bool hideCostPrice = AppGlobals.instance.restrictedPermissions
        .contains("Miscellaneous_HideCostPriceAndProfit");
    final bool lockSellPrice = AppGlobals.instance.restrictedPermissions
        .contains("Miscellaneous_LockSellPrice");
    // Package items cannot have their sell price updated (prices are calculated by server)
    final bool isPackage = widget.stock.isPackage == true;
    final String custom1Label = AppGlobals.instance.stockCustom1Label;
    final String custom2Label = AppGlobals.instance.stockCustom2Label;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color imageBackground = isDark ? colors.surface : kSecondaryColor;
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is RmVersionLoaded && state.version != null) {
              _applyRmVersion(state.version!);
            }
          },
        ),
        BlocListener<StockImageUploadBloc, StockImageUploadState>(
          listener: (context, state) {
            if (state is StockImageUploaded) {
              //context.navigateBack();
              _shouldSyncOnExit = true;
              final colors = context.appColors;
              final bool isDark = colors.isDark;
              AlertInfo.show(
                context: context,
                text: state.message,
                typeInfo: TypeInfo.success,
                backgroundColor: isDark ? colors.surface : kSecondaryColor,
                iconColor: kPrimaryColor,
                textColor: isDark ? colors.onSurface : kThirdColor,
                padding: 70,
                position: MessagePosition.top,
              );

              _refreshImagesWithRetry();
            }

            if (state is StockImageUploadError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
          },
        ),

        BlocListener<StockUpdateBloc, StockUpdateState>(
          listener: (context, state) {
            if (state is StockUpdateSuccess) {
              _shouldSyncOnExit = true;
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.success(message: state.message),
              );
              context.read<PendingStockUpdatesBloc>().add(
                LoadPendingStockUpdatesCountEvent(),
              );
            }

            if (state is StockUpdateError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
          },
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          await _triggerSyncIfNeeded();
          return true;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: SafeArea(
            bottom: false,
            top: false,
            child: useDesktopNav
                ? _buildDesktopLayout(
                    colors: colors,
                    isDark: isDark,
                    imageBackground: imageBackground,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    hideCostPrice: hideCostPrice,
                    lockSellPrice: lockSellPrice,
                    isPackage: isPackage,
                    custom1Label: custom1Label,
                    custom2Label: custom2Label,
                  )
                : (isTablet && isLandscape)
                ? _buildTabletLandscapeLayout(
                    colors: colors,
                    isDark: isDark,
                    imageBackground: imageBackground,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    imageHeight: imageHeight,
                    sectionGap: sectionGap,
                    hideCostPrice: hideCostPrice,
                    lockSellPrice: lockSellPrice,
                    isPackage: isPackage,
                    custom1Label: custom1Label,
                    custom2Label: custom2Label,
                  )
                : Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Hero(
                              tag: 'stock_image_${widget.stock.stockID}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: imageBackground,
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                            ),
                          ),
                          width: double.infinity,
                          height: imageHeight,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Builder(
                              builder: (context) {
                                final String? localImagePath =
                                    _localSelectedImagePath;
                                final String imageUrl =
                                    (widget.stock.imageUrl ?? "").trim();

                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (localImagePath != null &&
                                        localImagePath.isNotEmpty)
                                      Image.file(
                                        File(localImagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            Container(
                                              color: imageBackground,
                                            ),
                                      )
                                    else if (imageUrl.isNotEmpty)
                                      CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) =>
                                            Container(
                                              color: imageBackground,
                                            ),
                                      )
                                    else
                                      Container(
                                        color: imageBackground,
                                      ),

                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 9.0,
                                        sigmaY: 9.0,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.04),
                                      ),
                                    ),

                                    Center(
                                      child:
                                          (localImagePath != null &&
                                              localImagePath.isNotEmpty)
                                          ? Image.file(
                                              File(localImagePath),
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  Image.asset(
                                                    overviewPlaceholder,
                                                    fit: BoxFit.contain,
                                                  ),
                                            )
                                          : imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (_, _) => Image.asset(
                                                overviewPlaceholder,
                                                fit: BoxFit.contain,
                                              ),
                                              errorWidget: (_, _, _) =>
                                                  Image.asset(
                                                    overviewPlaceholder,
                                                    fit: BoxFit.contain,
                                                  ),
                                            )
                                          : Image.asset(
                                              overviewPlaceholder,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.55,
                              ),
                              child: Text(
                                widget.stock.description,
                                textAlign: TextAlign.right,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 22 : 24,
                                  fontWeight: FontWeight.w300,
                                  color: isDark ? Colors.white : kThirdColor,
                                ),
                              ),
                            ),
                             const SizedBox(width: 12),
                            Text(
                              _formatPrice(sell),
                              style: TextStyle(
                                fontSize: useDesktopNav ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : kThirdColor,
                              ),
                            ),
                           
                            
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 0.4),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stock.barcode,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: useDesktopNav ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color:kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 0.4),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildCountBox(
                              "Qty: ${_formatQty(widget.stock.quantity)}",
                             // const Color(0xFF34C759),
                              const Color(0xFF757575),
                              useDesktopNav,
                            ),
                            const SizedBox(width: 8),
                            _buildCountBox(
                              "LB: ${_formatQty(widget.stock.laybyQuantity)}",
                             // const Color(0xFF9C27B0),
                              const Color(0xFF757575),
                              useDesktopNav,
                            ),
                            const SizedBox(width: 8),
                            _buildCountBox(
                              "SO: ${_formatQty(widget.stock.salesOrderQuantity)}",
                             // kPrimaryColor,
                              const Color(0xFF757575),
                              useDesktopNav,
                            ),
                            const SizedBox(width: 8),
                            _buildCountBox(
                              "PO: ${_formatQty(widget.stock.purchaseOrderQuantity)}",
                              //const Color(0xFFF2911B),
                               const Color(0xFF757575),
                              useDesktopNav,
                            ),
                            const SizedBox(width: 8),
                            _buildCountBox(
                              "CSO: ${_formatQty(widget.stock.csoQuantity)}",
                              //const Color(0xFFA0522D),
                               const Color(0xFF757575),
                              useDesktopNav,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 1.6),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              isDark
                                  ? 'assets/images/options-black.png'
                                  : 'assets/images/options-light.png',
                              width: useDesktopNav ? 60 : 60,
                              height: useDesktopNav ? 60 : 60,
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    "LAST SALE",
                                    style: TextStyle(
                                      fontSize: useDesktopNav ? 11 : 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatLastSaleDate(
                                      widget.stock.lastSaleDate,
                                    ),
                                    style: TextStyle(
                                      fontSize: useDesktopNav ? 12 : 14,
                                      color: isDark ? Colors.white : kThirdColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.navigateToNext(
                                          StockActivityScreen(
                                            stockId:
                                                widget.stock.stockID.toInt(),
                                            stockDescription:
                                                widget.stock.description,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kPrimaryColor,
                                        side: const BorderSide(
                                          color: kPrimaryColor,
                                          width: 1.5,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: useDesktopNav ? 10 : 12,
                                          vertical: useDesktopNav ? 4 : 5,
                                        ),
                                        shape: const StadiumBorder(),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "STOCK ACTIVITY",
                                            style: TextStyle(
                                              fontSize: useDesktopNav ? 10 : 11,
                                                   fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                              
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: useDesktopNav ? 12 : 13,
                                            color: kPrimaryColor,
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

                      if ((widget.stock.longDescription ?? "").trim().isNotEmpty) ...[
                        SizedBox(height: sectionGap),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardHorizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "EXT DESCRIPTION",
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 11 : 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.stock.longDescription!.trim(),
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 13 : 14,
                                  color: isDark ? Colors.white : kThirdColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: sectionGap),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: _buildDottedSeparator(
                          isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),

                      SizedBox(height: sectionGap),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              isDark
                                  ? 'assets/images/dept-dark.png'
                                  : 'assets/images/dept-light.png',
                              width: useDesktopNav ? 60 : 60,
                              height: useDesktopNav ? 60 : 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Depts  &  Cats",
                              style: TextStyle(
                                fontSize: useDesktopNav ? 20 : 22,
                                  fontWeight: FontWeight.w300,
                                  color: isDark ? Colors.white : kThirdColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 0.6),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildOutlinedPill(
                              widget.stock.deptName ?? "-",
                              isDark ? Colors.white : kThirdColor,
                              useDesktopNav,
                            ),
                            Text(
                              "•",
                              style: TextStyle(
                                fontSize: useDesktopNav ? 16 : 18,
                                color: isDark ? Colors.white70 : kGreyColor,
                              ),
                            ),
                            _buildFilledPill(
                              widget.stock.category1 ?? "-",
                              const Color(0xFF94D82D),
                              useDesktopNav,
                            ),
                            _buildFilledPill(
                              widget.stock.category2 ?? "-",
                              const Color(0xFFFFCC00),
                             
                              useDesktopNav,
                            ),
                            _buildFilledPill(
                              widget.stock.category3 ?? "-",
                              const Color(0xFF34D0FF),
                              useDesktopNav,
                            ),
                          ],
                        ),
                      ),

                      if ((widget.stock.custom1 ?? "").trim().isNotEmpty ||
                          (widget.stock.custom2 ?? "").trim().isNotEmpty) ...[
                      SizedBox(height: sectionGap * 1.8),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              isDark
                                  ? 'assets/images/custom-dark.png'
                                  : 'assets/images/custom-light.png',
                              width: useDesktopNav ? 60 : 60,
                              height: useDesktopNav ? 60 : 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "${custom1Label.trim().isNotEmpty ? custom1Label.trim() : "Custom 1"}  &  ${custom2Label.trim().isNotEmpty ? custom2Label.trim() : "Custom 2"}",
                              style: TextStyle(
                                fontSize: useDesktopNav ? 20 : 22,
                                fontWeight: FontWeight.w300,
                                color: isDark ? Colors.white : kThirdColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 0.6),

                      Padding(
                        padding: EdgeInsets.only(
                          left: cardHorizontalPadding + 76,
                          right: cardHorizontalPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                (widget.stock.custom1 ?? "").trim().isNotEmpty
                                    ? widget.stock.custom1!.trim()
                                    : "N / A ",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 14 : 15,
                                  color: isDark ? Colors.white : kThirdColor,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "•",
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 16 : 18,
                                  color: isDark ? Colors.white70 : kGreyColor,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                (widget.stock.custom2 ?? "").trim().isNotEmpty
                                    ? widget.stock.custom2!.trim()
                                    : "N / A",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: useDesktopNav ? 14 : 14.5,
                                  color: isDark ? Colors.white : kThirdColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],

                     
                      SizedBox(height: sectionGap),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: _buildDottedSeparator(
                          isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),

                      SizedBox(height: sectionGap * 1.6),

                      // Tax & Prices title - centered
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        
                            Text(
                              "Tax & Prices",
                              style: TextStyle(
                                fontSize: useDesktopNav ? 20 : 22,
                                fontWeight: FontWeight.w300,
                                color: isDark ? Colors.white : kThirdColor,
                              ),
                            ),
                                const SizedBox(width: 10),
                            Image.asset(
                              isDark
                                  ? 'assets/images/tax-dark.png'
                                  : 'assets/images/tax-light.png',
                              width: useDesktopNav ? 32 : 36,
                              height: useDesktopNav ? 32 : 36,
                              fit: BoxFit.contain,
                            ),
                            
                          ],
                        ),
                      ),

                      SizedBox(height: sectionGap * 0.8),

                      // Embedded grey table container
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            //borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      Colors.white.withOpacity(0.04),
                                      Colors.white.withOpacity(0.08),
                                    ]
                                  : [
                                      const Color(0xFFF5F5F5),
                                      const Color(0xFFFBFBFB),
                                    ],
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final Color dividerColor = isDark
                                  ? Colors.white24
                                  : Colors.black26;
                              final Color textColor = isDark
                                  ? Colors.white
                                  : kThirdColor;
                              final Color labelColor = isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.shade500;
                              final double rowFontSize =
                                  useDesktopNav ? 12 : 13;
                              final double labelFontSize =
                                  useDesktopNav ? 11 : 12;
                              final String exCostStr = hideCostPrice
                                  ? "-"
                                  : _formatPrice(exCost);
                              final String incCostStr = hideCostPrice
                                  ? "-"
                                  : _formatPrice(cost);
                              return Column(
                                children: [
                                  _buildTaxPriceRow(
                                    label: "",
                                    costValue: "C O S T",
                                    salesValue: "S A L E S",
                                    dividerColor: dividerColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    fontSize: rowFontSize,
                                    labelFontSize: labelFontSize,
                                    isHeader: true,
                                  ),
                                  _buildTaxPriceRow(
                                    label: "T A X   C O D E",
                                    costValue: _formatTaxLabel(
                                      widget.stock.goodsTax,
                                      costTaxPercentage,
                                    ),
                                    salesValue: _formatTaxLabel(
                                      widget.stock.salesTax,
                                      sellTaxPercentage,
                                    ),
                                    dividerColor: dividerColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    fontSize: rowFontSize,
                                    labelFontSize: labelFontSize,
                                  ),
                                  _buildTaxPriceRow(
                                    label: "E X   T A X",
                                    costValue: exCostStr,
                                    salesValue:
                                        _formatPrice(exSell),
                                    dividerColor: dividerColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    fontSize: rowFontSize,
                                    labelFontSize: labelFontSize,
                                  ),
                                  _buildTaxPriceRow(
                                    label: "I N C   T A X",
                                    costValue: incCostStr,
                                    salesValue:
                                        _formatPrice(sell),
                                    dividerColor: dividerColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    fontSize: rowFontSize,
                                    labelFontSize: labelFontSize,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap * 1.6),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardHorizontalPadding,
                        ),
                        child: DetailedLowerGlass(
                          descController: _descriptionController,
                          custom1Controller: _custom1Controller,
                          custom2Controller: _custom2Controller,
                          stockId: widget.stock.stockID,
                          sell: sell,
                          exSell: exSell,
                          incCost: cost,
                          exCost: exCost,
                          costTaxLabel: _formatTaxLabel(
                            widget.stock.goodsTax,
                            costTaxPercentage,
                          ),
                          sellTaxLabel: _formatTaxLabel(
                            widget.stock.salesTax,
                            sellTaxPercentage,
                          ),
                          showCostPrices: !hideCostPrice,
                          taxPercentage: sellTaxPercentage,
                          taxType: sellTaxType,
                          canUpdateSellPrice: !lockSellPrice && !isPackage,
                          pricingRules: widget.stock.pricingRules,
                          isPackage: isPackage,
                          packageComponents: widget.stock.packageComponents,
                          packageDescription: widget.stock.description,
                          pricingGradesStock: widget.stock.pricingGradesStock,
                          pricingGradesCategories: widget.stock.pricingGradesCategories,
                          pricingGradesGlobal: widget.stock.pricingGradesGlobal,
                          onFocusNodesReady: (nodes) {
                            setState(() {
                              _priceFocusNodes = nodes;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: sectionGap),
                      if (isTablet)
                        SizedBox(
                          height: 20 + MediaQuery.of(context).padding.bottom,
                        ),
                        ],
                      ),
                      topIconsRow(),
                    ],
                  ),
                ),
              ),
              IosDoneBarMulti(
                focusNodes: _priceFocusNodes,
                onDone: () {
                  for (final node in _priceFocusNodes) {
                    if (node.hasFocus) {
                      node.unfocus();
                      break;
                    }
                  }
                },
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tablet landscape layout: full-width image on top, then a two-column
  /// split (faint vertical dotted divider). Left half = all details, right
  /// half = Tax & Prices + stacked action buttons at the bottom.
  Widget _buildTabletLandscapeLayout({
    required AppThemeColors colors,
    required bool isDark,
    required Color imageBackground,
    required double screenWidth,
    required double screenHeight,
    required double imageHeight,
    required double sectionGap,
    required bool hideCostPrice,
    required bool lockSellPrice,
    required bool isPackage,
    required String custom1Label,
    required String custom2Label,
  }) {
    const double colPad = 18.0;
    final Color faintDivider = isDark ? Colors.white24 : Colors.black26;

    // ----- LEFT HALF: details -----
    final Widget leftHalf = Padding(
      padding: const EdgeInsets.symmetric(horizontal: colPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description (RRP removed)
          Text(
            widget.stock.description,
            softWrap: true,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : kThirdColor,
            ),
          ),

          SizedBox(height: sectionGap * 0.4),

          // Barcode
          Text(
            widget.stock.barcode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kPrimaryColor,
            ),
          ),

          SizedBox(height: sectionGap * 0.4),

          // Count boxes
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildCountBox(
                "Qty: ${_formatQty(widget.stock.quantity)}",
                const Color(0xFF757575),
                false,
              ),
              _buildCountBox(
                "LB: ${_formatQty(widget.stock.laybyQuantity)}",
                const Color(0xFF757575),
                false,
              ),
              _buildCountBox(
                "SO: ${_formatQty(widget.stock.salesOrderQuantity)}",
                const Color(0xFF757575),
                false,
              ),
              _buildCountBox(
                "PO: ${_formatQty(widget.stock.purchaseOrderQuantity)}",
                const Color(0xFF757575),
                false,
              ),
              _buildCountBox(
                "CSO: ${_formatQty(widget.stock.csoQuantity)}",
                const Color(0xFF757575),
                false,
              ),
            ],
          ),

          SizedBox(height: sectionGap * 1.6),

          // Last sale + Stock Activity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                isDark
                    ? 'assets/images/options-black.png'
                    : 'assets/images/options-light.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "LAST SALE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatLastSaleDate(widget.stock.lastSaleDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : kThirdColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () {
                          context.navigateToNext(
                            StockActivityScreen(
                              stockId: widget.stock.stockID.toInt(),
                              stockDescription: widget.stock.description,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          side: const BorderSide(
                            color: kPrimaryColor,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          shape: const StadiumBorder(),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "STOCK ACTIVITY",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: kPrimaryColor,
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

          if ((widget.stock.longDescription ?? "").trim().isNotEmpty) ...[
            SizedBox(height: sectionGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EXT DESCRIPTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.stock.longDescription!.trim(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : kThirdColor,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: sectionGap),
          SizedBox(
            height: 1.5,
            width: double.infinity,
            child: CustomPaint(
              painter: _HorizontalDottedLinePainter(
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
          ),
          SizedBox(height: sectionGap),

          // Depts & Cats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                isDark
                    ? 'assets/images/dept-dark.png'
                    : 'assets/images/dept-light.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Text(
                "Depts  &  Cats",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: isDark ? Colors.white : kThirdColor,
                ),
              ),
            ],
          ),
          SizedBox(height: sectionGap * 0.6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildOutlinedPill(
                widget.stock.deptName ?? "-",
                isDark ? Colors.white : kThirdColor,
                false,
              ),
              Text(
                "•",
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : kGreyColor,
                ),
              ),
              _buildFilledPill(
                widget.stock.category1 ?? "-",
                const Color(0xFF94D82D),
                false,
              ),
              _buildFilledPill(
                widget.stock.category2 ?? "-",
                const Color(0xFFFFCC00),
                false,
              ),
              _buildFilledPill(
                widget.stock.category3 ?? "-",
                const Color(0xFF34D0FF),
                false,
              ),
            ],
          ),
        ],
      ),
    );

    // ----- Custom session (shown in the right half, below Tax & Prices) -----
    final Widget customSection =
        ((widget.stock.custom1 ?? "").trim().isNotEmpty ||
                (widget.stock.custom2 ?? "").trim().isNotEmpty)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        isDark
                            ? 'assets/images/custom-dark.png'
                            : 'assets/images/custom-light.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "${custom1Label.trim().isNotEmpty ? custom1Label.trim() : "Custom 1"}  &  ${custom2Label.trim().isNotEmpty ? custom2Label.trim() : "Custom 2"}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            color: isDark ? Colors.white : kThirdColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap * 0.6),
                  Padding(
                    padding: const EdgeInsets.only(left: 76),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            (widget.stock.custom1 ?? "").trim().isNotEmpty
                                ? widget.stock.custom1!.trim()
                                : "N / A ",
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : kThirdColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "•",
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white70 : kGreyColor,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            (widget.stock.custom2 ?? "").trim().isNotEmpty
                                ? widget.stock.custom2!.trim()
                                : "N / A",
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Colors.white : kThirdColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink();

    // ----- RIGHT HALF: Tax & Prices + stacked buttons -----
    final Color dividerColor = isDark ? Colors.white24 : Colors.black26;
    final Color textColor = isDark ? Colors.white : kThirdColor;
    final Color labelColor =
        isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade500;
    const double rowFontSize = 13;
    const double labelFontSize = 12;
    final String exCostStr = hideCostPrice ? "-" : _formatPrice(exCost);
    final String incCostStr = hideCostPrice ? "-" : _formatPrice(cost);

    final bool showViewComponents =
        isPackage && (widget.stock.packageComponents?.isNotEmpty ?? false);
    final bool showCalculator = !isPackage && !lockSellPrice;

    Widget actionButton({
      required String label,
      required bool filled,
      required VoidCallback onTap,
    }) {
      return SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: filled ? kPrimaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: kPrimaryColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: filled ? Colors.white : kPrimaryColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget rightHalf = Padding(
      padding: const EdgeInsets.symmetric(horizontal: colPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tax & Prices title - centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tax & Prices",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: isDark ? Colors.white : kThirdColor,
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                isDark
                    ? 'assets/images/tax-dark.png'
                    : 'assets/images/tax-light.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ],
          ),

          SizedBox(height: sectionGap * 0.8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.04),
                        Colors.white.withOpacity(0.08),
                      ]
                    : [
                        const Color(0xFFF5F5F5),
                        const Color(0xFFFBFBFB),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildTaxPriceRow(
                  label: "",
                  costValue: "C O S T",
                  salesValue: "S A L E S",
                  dividerColor: dividerColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontSize: rowFontSize,
                  labelFontSize: labelFontSize,
                  isHeader: true,
                ),
                _buildTaxPriceRow(
                  label: "T A X   C O D E",
                  costValue: _formatTaxLabel(
                    widget.stock.goodsTax,
                    costTaxPercentage,
                  ),
                  salesValue: _formatTaxLabel(
                    widget.stock.salesTax,
                    sellTaxPercentage,
                  ),
                  dividerColor: dividerColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontSize: rowFontSize,
                  labelFontSize: labelFontSize,
                ),
                _buildTaxPriceRow(
                  label: "E X   T A X",
                  costValue: exCostStr,
                  salesValue: _formatPrice(exSell),
                  dividerColor: dividerColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontSize: rowFontSize,
                  labelFontSize: labelFontSize,
                ),
                _buildTaxPriceRow(
                  label: "I N C   T A X",
                  costValue: incCostStr,
                  salesValue: _formatPrice(sell),
                  dividerColor: dividerColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  fontSize: rowFontSize,
                  labelFontSize: labelFontSize,
                ),
              ],
            ),
          ),

          // Custom session below Tax & Prices, then the buttons with a gap
          SizedBox(height: sectionGap * 1.6),
          customSection,
          SizedBox(height: sectionGap * 1.6),

          if (showViewComponents)
            actionButton(
              label: 'COMPONENTS',
              filled: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PackageComponentsScreen(
                      packageDescription: widget.stock.description,
                      components: widget.stock.packageComponents ?? [],
                    ),
                  ),
                );
              },
            )
          else if (showCalculator)
            actionButton(
              label: 'CALCULATOR',
              filled: false,
              onTap: _openCalculatorDialog,
            ),
          const SizedBox(height: 10),
          actionButton(
            label: 'PRICING',
            filled: true,
            onTap: _openPricingDialog,
          ),
        ],
      ),
    );

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            // Full-width image
            Hero(
              tag: 'stock_image_${widget.stock.stockID}',
              child: Container(
                width: double.infinity,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: imageBackground,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (context) {
                          final String imageUrl =
                              (widget.stock.imageUrl ?? "").trim();
                          final String? localImagePath =
                              _localSelectedImagePath;
                          if (localImagePath != null &&
                              localImagePath.isNotEmpty) {
                            return Image.file(
                              File(localImagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: imageBackground),
                            );
                          } else if (imageUrl.isNotEmpty) {
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  Container(color: imageBackground),
                            );
                          }
                          return Container(color: imageBackground);
                        },
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 9.0, sigmaY: 9.0),
                        child: Container(
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ),
                      Center(child: _buildStockImage(imageBackground)),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: sectionGap * 2.4),

            // Two-column split (60% / 40%)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: leftHalf),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 1.5,
                    child: CustomPaint(
                      painter: _VerticalDottedLinePainter(color: faintDivider),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: rightHalf),
                ],
              ),
            ),

            SizedBox(height: sectionGap * 2.5 + MediaQuery.of(context).padding.bottom),
          ],
        ),
        topIconsRow(),
      ],
    );
  }

  /// Desktop layout: Image on left, Details on right (centered)
  Widget _buildDesktopLayout({
    required AppThemeColors colors,
    required bool isDark,
    required Color imageBackground,
    required double screenWidth,
    required double screenHeight,
    required bool hideCostPrice,
    required bool lockSellPrice,
    required bool isPackage,
    required String custom1Label,
    required String custom2Label,
  }) {
    final double rightPanelWidth = screenWidth * 0.50;
    final double leftPanelWidth = screenWidth - rightPanelWidth;
    final double imageSize = (leftPanelWidth * 0.90).clamp(250.0, 420.0);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDE: Image and action buttons
          SizedBox(
            width: leftPanelWidth,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wrap icons, image, and buttons together
                  SizedBox(
                    width: imageSize,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Gallery + Close buttons (aligned with image left edge)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildCircularIcon(
                              icon: Icons.photo_library_rounded,
                              onTap: _onCameraTap,
                            ),
                            const SizedBox(width: 10),
                            _buildCircularIcon(
                              icon: Icons.close_rounded,
                              onTap: () {
                                _triggerSyncIfNeeded();
                                context.navigateBack();
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Stock image
                        Hero(
                          tag: 'stock_image_${widget.stock.stockID}',
                          child: Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: imageBackground,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? colors.onSurface.withOpacity(0.1) : kThirdColor.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildStockImage(imageBackground),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stacked action buttons
                        _buildDesktopActionButtons(
                          colors: colors,
                          isDark: isDark,
                          isPackage: isPackage,
                          lockSellPrice: lockSellPrice,
                          maxWidth: imageSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // RIGHT SIDE: Centered Details panels
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: rightPanelWidth - 40),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 20,
                          top: 20,
                          bottom: 30,
                        ),
                        children: [
                          // Lower Glass - Pricing controls (no buttons on desktop)
                          DetailedLowerGlass(
                            descController: _descriptionController,
                            custom1Controller: _custom1Controller,
                            custom2Controller: _custom2Controller,
                            stockId: widget.stock.stockID,
                            sell: sell,
                            exSell: exSell,
                            incCost: cost,
                            exCost: exCost,
                            costTaxLabel: _formatTaxLabel(widget.stock.goodsTax, costTaxPercentage),
                            sellTaxLabel: _formatTaxLabel(widget.stock.salesTax, sellTaxPercentage),
                            showCostPrices: !hideCostPrice,
                            taxPercentage: sellTaxPercentage,
                            taxType: sellTaxType,
                            canUpdateSellPrice: !lockSellPrice && !isPackage,
                            pricingRules: widget.stock.pricingRules,
                            isPackage: isPackage,
                            packageComponents: widget.stock.packageComponents,
                            packageDescription: widget.stock.description,
                            pricingGradesStock: widget.stock.pricingGradesStock,
                            pricingGradesCategories: widget.stock.pricingGradesCategories,
                            pricingGradesGlobal: widget.stock.pricingGradesGlobal,
                            hideButtons: true,
                            onFocusNodesReady: (nodes) {
                              setState(() {
                                _priceFocusNodes = nodes;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IosDoneBarMulti(
                  focusNodes: _priceFocusNodes,
                  onDone: () {
                    for (final node in _priceFocusNodes) {
                      if (node.hasFocus) {
                        node.unfocus();
                        break;
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the stacked action buttons for desktop layout (Calculator/Components, Pricing, Update)
  Widget _buildDesktopActionButtons({
    required AppThemeColors colors,
    required bool isDark,
    required bool isPackage,
    required bool lockSellPrice,
    required double maxWidth,
  }) {
    final bool showViewComponents = isPackage && (widget.stock.packageComponents?.isNotEmpty ?? false);
    final bool showCalculator = !isPackage && !lockSellPrice;
    final double buttonPadding = 10.0;
    
    Widget buildButton({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
    }) {
      return SizedBox(
        width: maxWidth,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : kSecondaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: kPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (showViewComponents)
          buildButton(
            icon: Icons.inventory_2_outlined,
            label: 'COMPONENTS',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PackageComponentsScreen(
                    packageDescription: widget.stock.description,
                    components: widget.stock.packageComponents ?? [],
                  ),
                ),
              );
            },
          )
        else if (showCalculator)
          buildButton(
            icon: Icons.calculate,
            label: 'CALCULATOR',
            onTap: _openCalculatorDialog,
          ),
        if (showViewComponents || showCalculator) const SizedBox(height: 8),
        buildButton(
          icon: Icons.price_change_outlined,
          label: 'PRICING',
          onTap: _openPricingDialog,
        ),
        const SizedBox(height: 8),
        buildButton(
          icon: Icons.arrow_circle_up,
          label: 'UPDATE',
          onTap: _submitStockUpdate,
        ),
      ],
    );
  }

  /// Opens the calculator dialog
  void _openCalculatorDialog() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 120));

    final double? result = await showDialog<double>(
      context: context,
      builder: (context) => PriceCalculatorDialog(
        incCost: cost,
        exCost: exCost,
        currentSell: sell,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        sell = result;
        // Calculate ex sell based on tax
        if (sellTaxPercentage > 0) {
          exSell = TaxCalculationUtils.calculateExclusivePrice(result, sellTaxPercentage);
        } else {
          exSell = result;
        }
      });
    }
  }

  /// Opens the pricing dialog
  void _openPricingDialog() {
    final rules = widget.stock.pricingRules ?? PricingRules.empty();
    showDialog<void>(
      context: context,
      builder: (_) => PricingDialog(
        pricingRules: rules,
        sell: sell,
        cost: cost,
        pricingGradesStock: widget.stock.pricingGradesStock,
        pricingGradesCategories: widget.stock.pricingGradesCategories,
        pricingGradesGlobal: widget.stock.pricingGradesGlobal,
        onUpdate: (updatedRules) {
          _submitPricingUpdate(updatedRules);
          Navigator.pop(context);
        },
        onDelete: () {
          _submitPricingUpdate(PricingRules.empty());
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Submits pricing rules update
  void _submitPricingUpdate(PricingRules rules) {
    context.read<StockUpdateBloc>().add(
      SubmitStockUpdateEvent(
        stockId: widget.stock.stockID.toInt(),
        description: _descriptionController.text,
        sell: sell,
        custom1: _custom1Controller.text.trim().isNotEmpty ? _custom1Controller.text.trim() : null,
        custom2: _custom2Controller.text.trim().isNotEmpty ? _custom2Controller.text.trim() : null,
        pricingRules: rules,
      ),
    );
  }

  /// Submits stock update
  void _submitStockUpdate() {
    context.read<StockUpdateBloc>().add(
      SubmitStockUpdateEvent(
        stockId: widget.stock.stockID.toInt(),
        description: _descriptionController.text,
        sell: sell,
        custom1: _custom1Controller.text.trim().isNotEmpty ? _custom1Controller.text.trim() : null,
        custom2: _custom2Controller.text.trim().isNotEmpty ? _custom2Controller.text.trim() : null,
      ),
    );
  }

  String _formatQty(num value) {
    return (value % 1 == 0)
        ? value.toInt().toString()
        : double.parse(value.toStringAsFixed(2)).toString();
  }

  /// UI-only helper: formats a price for display rounded to 2 decimals.
  /// Does not affect any stored values or calculations.
  String _formatPrice(num value) {
    return "\$${value.toStringAsFixed(2)}";
  }

  Widget _buildCountBox(String text, Color color, bool useDesktopNav) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useDesktopNav ? 3 : 5,
        vertical: useDesktopNav ? 0 : 0,
      ),
      decoration: BoxDecoration(
        //borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: useDesktopNav ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDottedSeparator(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dashWidth = 4;
        const double dashGap = 4;
        final int dashCount =
            (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlinedPill(String text, Color color, bool useDesktopNav) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useDesktopNav ? 10 : 12,
        vertical: useDesktopNav ? 4 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
           fontSize: useDesktopNav ? 12 : 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFilledPill(String text, Color color, bool useDesktopNav) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useDesktopNav ? 10 : 12,
        vertical: useDesktopNav ? 4 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
      ),
      child: Text(
        text,
        style: TextStyle(
             fontSize: useDesktopNav ? 12 : 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Builds a single row of the Tax & Prices table (label | cost | sales)
  Widget _buildTaxPriceRow({
    required String label,
    required String costValue,
    required String salesValue,
    required Color dividerColor,
    required Color textColor,
    required Color labelColor,
    required double fontSize,
    required double labelFontSize,
    bool isHeader = false,
  }) {
    final TextStyle labelStyle = TextStyle(
      fontSize: labelFontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: labelColor,
    );
    final TextStyle valueStyle = isHeader
        ? labelStyle
        : TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: textColor,
          );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: labelStyle,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Center(
                child: Text(
                  costValue,
                  textAlign: TextAlign.center,
                  style: valueStyle,
                ),
              ),
            ),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Center(
                child: Text(
                  salesValue,
                  textAlign: TextAlign.center,
                  style: valueStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the stock image widget (shared between layouts)
  Widget _buildStockImage(Color imageBackground) {
    final String? localImagePath = _localSelectedImagePath;
    final String imageUrl = (widget.stock.imageUrl ?? "").trim();
    if (localImagePath != null && localImagePath.isNotEmpty) {
      return Image.file(
        File(localImagePath),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(
          overviewPlaceholder,
          fit: BoxFit.contain,
        ),
      );
    } else if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) => Image.asset(
          overviewPlaceholder,
          fit: BoxFit.contain,
        ),
        errorWidget: (_, _, _) => Image.asset(
          overviewPlaceholder,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return Image.asset(
        overviewPlaceholder,
        fit: BoxFit.contain,
      );
    }
  }

  Widget topIconsRow() {
    final bool useDesktopNav = context.useDesktopNav;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: useDesktopNav ? 15 : 20, 
            vertical: useDesktopNav ? 8 : 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircularIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  _triggerSyncIfNeeded();
                  context.navigateBack();
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircularIcon(
                    // On desktop show gallery icon, on mobile show camera
                    icon: useDesktopNav ? Icons.photo_library_rounded : Icons.camera_alt_rounded,
                    onTap: _onCameraTap,
                  ),
                  SizedBox(width: useDesktopNav ? 10 : 12),
                  _buildCircularIcon(
                    icon: Icons.edit_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final double iconBoxSize = useDesktopNav ? 38 : 44;
    final double iconSize = useDesktopNav ? 19 : 22;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        width: iconBoxSize,
        height: iconBoxSize,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : kSecondaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: useDesktopNav ? 6 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? colors.onSurface : kThirdColor,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Paints a vertical dotted line. Used as the faint divider between the two
/// halves of the tablet landscape layout (works inside IntrinsicHeight).
class _VerticalDottedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 4;
    const double dashGap = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final double x = size.width / 2;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Paints a horizontal dotted line. Safe to use inside IntrinsicHeight (unlike
/// the LayoutBuilder-based separator).
class _HorizontalDottedLinePainter extends CustomPainter {
  final Color color;

  _HorizontalDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 4;
    const double dashGap = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final double y = size.height / 2;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalDottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
