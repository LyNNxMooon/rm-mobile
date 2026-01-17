import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';

class DetailedLowerGlass extends StatefulWidget {
  const DetailedLowerGlass({super.key, required this.sell});

  final double sell;

  @override
  State<DetailedLowerGlass> createState() => _DetailedLowerGlassState();
}

class _DetailedLowerGlassState extends State<DetailedLowerGlass> {
  late final TextEditingController _rrpController;

  @override
  void initState() {
    _rrpController = TextEditingController(
      text: widget.sell.toStringAsFixed(4),
    );
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      _rrpController.dispose();
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.monetization_on,
                          size: 15,
                          color: kSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Inc RRP",
                        style: TextStyle(fontSize: 12, color: kSecondaryColor),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        height: 30,
                        child: TextField(
                          controller: _rrpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kSecondaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "Sell",
                            hintStyle: TextStyle(
                              color: kGreyColor,
                              fontSize: 12,
                            ),
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
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kSecondaryColor.withOpacity(
                            0.95,
                          ), // Solid white at top-left
                          kSecondaryColor.withOpacity(
                            0.70,
                          ), // See-through at bottom-right
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),

                      // 2. The Glass Border: Crucial for the "edge" definition
                      border: Border.all(
                        color: kSecondaryColor.withOpacity(0.6),
                        width: 1.5,
                      ),

                      // 3. Soft Glow Shadow: Helps it separate from the background
                      boxShadow: [
                        BoxShadow(
                          color: kThirdColor.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      "UPDATE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
