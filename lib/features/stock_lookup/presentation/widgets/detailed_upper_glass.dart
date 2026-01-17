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
    required this.description,
    required this.cats,
    required this.custom1,
    required this.custom2,
    required this.layByQty,
    required this.soQty,
    required this.cost,
    required this.sell,
  });

  final String barcode;
  final String qty;
  final String description;
  final String cats;
  final String custom1;
  final String custom2;
  final String layByQty;
  final String soQty;
  final double cost;
  final double sell;

  @override
  State<DetailedUpperGlass> createState() => _DetailedUpperGlassState();
}

class _DetailedUpperGlassState extends State<DetailedUpperGlass> {
  late final LanguageToolController _languageToolController;

  @override
  void initState() {
    _languageToolController = LanguageToolController();
    _languageToolController.text = widget.description;
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      _languageToolController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
                  Text(
                    widget.barcode,
                    style: getSmartTitle(color: kSecondaryColor, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.qty,
                      style: TextStyle(fontSize: 12, color: kSecondaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.description,
                          size: 15,
                          color: kSecondaryColor,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "Description",
                        style: TextStyle(fontSize: 12, color: kSecondaryColor),
                      ),
                    ],
                  ),

                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.48,
                    height: 30,
                    child: LanguageToolTextField(
                      controller: _languageToolController,

                      style: const TextStyle(
                        fontSize: 12,
                        color: kSecondaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: "Description",
                        hintStyle: TextStyle(color: kGreyColor, fontSize: 12),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.only(
                          //top: 6,
                          right: 10,
                          left: 10,
                        ),
                        // The Border styling (Preserved)
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide(
                            color: kPrimaryColor,
                            width: 1,
                          ),
                        ),
                      ),
                      language: 'en-AU',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.category_outlined,
                label: 'Categories',
                iconBgColor: Colors.orangeAccent,
                value: widget.cats,
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.format_paint,
                iconBgColor: Colors.blue,
                label: "Custom1",
                value: widget.custom1,
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.settings,
                iconBgColor: Colors.deepOrange,
                label: "Custom2",
                value: widget.custom2,
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.numbers,
                iconBgColor: Colors.purple,
                label: "Lay-By Qty",
                value: widget.layByQty,
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.history,
                iconBgColor: Colors.yellow,
                label: "SO Qty",
                value: widget.soQty,
              ),
              const SizedBox(height: 8),
              StockInfoRow(
                icon: Icons.monetization_on_outlined,
                iconBgColor: Colors.lightBlue,
                label: "Inc Cost",
                value: widget.cost.toStringAsFixed(4),
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

  const StockInfoRow({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Icon and Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 15, color: kSecondaryColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: kSecondaryColor),
              ),
            ],
          ),

          // Wrap in Flexible/Sized box to prevent overflow if text is long
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: kSecondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
