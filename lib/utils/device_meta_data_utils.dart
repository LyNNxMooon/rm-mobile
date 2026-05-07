import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';

import '../entities/vos/device_metedata_vo.dart';

class DeviceMetaDataUtils {
  DeviceMetaDataUtils._();

  static final DeviceMetaDataUtils _instance = DeviceMetaDataUtils._();

  static DeviceMetaDataUtils get instance => _instance;

  /// Cache for tablet detection result
  bool? _isTabletCached;

  /// Checks if the device is natively a tablet (iPad or Android tablet)
  /// Uses multiple detection methods:
  /// 1. iOS: Check if model contains "iPad"
  /// 2. Android: Check system features for tablet flag
  /// 3. Android: Check model name for tablet keywords
  /// 4. Fallback: Check screen size (shortestSide >= 600dp)
  Future<bool> isTablet() async {
    // Return cached result if available
    if (_isTabletCached != null) return _isTabletCached!;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // iPad model names start with "iPad"
      _isTabletCached = iosInfo.model.toLowerCase().contains('ipad');
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      
      // Method 1: Check system features for tablet indicator
      final features = androidInfo.systemFeatures;
      final bool hasTabletFeature = features.contains('android.hardware.type.tablet');
      
      // Method 2: Check model name for tablet keywords
      final String model = androidInfo.model.toLowerCase();
      final bool modelSuggestsTablet = model.contains('tab') || 
                                       model.contains('pad') || 
                                       model.contains('tablet') ||
                                       model.contains('sm-t') ||  // Samsung tablets
                                       model.contains('sm-x');    // Samsung tablets (newer)
      
      // Method 3: Check screen size as final fallback
      // Use PlatformDispatcher to get physical screen size
      final display = PlatformDispatcher.instance.displays.first;
      final size = display.size;
      final devicePixelRatio = display.devicePixelRatio;
      final shortestSideDp = size.shortestSide / devicePixelRatio;
      final bool screenSizeSuggestsTablet = shortestSideDp >= 600;
      
      _isTabletCached = hasTabletFeature || modelSuggestsTablet || screenSizeSuggestsTablet;
    } else {
      _isTabletCached = false;
    }

    return _isTabletCached!;
  }

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
