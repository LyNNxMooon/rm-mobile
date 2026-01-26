import 'dart:ui'; // Required for ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
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

  @override
  void initState() {
    if ((widget.stock.goodsTax ?? "") == "GST") {
      cost = widget.stock.cost * 1.1;
    } else {
      cost = widget.stock.cost;
    }

    if ((widget.stock.salesTax ?? "") == "GST") {
      sell = widget.stock.sell * 1.1;
    } else {
      sell = widget.stock.sell;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: kGColor),
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamic Height: 42% of screen, but capped between 250px and 400px
                      // This prevents it from being too small on landscape or too huge on giant tablets
                      double screenHeight = MediaQuery.of(context).size.height;
                      double imageHeight = screenHeight * 0.42;

                      if (imageHeight > 400) imageHeight = 400;
                      if (imageHeight < 250) imageHeight = 250;

                      return Hero(
                        tag: 'stock_image_${widget.stock.stockID}',
                        child: SizedBox(
                          width: double.infinity,
                          height: imageHeight,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [

                                CachedNetworkImage(
                                  imageUrl: widget.stock.imageUrl ?? "",
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(color: kSecondaryColor),
                                  errorWidget: (_, _, _) => Container(color: kSecondaryColor),
                                ),


                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),

                                Center(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.stock.imageUrl ?? "",
                                    fit: BoxFit.contain,
                                    placeholder: (_, url) => Image.asset(
                                      overviewPlaceholder,
                                      fit: BoxFit.contain,
                                    ),
                                    errorWidget: (_, url, error) => Image.asset(
                                      overviewPlaceholder,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DetailedUpperGlass(
                      barcode: widget.stock.barcode,
                      qty: "In System: ${(widget.stock.quantity % 1 == 0) ? widget.stock.quantity.toInt().toString() : double.parse(widget.stock.quantity.toStringAsFixed(2)).toString()}",
                      description: widget.stock.description,
                      cats: "${widget.stock.category1 ?? "-"} / ${widget.stock.category2 ?? "-"} / ${widget.stock.category3 ?? "-"}",
                      cost: cost,
                      sell: sell,
                      custom1: widget.stock.custom1 ?? "-",
                      custom2: widget.stock.custom2 ?? "-",
                      layByQty: (widget.stock.laybyQuantity % 1 == 0)
                          ? widget.stock.laybyQuantity.toInt().toString()
                          : double.parse(widget.stock.laybyQuantity.toStringAsFixed(2)).toString(),
                      soQty: (widget.stock.salesOrderQuantity % 1 == 0)
                          ? widget.stock.salesOrderQuantity.toInt().toString()
                          : double.parse(widget.stock.salesOrderQuantity.toStringAsFixed(2)).toString(),
                    ),
                  ),

                  const SizedBox(height: 20),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DetailedLowerGlass(sell: sell),
                  ),

                  const SizedBox(height: 100),
                ],
              ),

              topIconsRow(),
            ],
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
                onTap: () => context.navigateBack(),
              ),
              _buildCircularIcon(icon: Icons.camera_alt_rounded, onTap: () {}),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: kSecondaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kThirdColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: kThirdColor, size: 16),
      ),
    );
  }
}