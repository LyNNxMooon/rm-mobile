import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';

class DetailedUpperGlass extends StatefulWidget {
  const DetailedUpperGlass({
    super.key,
    required this.barcode,
    required this.qty,
    required this.cats,
    required this.custom1Controller,
    required this.custom2Controller,
    required this.custom1Label,
    required this.custom2Label,
    required this.layByQty,
    required this.soQty,
    required this.cost,
    required this.sell,
    required this.exCost,
    required this.costTaxLabel,
    required this.sellTaxLabel,
    required this.dept,
    required this.lastSaleDate,
    required this.showCostPrices,
    required this.descController,
  });

  final LanguageToolController descController;
  final TextEditingController custom1Controller;
  final TextEditingController custom2Controller;
  final String custom1Label;
  final String custom2Label;
  final String barcode;
  final String qty;
  final String cats;
  final String layByQty;
  final String soQty;
  final double cost;
  final double sell;
  final double exCost;
  final String costTaxLabel;
  final String sellTaxLabel;
  final String dept;
  final String lastSaleDate;
  final bool showCostPrices;

  @override
  State<DetailedUpperGlass> createState() => _DetailedUpperGlassState();
}

class _DetailedUpperGlassState extends State<DetailedUpperGlass> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color onGlass = isDark ? Colors.white : kSecondaryColor;
    final Color onGlassMuted = isDark ? Colors.white70 : kGreyColor;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    
    // Desktop-specific smaller sizes
    final double containerVertical = useDesktopNav ? 12 : ((isTablet ? 24 : 20) * uiScale);
    final double containerHorizontal = useDesktopNav ? 10 : ((isTablet ? 14 : 12) * uiScale);
    final double sectionGap = useDesktopNav ? 8 : ((isTablet ? 18 : 15) * uiScale);
    final double rowGap = useDesktopNav ? 5 : ((isTablet ? 10 : 8) * uiScale);
    final double descFieldHeight = useDesktopNav ? 28 : ((isTablet ? 40 : 35) * uiScale);
    final double customFieldHeight = useDesktopNav ? 26 : ((isTablet ? 36 : 32) * uiScale);
    final double barcodeFontSize = useDesktopNav ? 12 : (isTablet ? 18 : 16);
    final double labelFontSize = useDesktopNav ? 12 : 14;
    final double inputFontSize = useDesktopNav ? 12 : 14;
    final qtyPair = _splitLabelValue(widget.qty, 'Qty');

    return Column(
      children: [
        _buildGlassPanel(
          colors: colors,
          isDark: isDark,
          verticalPadding: containerVertical,
          horizontalPadding: containerHorizontal,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.barcode,
                      style: getSmartTitle(
                        color: onGlass,
                        fontSize: barcodeFontSize,
                      ),
                      maxLines: 4,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.withOpacity(0.35)
                            : kSecondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQtyRow(
                                  iconPath: 'assets/images/qty.png',
                                  label: qtyPair.key,
                                  value: qtyPair.value,
                                  color: onGlass,
                                  isTablet: true,
                                  fontSize: labelFontSize,
                                ),
                                _buildQtyDivider(isDark, isTablet: true),
                                _buildQtyRow(
                                  iconPath: 'assets/images/layby.png',
                                  label: 'Lay-By Qty',
                                  value: widget.layByQty,
                                  color: onGlass,
                                  isTablet: true,
                                  fontSize: labelFontSize,
                                ),
                                _buildQtyDivider(isDark, isTablet: true),
                                _buildQtyRow(
                                  iconPath: 'assets/images/so.png',
                                  label: 'SO Qty',
                                  value: widget.soQty,
                                  color: onGlass,
                                  isTablet: true,
                                  fontSize: labelFontSize,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQtyRow(
                                  iconPath: 'assets/images/qty.png',
                                  label: 'On-Hand',
                                  value: qtyPair.value,
                                  color: onGlass,
                                  isTablet: false,
                                  fontSize: labelFontSize,
                                ),
                                const SizedBox(height: 6),
                                _buildQtyRow(
                                  iconPath: 'assets/images/layby.png',
                                  label: 'LB Qty',
                                  value: widget.layByQty,
                                  color: onGlass,
                                  isTablet: false,
                                  fontSize: labelFontSize,
                                ),
                                const SizedBox(height: 6),
                                _buildQtyRow(
                                  iconPath: 'assets/images/so.png',
                                  label: 'SO Qty',
                                  value: widget.soQty,
                                  color: onGlass,
                                  isTablet: false,
                                  fontSize: labelFontSize,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: 'assets/images/so.png',
                icon: Icons.event,
                iconBgColor: Colors.teal,
                label: 'Last Sale',
                value: widget.lastSaleDate,
                fontSize: labelFontSize,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        _buildGlassPanel(
          colors: colors,
          isDark: isDark,
          verticalPadding: containerVertical,
          horizontalPadding: containerHorizontal,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            'assets/images/desc.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: labelFontSize,
                          color: onGlass,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: (isTablet ? 12 : 10) * uiScale),
                  Expanded(
                    child: SizedBox(
                      height: descFieldHeight,
                      child: LanguageToolTextField(
                        controller: widget.descController,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          color: onGlass,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: TextStyle(
                            color: onGlassMuted,
                            fontSize: labelFontSize,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                        language: 'en-AU',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: 'assets/images/dept.png',
                icon: Icons.category_outlined,
                label: 'Department',
                iconBgColor: Colors.grey,
                value: widget.dept,
                fontSize: labelFontSize,
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: 'assets/images/cat.png',
                icon: Icons.category_outlined,
                label: 'Categories',
                iconBgColor: Colors.orangeAccent,
                value: widget.cats,
                fontSize: labelFontSize,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        _buildGlassPanel(
          colors: colors,
          isDark: isDark,
          verticalPadding: containerVertical,
          horizontalPadding: containerHorizontal,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Image.asset(
                              'assets/images/cus1.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.custom1Label,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              color: onGlass,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: customFieldHeight,
                      child: TextField(
                        controller: widget.custom1Controller,
                        scrollPhysics: const ClampingScrollPhysics(),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        style: TextStyle(
                          fontSize: inputFontSize,
                          color: onGlass,
                        ),
                        onEditingComplete: () {
                          final trimmedValue =
                              widget.custom1Controller.text.trim();
                          if (widget.custom1Controller.text != trimmedValue) {
                            widget.custom1Controller.value =
                                widget.custom1Controller.value.copyWith(
                              text: trimmedValue,
                              selection: TextSelection.collapsed(
                                offset: trimmedValue.length,
                              ),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          hintText: widget.custom1Label,
                          hintStyle: TextStyle(
                            color: onGlassMuted,
                            fontSize: inputFontSize,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white : Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Image.asset(
                              'assets/images/cus2.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.custom2Label,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              color: onGlass,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: customFieldHeight,
                      child: TextField(
                        controller: widget.custom2Controller,
                        scrollPhysics: const ClampingScrollPhysics(),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        style: TextStyle(
                          fontSize: inputFontSize,
                          color: onGlass,
                        ),
                        onEditingComplete: () {
                          final trimmedValue =
                              widget.custom2Controller.text.trim();
                          if (widget.custom2Controller.text != trimmedValue) {
                            widget.custom2Controller.value =
                                widget.custom2Controller.value.copyWith(
                              text: trimmedValue,
                              selection: TextSelection.collapsed(
                                offset: trimmedValue.length,
                              ),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          hintText: widget.custom2Label,
                          hintStyle: TextStyle(
                            color: onGlassMuted,
                            fontSize: inputFontSize,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white : Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 1,
                            ),
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

  Widget _buildQtyRow({
    required String iconPath,
    required String label,
    required String value,
    required Color color,
    required bool isTablet,
    double fontSize = 14,
  }) {
    final content = Row(
      mainAxisSize: isTablet ? MainAxisSize.min : MainAxisSize.max,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Image.asset(
            iconPath,
            fit: BoxFit.fill,
          ),
        ),
        const SizedBox(width: 6),
        isTablet
            ? Text(
                '$label:',
                style: TextStyle(
                  fontSize: fontSize,
                  color: color,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              )
            : Expanded(
                child: Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );

    if (isTablet) {
      return IntrinsicWidth(child: content);
    }

    return SizedBox(width: 140, child: content);
  }

  Widget _buildQtyDivider(bool isDark, {required bool isTablet}) {
    return Container(
      width: 1,
      height: isTablet ? 26 : 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark
          ? (isTablet ? Colors.white54 : Colors.white24)
          : (isTablet ? Colors.black38 : Colors.black12),
    );
  }

  MapEntry<String, String> _splitLabelValue(String text, String fallbackLabel) {
    final idx = text.indexOf(':');
    if (idx == -1) {
      return MapEntry(fallbackLabel, text);
    }
    final label = text.substring(0, idx).trim();
    final value = text.substring(idx + 1).trim();
    return MapEntry(label.isEmpty ? fallbackLabel : label, value);
  }
}

class StockInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String value;
  final String image;
  final double fontSize;

  const StockInfoRow({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.image,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color onGlass = isDark ? Colors.white : kSecondaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: Image.asset(image, fit: BoxFit.fill),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: onGlass,
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fontSize,
                color: onGlass,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}