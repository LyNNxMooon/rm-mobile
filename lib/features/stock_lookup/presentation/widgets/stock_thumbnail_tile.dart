import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/images.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';

class StockThumbnailTile extends StatefulWidget {
  final StockVO stock;

  const StockThumbnailTile({super.key, required this.stock});

  @override
  State<StockThumbnailTile> createState() => _StockThumbnailTileState();
}

class _StockThumbnailTileState extends State<StockThumbnailTile> {
  @override
  void initState() {
    super.initState();

    final pic = widget.stock.pictureFileName;
    if (pic != null && pic.isNotEmpty) {
      context.read<ThumbnailBloc>().add(
        RequestThumbnailEvent(
          stockId: widget.stock.stockID,
          pictureFileName: pic,
          //forceRefresh: true
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant StockThumbnailTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldPic = oldWidget.stock.pictureFileName ?? '';
    final newPic = widget.stock.pictureFileName ?? '';

    if (oldWidget.stock.stockID != widget.stock.stockID || oldPic != newPic) {
      if (newPic.isNotEmpty) {
        context.read<ThumbnailBloc>().add(
          RequestThumbnailEvent(
            stockId: widget.stock.stockID,
            pictureFileName: newPic,
            forceRefresh: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThumbnailBloc, ThumbnailState>(
      builder: (context, state) {
        String? localPath;
        int rev = 0;

        if (state is ThumbnailLoaded) {
          localPath = state.thumbPaths[widget.stock.stockID];
          rev = state.rev[widget.stock.stockID] ?? 0;
        }

        if (localPath != null &&
            localPath.isNotEmpty &&
            File(localPath).existsSync()) {
          return Image.file(
            File(localPath),
            key: ValueKey('thumb_${widget.stock.stockID}_$rev'),
            fit: BoxFit.fill,
          );
        }

        return Image.asset(overviewPlaceholder, fit: BoxFit.fill);
      },
    );
  }
}
