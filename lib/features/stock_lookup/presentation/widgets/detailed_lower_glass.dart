import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';
import 'package:rmmobile/entities/vos/package_component.dart';
import 'package:rmmobile/entities/vos/pricing_grades.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
//import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/package_components_screen.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/price_calculator_dialog.dart';
//import 'package:rmmobile/features/stock_lookup/presentation/widgets/detailed_upper_glass.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/pricing_dialog.dart';
import '../../../../constants/colors.dart';
//import '../../../../constants/theme_colors.dart';
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
   // final colors = context.appColors;
    //final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    
    // Desktop-specific smaller sizes

    final double rowGap = useDesktopNav ? 8 : ((isTablet ? 18 : 15) * uiScale);
    final double buttonVertical = useDesktopNav ? 12 : ((isTablet ? 16 : 14) * uiScale);
    final double buttonGap = useDesktopNav ? 8 : ((isTablet ? 12 : 10) * uiScale);

    return Column(
      children: [
        if (!widget.hideButtons) ...[
          SizedBox(height: rowGap),
          Builder(
            builder: (context) {
                // Determine which first button to show
                final bool showViewComponents = widget.isPackage &&
                    (widget.packageComponents?.isNotEmpty ?? false);
                final bool showCalculator =
                    !widget.isPackage && widget.canUpdateSellPrice;

                final String firstLabel =
                    showViewComponents ? "COMPONENTS" : "CALCULATOR";
                final VoidCallback? firstOnTap = showViewComponents
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageComponentsScreen(
                              packageDescription:
                                  widget.packageDescription ?? '',
                              components: widget.packageComponents ?? [],
                            ),
                          ),
                        );
                      }
                    : (widget.canUpdateSellPrice ? _openCalculator : null);

                final bool showFirstButton =
                    showViewComponents || showCalculator;

                final Widget firstButton = _buildPillButton(
                  label: firstLabel,
                  filled: false,
                  onTap: firstOnTap,
                  verticalPadding: buttonVertical,
                );

                final Widget pricingButton = _buildPillButton(
                  label: "PRICING",
                  filled: true,
                  onTap: _openPricingDialog,
                  verticalPadding: buttonVertical,
                );

                return Row(
                  children: [
                    if (showFirstButton) ...[
                      Expanded(child: firstButton),
                      SizedBox(width: buttonGap),
                    ],
                    Expanded(child: pricingButton),
                  ],
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool filled,
    required VoidCallback? onTap,
    required double verticalPadding,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
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
