// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
          //forceRefresh: true
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _onCameraTap() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kSecondaryColor,
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
                title: const Text("Take Photo"),
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
                title: const Text("Choose from Gallery"),
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
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
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: kThirdColor.withOpacity(0.1),
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
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: kGreyColor,
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
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Upload",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

    if (confirmed != true) return;

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
    final id = widget.stock.stockID;
    final fileName = "${id.toInt()}.jpg";

    // try a few times while the agent generates/updates thumbnails
    const delays = <Duration>[
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ];

    for (final d in delays) {
      await Future.delayed(d);
      if (!mounted) return;

      context.read<FullImageBloc>().add(
        RequestFullImageEvent(
          stockId: id,
          pictureFileName: fileName,
          forceRefresh: true,
        ),
      );

      context.read<ThumbnailBloc>().add(
        RequestThumbnailEvent(
          stockId: id,
          pictureFileName: fileName,
          forceRefresh: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return BlocListener<StockImageUploadBloc, StockImageUploadState>(
      listener: (context, state) {
        if (state is StockImageUploaded) {
          AlertInfo.show(
            context: context,

            text: state.message,

            typeInfo: TypeInfo.success,

            backgroundColor: kSecondaryColor,

            iconColor: kPrimaryColor,

            textColor: kThirdColor,
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
      child: Scaffold(
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
                        double screenHeight = MediaQuery.of(
                          context,
                        ).size.height;
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
                                  int rev = 0;

                                  if (state is FullImageLoaded) {
                                    localPath =
                                        state.imagePaths[widget.stock.stockID];
                                    isLoading = state.loading.contains(
                                      widget.stock.stockID,
                                    );
                                    rev = state.rev[widget.stock.stockID] ?? 0;
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
                                          key: ValueKey(
                                            'full_${widget.stock.stockID}_$rev',
                                          ),
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
                                                key: ValueKey(
                                                  'full_center_${widget.stock.stockID}_$rev',
                                                ),
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
