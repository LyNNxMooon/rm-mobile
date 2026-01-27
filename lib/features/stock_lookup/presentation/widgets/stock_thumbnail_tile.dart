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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThumbnailBloc, ThumbnailState>(
      buildWhen: (prev, next) => true,
      builder: (context, state) {
        String? localPath;
        if (state is ThumbnailLoaded) {
          localPath = state.thumbPaths[widget.stock.stockID];
        }

        if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
          return Image.file(
            File(localPath),
            fit: BoxFit.fill,
          );
        }

        return Image.asset(
          overviewPlaceholder,
          fit: BoxFit.fill,
        );
      },
    );
  }
}
