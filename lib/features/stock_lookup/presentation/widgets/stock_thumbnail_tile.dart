import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/images.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

class StockThumbnailTile extends StatelessWidget {
  final StockVO stock;

  const StockThumbnailTile({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = (stock.imageUrl ?? "").trim();
    if (imageUrl.isEmpty) {
      return Image.asset(overviewPlaceholder, fit: BoxFit.fill);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.fill,
      placeholder: (_, _) => Image.asset(overviewPlaceholder, fit: BoxFit.fill),
      errorWidget: (_, _, _) =>
          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
    );
  }
}
