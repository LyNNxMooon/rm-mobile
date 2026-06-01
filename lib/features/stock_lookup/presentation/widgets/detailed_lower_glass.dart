import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';
import 'package:rmmobile/entities/vos/package_component.dart';
import 'package:rmmobile/entities/vos/pricing_grades.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/package_components_screen.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/price_calculator_dialog.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/detailed_upper_glass.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/pricing_button.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/pricing_dialog.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../utils/tax_calculation_utils.dart';
import '../BLoC/stock_lookup_bloc.dart';
import '../BLoC/stock_lookup_events.dart';

class DetailedLowerGlass extends StatefulWidget {
  const DetailedLowerGlass({
    super.key,
    required this.sell,
    required this.exSell,
    required this.incCost,
    required this.exCost,
    required this.taxPercentage,
    required this.taxType,
    required this.stockId,
    required this.descController,
    required this.custom1Controller,
    required this.custom2Controller,
    required this.canUpdateSellPrice,
    required this.pricingRules,
    required this.costTaxLabel,
    required this.sellTaxLabel,
    required this.showCostPrices,
    this.isPackage = false,
    this.packageComponents,
    this.packageDescription,
    this.pricingGradesStock,
    this.pricingGradesCategories,
    this.pricingGradesGlobal,
    this.onFocusNodesReady,
    this.hideButtons = false,
  });

  final double sell;
  final double exSell;
  final double incCost;
  final double exCost;
  final double taxPercentage;
  final int taxType;
  final num stockId;
  final LanguageToolController descController;
  final TextEditingController custom1Controller;
  final TextEditingController custom2Controller;
  final bool canUpdateSellPrice;
  final PricingRules? pricingRules;
  final String costTaxLabel;
  final String sellTaxLabel;
  final bool showCostPrices;
  final bool isPackage;
  final List<PackageComponent>? packageComponents;
  final String? packageDescription;
  final PricingGrades? pricingGradesStock;
  final PricingGrades? pricingGradesCategories;
  final PricingGrades? pricingGradesGlobal;
  /// Callback to expose the focus nodes for iOS Done Bar integration
  final void Function(List<FocusNode> focusNodes)? onFocusNodesReady;
  /// If true, hides the action buttons (Calculator, Pricing, Update) - used for desktop layout
  final bool hideButtons;

  @override
  State<DetailedLowerGlass> createState() => _DetailedLowerGlassState();
}

class _DetailedLowerGlassState extends State<DetailedLowerGlass> {
  late final TextEditingController _rrpController;
  late final TextEditingController _exRrpController;

  final FocusNode _rrpFocus = FocusNode();
  final FocusNode _exRrpFocus = FocusNode();

  _PriceField _lastEdited = _PriceField.none;
  double? _lastIncValue;
  double? _lastExValue;

  @override
  void initState() {
    _rrpController = TextEditingController(
      text: widget.sell.toStringAsFixed(4),
    );
    _exRrpController = TextEditingController(
      text: widget.exSell.toStringAsFixed(4),
    );

    _lastIncValue = widget.sell;
    _lastExValue = widget.exSell;

    _rrpController.addListener(_onIncChanged);
    _exRrpController.addListener(_onExChanged);
    super.initState();
    
    // Notify parent about focus nodes for iOS Done Bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFocusNodesReady?.call([_rrpFocus, _exRrpFocus]);
    });
  }

  @override
  void didUpdateWidget(covariant DetailedLowerGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when parent passes new values (after async tax calculation)
    if (oldWidget.sell != widget.sell) {
      _rrpController.text = widget.sell.toStringAsFixed(4);
    }
    if (oldWidget.exSell != widget.exSell) {
      _exRrpController.text = widget.exSell.toStringAsFixed(4);
    }
  }

  @override
  void dispose() {
    if (!mounted) {
      _rrpController.dispose();
      _exRrpController.dispose();
      _rrpFocus.dispose();
      _exRrpFocus.dispose();
    }
    super.dispose();
  }

  void _onIncChanged() {
    if (!_rrpFocus.hasFocus) return;

    final text = _rrpController.text;
    if (text.isEmpty) return;

    final double incVal = double.tryParse(text) ?? 0.0;
    _lastEdited = _PriceField.inc;
    _lastIncValue = incVal;
    double exVal = 0.0;

    if (widget.taxPercentage > 0) {
      // Use precise Rational arithmetic, rounds to 4 decimals
      exVal = TaxCalculationUtils.calculateExclusivePrice(incVal, widget.taxPercentage);
    } else {
      exVal = incVal;
    }

    _lastExValue = exVal;
    _exRrpController.text = exVal.toStringAsFixed(4);
  }

  void _onExChanged() {
    if (!_exRrpFocus.hasFocus) return;

    final text = _exRrpController.text;
    if (text.isEmpty) return;

    final double exVal = double.tryParse(text) ?? 0.0;
    _lastEdited = _PriceField.ex;
    _lastExValue = exVal;
    double incVal = 0.0;

    if (widget.taxPercentage > 0) {
      // Use precise Rational arithmetic, rounds to 4 decimals
      incVal = TaxCalculationUtils.calculateInclusivePrice(exVal, widget.taxPercentage);
    } else {
      incVal = exVal;
    }

    _lastIncValue = incVal;
    _rrpController.text = incVal.toStringAsFixed(4);
  }

  void _openCalculator() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 120));

    final double? result = await showDialog<double>(
      context: context,
      builder: (context) => PriceCalculatorDialog(
        incCost: widget.incCost,
        exCost: widget.exCost,
        currentSell: double.tryParse(_rrpController.text) ?? 0.0,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // Set Inclusive Value
        _lastEdited = _PriceField.inc;
        _lastIncValue = result;
        _rrpController.text = result.toStringAsFixed(4);

        // Manually trigger the Ex Calculation since focus logic won't catch this
        // Use precise Rational arithmetic, rounds to 4 decimals
        if (widget.taxPercentage > 0) {
          final exVal = TaxCalculationUtils.calculateExclusivePrice(result, widget.taxPercentage);
          _lastExValue = exVal;
          _exRrpController.text = exVal.toStringAsFixed(4);
        } else {
          _lastExValue = result;
          _exRrpController.text = result.toStringAsFixed(4);
        }
      });
    }
  }

  void _openPricingDialog() {
    final rules = widget.pricingRules ?? PricingRules.empty();
    showDialog<void>(
      context: context,
      builder: (_) => PricingDialog(
        pricingRules: rules,
        sell: widget.sell,
        cost: widget.incCost,
        pricingGradesStock: widget.pricingGradesStock,
        pricingGradesCategories: widget.pricingGradesCategories,
        pricingGradesGlobal: widget.pricingGradesGlobal,
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

  void _submitPricingUpdate(PricingRules rules) {
    final sellVal = _resolveEditedSellValue();

    if (sellVal == null) {
      return;
    }

    final updatedDescription = widget.descController.text;
    final updatedCustom1 = widget.custom1Controller.text.trim();
    final updatedCustom2 = widget.custom2Controller.text.trim();

    context.read<StockUpdateBloc>().add(
      SubmitStockUpdateEvent(
        stockId: widget.stockId.toInt(),
        description: updatedDescription,
        sell: sellVal,
        custom1: updatedCustom1.isNotEmpty ? updatedCustom1 : null,
        custom2: updatedCustom2.isNotEmpty ? updatedCustom2 : null,
        pricingRules: rules,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color onGlass = isDark ? Colors.white : kSecondaryColor;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    
    // Desktop-specific smaller sizes
    final double containerVertical = useDesktopNav ? 12 : ((isTablet ? 24 : 20) * uiScale);
    final double containerHorizontal = useDesktopNav ? 10 : ((isTablet ? 14 : 12) * uiScale);
    final double rowGap = useDesktopNav ? 8 : ((isTablet ? 18 : 15) * uiScale);
    final double fieldHeight = useDesktopNav ? 26 : ((isTablet ? 40 : 35) * uiScale);
    final double buttonVertical = useDesktopNav ? 5 : ((isTablet ? 8 : 6) * uiScale);
    final double buttonGap = useDesktopNav ? 8 : ((isTablet ? 12 : 10) * uiScale);
    final double labelFontSize = useDesktopNav ? 12 : 14;
    final double inputFontSize = useDesktopNav ? 12 : 14;

    return Column(
      children: [
        _buildGlassPanel(
          colors: colors,
          isDark: isDark,
          verticalPadding: containerVertical,
          horizontalPadding: containerHorizontal,
          child: Column(
            children: [
              if (widget.showCostPrices) ...[
                StockInfoRow(
                  image: "assets/images/cost_white.png",
                  icon: Icons.percent,
                  iconBgColor: Colors.deepPurpleAccent,
                  label: "Cost / Sell Tax",
                  value: "${widget.costTaxLabel} / ${widget.sellTaxLabel}",
                  fontSize: labelFontSize,
                ),
                SizedBox(height: rowGap),
                StockInfoRow(
                  image: "assets/images/cost_white.png",
                  icon: Icons.monetization_on_outlined,
                  iconBgColor: Colors.pinkAccent,
                  label: "Ex Cost",
                  value: widget.exCost.toStringAsFixed(4),
                  fontSize: labelFontSize,
                ),
                SizedBox(height: rowGap),
                StockInfoRow(
                  image: "assets/images/cost_white.png",
                  icon: Icons.monetization_on_outlined,
                  iconBgColor: Colors.lightBlue,
                  label: "Inc Cost",
                  value: widget.incCost.toStringAsFixed(4),
                  fontSize: labelFontSize,
                ),
                SizedBox(height: rowGap),
              ],
              if (widget.canUpdateSellPrice)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Container(
                            width: useDesktopNav ? 20 : 24,
                            height: useDesktopNav ? 20 : 24,
                            decoration: BoxDecoration(
                              color: isDark ? colors.surface : kSecondaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? colors.cardShadow
                                      : kThirdColor.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/rrp.png',
                                fit: BoxFit.contain,
                                color: isDark ? colors.onSurface : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Ex RRP",
                            style: TextStyle(fontSize: labelFontSize, color: onGlass),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: fieldHeight,
                        child: TextField(
                          enabled: widget.canUpdateSellPrice,
                          controller: _exRrpController,
                          focusNode: _exRrpFocus,
                          scrollPhysics: const ClampingScrollPhysics(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: TextStyle(
                            fontSize: inputFontSize,
                            color: onGlass,
                          ),
                          onEditingComplete: () {
                            final trimmedValue = _exRrpController.text.trim();
                            if (_exRrpController.text != trimmedValue) {
                              _exRrpController.value = _exRrpController.value.copyWith(
                                text: trimmedValue,
                                selection: TextSelection.collapsed(offset: trimmedValue.length),
                              );
                            }
                          },
                          decoration: _inputDecoration(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                StockInfoRow(
                  image: "assets/images/rrp.png",
                  icon: Icons.sell_outlined,
                  iconBgColor: Color.fromRGBO(203, 128, 128, 1.0).withOpacity(0.7),
                  label: "Ex RRP",
                  value: widget.exSell.toStringAsFixed(4),
                  fontSize: labelFontSize,
                ),
              SizedBox(height: rowGap),
              if (widget.canUpdateSellPrice)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Container(
                            width: useDesktopNav ? 20 : 24,
                            height: useDesktopNav ? 20 : 24,
                            decoration: BoxDecoration(
                              color: isDark ? colors.surface : kSecondaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? colors.cardShadow
                                      : kThirdColor.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/rrp.png',
                                fit: BoxFit.contain,
                                color: isDark ? colors.onSurface : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Inc RRP",
                            style: TextStyle(fontSize: labelFontSize, color: onGlass),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: fieldHeight,
                        child: TextField(
                          enabled: widget.canUpdateSellPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: _rrpController,
                          focusNode: _rrpFocus,
                          scrollPhysics: const ClampingScrollPhysics(),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: TextStyle(
                            fontSize: inputFontSize,
                            color: onGlass,
                          ),
                          onEditingComplete: () {
                            final trimmedValue = _rrpController.text.trim();
                            if (_rrpController.text != trimmedValue) {
                              _rrpController.value = _rrpController.value.copyWith(
                                text: trimmedValue,
                                selection: TextSelection.collapsed(offset: trimmedValue.length),
                              );
                            }
                          },
                          decoration: _inputDecoration(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                StockInfoRow(
                  image: "assets/images/rrp.png",
                  icon: Icons.sell_outlined,
                  iconBgColor: Colors.greenAccent.withOpacity(0.7),
                  label: "Inc RRP",
                  value: widget.sell.toStringAsFixed(4),
                  fontSize: labelFontSize,
                ),
            ],
          ),
        ),
        if (!widget.hideButtons) ...[
          SizedBox(height: rowGap),
          _buildGlassPanel(
            colors: colors,
            isDark: isDark,
            verticalPadding: containerVertical,
            horizontalPadding: containerHorizontal,
            child: Builder(
              builder: (context) {
                final viewComponentsButton = InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PackageComponentsScreen(
                          packageDescription: widget.packageDescription ?? '',
                        components: widget.packageComponents ?? [],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: buttonVertical),
                  decoration: _buttonDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "COMPONENTS",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final calculatorButton = InkWell(
                onTap: widget.canUpdateSellPrice ? _openCalculator : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: buttonVertical),
                  decoration: _buttonDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calculate,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "CALCULATOR",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final pricingButton = PricingButton(
                onTap: _openPricingDialog,
                verticalPadding: buttonVertical,
              );

              final updateButton = InkWell(
                onTap: () {
                  final sellVal = _resolveEditedSellValue();

                  if (sellVal == null) {
                    return;
                  }

                  final updatedDescription = widget.descController.text;
                  final updatedCustom1 = widget.custom1Controller.text.trim();
                  final updatedCustom2 = widget.custom2Controller.text.trim();

                  context.read<StockUpdateBloc>().add(
                    SubmitStockUpdateEvent(
                      stockId: widget.stockId.toInt(),
                      description: updatedDescription,
                      sell: sellVal,
                      custom1: updatedCustom1.isNotEmpty ? updatedCustom1 : null,
                      custom2: updatedCustom2.isNotEmpty ? updatedCustom2 : null,
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: buttonVertical),
                  decoration: _buttonDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BlocBuilder<StockUpdateBloc, StockUpdateState>(
                        builder: (context, state) {
                          if (state is StockUpdateLoading) {
                            return CupertinoActivityIndicator(radius: 10);
                          } else {
                            return Icon(
                              Icons.arrow_circle_up,
                              color: kPrimaryColor,
                              size: 20,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "UPDATE",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              // Determine which first button to show
              final bool showViewComponents = widget.isPackage &&
                  (widget.packageComponents?.isNotEmpty ?? false);
              final bool showCalculator = !widget.isPackage && widget.canUpdateSellPrice;

              if (isTablet) {
                return Row(
                  children: [
                    if (showViewComponents) ...[
                      Expanded(child: viewComponentsButton),
                      SizedBox(width: buttonGap),
                    ] else if (showCalculator) ...[
                      Expanded(child: calculatorButton),
                      SizedBox(width: buttonGap),
                    ],
                    Expanded(child: pricingButton),
                    SizedBox(width: buttonGap),
                    Expanded(child: updateButton),
                  ],
                );
              }

              return Column(
                children: [
                  if (showViewComponents) ...[
                    SizedBox(width: double.infinity, child: viewComponentsButton),
                    SizedBox(height: buttonGap),
                  ] else if (showCalculator) ...[
                    SizedBox(width: double.infinity, child: calculatorButton),
                    SizedBox(height: buttonGap),
                  ],
                  SizedBox(width: double.infinity, child: pricingButton),
                  SizedBox(height: buttonGap),
                  SizedBox(width: double.infinity, child: updateButton),
                ],
              );
            },
          ),
        ),
        ],
      ],
    );
  }

  Widget _buildGlassPanel({
    required AppThemeColors colors,
    required bool isDark,
    required double verticalPadding,
    required double horizontalPadding,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: isDark ? colors.glassFill : kSecondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? colors.glassBorder
                  : kSecondaryColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: isDark
                    ? colors.cardShadow
                    : kThirdColor.withOpacity(.1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(
          color: isDark ? Colors.white : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1),
      ),
    );
  }

  BoxDecoration _buttonDecoration({bool disabled = false}) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return BoxDecoration(
      gradient: isDark
          ? colors.glassGradient
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kSecondaryColor.withOpacity(disabled ? 0.65 : 0.95),
                kSecondaryColor.withOpacity(disabled ? 0.45 : 0.70),
              ],
            ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: isDark
            ? colors.glassBorder
            : kSecondaryColor.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  double? _resolveEditedSellValue() {
    if (!widget.canUpdateSellPrice) {
      return widget.exSell;
    }

    final bool expectsInclusive = widget.taxType != 0;

    final double? incValue = _lastIncValue ?? double.tryParse(_rrpController.text.trim());
    final double? exValue = _lastExValue ?? double.tryParse(_exRrpController.text.trim());

    if (expectsInclusive) {
      if (incValue != null) return incValue;
      if (exValue == null) return null;
      if (widget.taxPercentage <= 0) return exValue;
      return TaxCalculationUtils.calculateInclusivePrice(
        exValue,
        widget.taxPercentage,
      );
    }

    if (exValue != null) return exValue;
    if (incValue == null) return null;
    if (widget.taxPercentage <= 0) return incValue;
    return TaxCalculationUtils.calculateExclusivePrice(
      incValue,
      widget.taxPercentage,
    );
  }
}

enum _PriceField {
  none,
  ex,
  inc,
}
