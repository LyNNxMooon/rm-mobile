import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
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
      body: Container(
        decoration: BoxDecoration(gradient: kGColor),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                //Product Image Session
                Hero(
                  tag: 'stock_image_${widget.stock.stockID}',
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: CachedNetworkImage(
                        fit: BoxFit.fill,
                        imageUrl: widget.stock.imageUrl ?? "",
                        placeholder: (_, url) =>
                            Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                        errorWidget: (_, url, error) =>
                            Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //Detailed Upper Glass
                DetailedUpperGlass(
                  barcode: widget.stock.barcode,
                  qty:
                      "In System: ${(widget.stock.quantity % 1 == 0) ? widget.stock.quantity.toInt().toString() : double.parse(widget.stock.quantity.toStringAsFixed(2)).toString()}",
                  description: widget.stock.description,
                  cats:
                      "${widget.stock.category1 ?? "-"} / ${widget.stock.category2 ?? "-"} / ${widget.stock.category3 ?? "-"}",
                  cost: cost,
                  sell: sell,
                  custom1: widget.stock.custom1 ?? "-",
                  custom2: widget.stock.custom2 ?? "-",
                  layByQty: (widget.stock.laybyQuantity % 1 == 0)
                      ? widget.stock.laybyQuantity.toInt().toString()
                      : double.parse(
                          widget.stock.laybyQuantity.toStringAsFixed(2),
                        ).toString(),
                  soQty: (widget.stock.salesOrderQuantity % 1 == 0)
                      ? widget.stock.salesOrderQuantity.toInt().toString()
                      : double.parse(
                          widget.stock.salesOrderQuantity.toStringAsFixed(2),
                        ).toString(),
                ),

                const SizedBox(height: 20),

                //Detailed Lower Glass
                DetailedLowerGlass(sell: sell),
                const SizedBox(height: 20),
              ],
            ),

            topIconsRow(),
          ],
        ),
      ),
    );
  }

  //Top Floating Icons Row above item image

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
