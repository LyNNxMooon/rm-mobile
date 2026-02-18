import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:rmstock_scanner/entities/response/picture_upload_response.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';

class UploadStockImageUseCase {
  final StockLookupRepo repository;

  UploadStockImageUseCase(this.repository);

  Future<PictureUploadResponse> call({
    required int stockId,
    required String imagePath,
  }) async {
    try {
      final String ip = (await LocalDbDAO.instance.getHostIpAddress() ?? "")
          .trim();
      final int port =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String apiKey = (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String shopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (ip.isEmpty || apiKey.isEmpty || shopfrontId.isEmpty) {
        throw Exception("Missing host or shopfront setup for image upload.");
      }

      final jpgBytes = await toJpegBytesStrict(imagePath);

      return await repository.uploadStockImage(
        ip: ip,
        port: port,
        shopfrontId: shopfrontId,
        stockId: stockId,
        apiKey: apiKey,
        jpgBytes: jpgBytes,
      );
    } catch (e) {
      return Future.error(e);
    }
  }

Future<Uint8List> toJpegBytesStrict(
  String path, {
  int quality = 85,
  int maxDim = 1600,
}) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    throw Exception("Selected image format not supported. Please choose a JPEG/PNG.");
  }

  img.Image out = decoded;

  final w = out.width;
  final h = out.height;
  final longest = w > h ? w : h;

  if (longest > maxDim) {
    final scale = maxDim / longest;
    out = img.copyResize(out, width: (w * scale).round(), height: (h * scale).round());
  }

  final jpg = img.encodeJpg(out, quality: quality);
  return Uint8List.fromList(jpg);
}
}
