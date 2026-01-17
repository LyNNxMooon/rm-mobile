import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../entities/vos/device_metedata_vo.dart';

class DeviceMetaDataUtils {
  DeviceMetaDataUtils._();

  static final DeviceMetaDataUtils _instance = DeviceMetaDataUtils._();

  static DeviceMetaDataUtils get instance => _instance;

  Future<DeviceMetadata> getDeviceInformation() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return DeviceMetadata(
        name: "${androidInfo.manufacturer} ${androidInfo.model}",
        deviceId: androidInfo.id,
      );
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return DeviceMetadata(
        name: iosInfo.name,
        deviceId: iosInfo.identifierForVendor ?? "Unknown ID",
      );
    } else {
      return DeviceMetadata(name: "Generic Device", deviceId: "Unknown");
    }
  }
}
