import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
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
    super.initState();

    final pic = widget.stock.pictureFileName;
    if (pic != null && pic.isNotEmpty) {
      context.read<FullImageBloc>().add(
        RequestFullImageEvent(
          stockId: widget.stock.stockID,
          pictureFileName: pic,
        ),
      );
    }

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
                            child: BlocBuilder<FullImageBloc, FullImageState>(
                              builder: (context, state) {
                                String? localPath;
                                bool isLoading = false;

                                if (state is FullImageLoaded) {
                                  localPath =
                                      state.imagePaths[widget.stock.stockID];
                                  isLoading = state.loading.contains(
                                    widget.stock.stockID,
                                  );
                                }

                                final bool hasFile =
                                    localPath != null &&
                                    localPath.isNotEmpty &&
                                    File(localPath).existsSync();

                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // BACKGROUND (blurred if file exists, else color)
                                    if (hasFile)
                                      Image.file(
                                        File(localPath),
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Container(color: kSecondaryColor),
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 0.6,
                                        sigmaY: 0.6,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.04),
                                      ),
                                    ), // CENTER IMAGE
                                    Center(
                                      child: hasFile
                                          ? Image.file(
                                              File(localPath),
                                              fit: BoxFit.contain,
                                            )
                                          : Image.asset(
                                              overviewPlaceholder,
                                              fit: BoxFit.contain,
                                            ),
                                    ), // OPTIONAL: loading indicator overlay
                                    if (!hasFile && isLoading)
                                      const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CupertinoActivityIndicator(),
                                        ),
                                      ),
                                  ],
                                );
                              },
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
                              widget.stock.salesOrderQuantity.toStringAsFixed(
                                2,
                              ),
                            ).toString(),
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
