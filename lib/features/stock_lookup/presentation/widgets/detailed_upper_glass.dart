import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';

class DetailedUpperGlass extends StatefulWidget {
  const DetailedUpperGlass({
    super.key,
    required this.barcode,
    required this.qty,
    required this.cats,
    required this.custom1Controller,
    required this.custom2Controller,
    required this.layByQty,
    required this.soQty,
    required this.cost,
    required this.sell,
    required this.exCost,
    required this.dept,
    required this.lastSaleDate,
    required this.showCostPrices,
    required this.descController,
  });

  final LanguageToolController descController;
  final TextEditingController custom1Controller;
  final TextEditingController custom2Controller;
  final String barcode;
  final String qty;
  final String cats;
  final String layByQty;
  final String soQty;
  final double cost;
  final double sell;
  final double exCost;
  final String dept;
  final String lastSaleDate;
  final bool showCostPrices;

  @override
  State<DetailedUpperGlass> createState() => _DetailedUpperGlassState();
}

class _DetailedUpperGlassState extends State<DetailedUpperGlass> {
  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double containerVertical = (isTablet ? 24 : 20) * uiScale;
    final double containerHorizontal = (isTablet ? 14 : 12) * uiScale;
    final double sectionGap = (isTablet ? 18 : 15) * uiScale;
    final double rowGap = (isTablet ? 10 : 8) * uiScale;
    final double descFieldHeight = (isTablet ? 40 : 35) * uiScale;
    final double customFieldHeight = (isTablet ? 36 : 32) * uiScale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          // Margin handled by parent padding in main screen for better control
          padding: EdgeInsets.symmetric(
            vertical: containerVertical,
            horizontal: containerHorizontal,
          ),
          decoration: BoxDecoration(
            color: kSecondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(blurRadius: 20, color: kThirdColor.withOpacity(.1)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Responsive Text
                    child: Text(
                      widget.barcode,
                      style: getSmartTitle(
                        color: kSecondaryColor,
                        fontSize: 18,
                      ), // Increased readability
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 25,
                          height: 25,
                          child: Image.asset(
                            "assets/images/qty.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.qty,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionGap),

              // Description Field
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align center vertically
                children: [
                  // Label & Icon Group
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
                            "assets/images/desc.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ), // Readability
                      ),
                    ],
                  ),

                  SizedBox(width: (isTablet ? 12 : 10) * uiScale),

                  // Responsive TextField
                  Expanded(
                    child: SizedBox(
                      height: descFieldHeight, // Slightly taller for better touch target
                      child: LanguageToolTextField(
                        controller: widget.descController,
                        style: const TextStyle(
                          fontSize: 14, // Increased font size
                          color: kSecondaryColor,
                        ),

                        decoration: InputDecoration(
                          //enabled: false,
                          hintText: "Description",
                          hintStyle: const TextStyle(
                            color: kGreyColor,
                            fontSize: 14,
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
                image: "assets/images/dept.png",
                icon: Icons.category_outlined,
                label: 'Department',
                iconBgColor: Colors.grey,
                value: widget.dept,
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: "assets/images/cat.png",
                icon: Icons.category_outlined,
                label: 'Categories',
                iconBgColor: Colors.orangeAccent,
                value: widget.cats,
              ),
              SizedBox(height: rowGap),
              // Custom1 Editable Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                            "assets/images/cus1.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Custom1",
                        style: TextStyle(fontSize: 14, color: kSecondaryColor),
                      ),
                    ],
                  ),
                  SizedBox(width: (isTablet ? 45 : 35) * uiScale),
                  Expanded(
                    child: SizedBox(
                      height: customFieldHeight,
                      child: TextField(
                        controller: widget.custom1Controller,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Custom1",
                          hintStyle: const TextStyle(
                            color: kGreyColor,
                            fontSize: 14,
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
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              // Custom2 Editable Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                            "assets/images/cus2.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Custom2",
                        style: TextStyle(fontSize: 14, color: kSecondaryColor),
                      ),
                    ],
                  ),
                  SizedBox(width: (isTablet ? 45 : 35) * uiScale),
                  Expanded(
                    child: SizedBox(
                      height: customFieldHeight,
                      child: TextField(
                        controller: widget.custom2Controller,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Custom2",
                          hintStyle: const TextStyle(
                            color: kGreyColor,
                            fontSize: 14,
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
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: "assets/images/layby.png",
                icon: Icons.numbers,
                iconBgColor: Colors.purple,
                label: "Lay-By Qty",
                value: widget.layByQty,
              ),
              SizedBox(height: rowGap),
              StockInfoRow(
                image: "assets/images/so.png",
                icon: Icons.history,
                iconBgColor: Colors.yellow,
                label: "SO Qty",
                value: widget.soQty,
              ),
              SizedBox(height: rowGap),
              if (widget.showCostPrices) ...[
                StockInfoRow(
                  image: "assets/images/cost_white.png",
                  icon: Icons.monetization_on_outlined,
                  iconBgColor: Colors.lightBlue,
                  label: "Inc Cost",
                  value: widget.cost.toStringAsFixed(4),
                ),
                SizedBox(height: rowGap),
                StockInfoRow(
                  image: "assets/images/cost_white.png",
                  icon: Icons.monetization_on_outlined,
                  iconBgColor: Colors.pinkAccent,
                  label: "Ex Cost",
                  value: widget.exCost.toStringAsFixed(4),
                ),
                SizedBox(height: rowGap),
              ],
              StockInfoRow(
                image: "assets/images/so.png",
                icon: Icons.event,
                iconBgColor: Colors.teal,
                label: "Last Sale",
                value: widget.lastSaleDate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StockInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String value;
  final String image;

  const StockInfoRow({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Increased padding for touchability
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Icon and Label
          Row(
            mainAxisSize: MainAxisSize.min, // Shrink wrap
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
                style: const TextStyle(
                  fontSize: 14,
                  color: kSecondaryColor,
                ), // Increased font size
              ),
            ],
          ),

          const SizedBox(width: 15), // Gap
          // Flexible Value Text (Right Aligned)
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14, // Increased font size for readability
                color: kSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
