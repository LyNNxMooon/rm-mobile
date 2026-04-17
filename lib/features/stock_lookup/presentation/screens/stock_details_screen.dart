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
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
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
import '../widgets/detailed_upper_glass.dart';

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
                    color: isDark ? colors.onSurface : null,
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
                    color: isDark ? colors.onSurface : null,
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
    final double previewHeight = (media.size.height * 0.42).clamp(190.0, 340.0);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Confirm Upload",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 15),

              Container(
                height: previewHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? colors.cardShadow
                          : kThirdColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isUploading
                                  ? const CupertinoActivityIndicator(
                                      radius: 11,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      "Upload",
                                      style: TextStyle(
                                        color: isDark
                                            ? colors.onHero
                                            : Colors.white,
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
    context.read<FetchCustomerBloc>().add(
      StartCustomerSyncEvent(
        ipAddress: "",
      ),
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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color imageBackground = kSecondaryColor;
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool isLandscape = context.isLandscape;
    final double screenHeight = media.size.height;
    final double screenWidth = media.size.width;

    final double imageHeight = isTablet
        ? (isLandscape
              ? (screenHeight * 0.44).clamp(320.0, 520.0)
              : (screenHeight * 0.42).clamp(360.0, 620.0))
        : (screenHeight * 0.42).clamp(250.0, 400.0);

    final double contentTargetHeight = isTablet
        ? (screenHeight - imageHeight - (isLandscape ? 120 : 150)).clamp(
            380.0,
            980.0,
          )
        : 0.0;
    final double upperMinHeight = isTablet
        ? (contentTargetHeight * (isLandscape ? 0.56 : 0.60)).clamp(
            260.0,
            620.0,
          )
        : 0.0;
    final double cardHorizontalPadding = isTablet
        ? (screenWidth * (isLandscape ? 0.045 : 0.04)).clamp(24.0, 56.0)
        : 20.0;
    final double sectionGap = isTablet ? (isLandscape ? 16.0 : 20.0) : 20.0;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double bottomGap = (isTablet ? 40.0 : 100.0) + bottomSafeArea;

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
          backgroundColor: isDark ? colors.bg : kPrimaryColor,
          body: SafeArea(
            bottom: false,
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDark ? colors.heroGradient : kGColor,
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
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: upperMinHeight),
                          child: DetailedUpperGlass(
                            descController: _descriptionController,
                            custom1Controller: _custom1Controller,
                            custom2Controller: _custom2Controller,
                            custom1Label: custom1Label,
                            custom2Label: custom2Label,
                            dept: widget.stock.deptName ?? "-",
                            barcode: widget.stock.barcode,
                            qty:
                                "Qty On-Hand: ${(widget.stock.quantity % 1 == 0) ? widget.stock.quantity.toInt().toString() : double.parse(widget.stock.quantity.toStringAsFixed(2)).toString()}",

                            cats:
                                "${widget.stock.category1 ?? "-"} / ${widget.stock.category2 ?? "-"} / ${widget.stock.category3 ?? "-"}",
                            cost: cost,
                            sell: sell,
                            layByQty: (widget.stock.laybyQuantity % 1 == 0)
                                ? widget.stock.laybyQuantity.toInt().toString()
                                : double.parse(
                                    widget.stock.laybyQuantity.toStringAsFixed(
                                      2,
                                    ),
                                  ).toString(),
                            soQty: (widget.stock.salesOrderQuantity % 1 == 0)
                                ? widget.stock.salesOrderQuantity
                                      .toInt()
                                      .toString()
                                : double.parse(
                                    widget.stock.salesOrderQuantity
                                        .toStringAsFixed(2),
                                  ).toString(),
                            exCost: exCost,
                            costTaxLabel: _formatTaxLabel(
                              widget.stock.goodsTax,
                              costTaxPercentage,
                            ),
                            sellTaxLabel: _formatTaxLabel(
                              widget.stock.salesTax,
                              sellTaxPercentage,
                            ),
                            lastSaleDate: _formatLastSaleDate(
                              widget.stock.lastSaleDate,
                            ),
                            showCostPrices: !hideCostPrice,
                          ),
                        ),
                      ),

                      SizedBox(height: sectionGap),

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

                      SizedBox(height: bottomGap),
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

  Widget topIconsRow() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              _buildCircularIcon(
                icon: Icons.camera_alt_rounded,
                onTap: _onCameraTap,
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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : kSecondaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? colors.cardShadow
                  : kThirdColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? colors.onSurface : kThirdColor,
          size: 16,
        ),
      ),
    );
  }
}
