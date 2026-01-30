import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/device_meta_data_utils.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class UploadStockImageUseCase {
  final StockLookupRepo repository;

  UploadStockImageUseCase(this.repository);

  Future<void> call({required int stockId, required String imagePath}) async {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";
      final fullPath = AppGlobals.instance.currentPath ?? "";
      final shopfront = AppGlobals.instance.shopfront ?? "";

      String? user;
      String? pwd;

      if (await NetworkCredentialsCheckUtils.instance
          .isRequiredNetworkCredentials(ipAddress: ip)) {
        final savedCred = await LocalDbDAO.instance.getNetworkCredential(
          ip: ip,
        );
        user = savedCred?['username'] as String?;
        pwd = savedCred?['password'] as String?;
      }

      final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
          .getDeviceInformation();

      String pad(int v) => v.toString().padLeft(2, '0');
      final now = DateTime.now();
      final ts =
          "${now.year}${pad(now.month)}${pad(now.day)}${pad(now.hour)}${pad(now.minute)}${pad(now.second)}";

      final fileName =
          "${mobileInfo.deviceId}_stockimg_${shopfront.split(r'\').last}_${stockId}_$ts.jpg";

      final jpgBytes = await toJpegBytesStrict(imagePath);

      await repository.uploadStockImage(
        address: ip,
        fullPath: fullPath,
        username: user,
        password: pwd,
        fileName: fileName,
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
