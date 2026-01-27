import 'dart:convert';
import 'dart:typed_data';
import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/network/LAN_sharing/lan_network_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import 'package:smb_connect/smb_connect.dart';

import '../../utils/log_utils.dart';

class LanNetworkServiceImpl implements LanNetworkService {
  LanNetworkServiceImpl._();

  static final LanNetworkServiceImpl _instance = LanNetworkServiceImpl._();
  static LanNetworkServiceImpl get instance => _instance;
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  Future<List<NetworkComputerVO>> scanNetwork() async {
    //await Permission.locationWhenInUse.request();

    List<NetworkComputerVO> devices = [];

    final String? ip = await _networkInfo.getWifiIP();
    if (ip == null || ip == '0.0.0.0') {
      logger.e("Could not get IP or connected to cellular.");
      return [];
    }

    final String subnetId = ip.substring(0, ip.lastIndexOf('.'));
    final List<String> targetIps = List.generate(
      254,
      (i) => '$subnetId.${i + 1}',
    );
    final int batchSize = 30;

    for (int i = 0; i < targetIps.length; i += batchSize) {
      final end = (i + batchSize < targetIps.length)
          ? i + batchSize
          : targetIps.length;
      final batch = targetIps.sublist(i, end);

      final results = await Future.wait(
        batch.map((hostIp) => _checkSmbPort(hostIp)),
      );

      devices.addAll(results.whereType<NetworkComputerVO>());
    }

    return devices;
  }

  Future<NetworkComputerVO?> _checkSmbPort(String targetIp) async {
    try {
      final socket = await Socket.connect(
        targetIp,
        445,
        timeout: Duration(milliseconds: 750),
      );
      socket.destroy();

      String hostname = targetIp;
      try {
        final hostEntry = await InternetAddress(targetIp).reverse();

        if (hostEntry.host == targetIp) {
          hostname = "($targetIp)UnknownPC";
        } else {
          hostname = hostEntry.host;
          if (hostname.endsWith('.local')) {
            hostname = hostname.replaceAll('.local', '');
          }
          if (hostname.endsWith('.lan')) {
            hostname = hostname.replaceAll('.lan', '');
          }
        }
      } catch (e) {
        hostname = "($targetIp)UnknownPC";
      }

      return NetworkComputerVO(ipAddress: targetIp, hostName: hostname);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getDirectoryListing({
    required String address,
    required String path,
    required String username,
    required String password,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      List<String> resultNames = [];
      if (path.isEmpty || path == "/") {
        final shares = await connect.listShares();
        resultNames = shares
            .where((e) => e.isDirectory())
            .map((e) => e.name)
            .toList();
      } else {
        final String formattedPath = path.startsWith('/') ? path : '/$path';
        final folder = await connect.file(formattedPath);
        final files = await connect.listFiles(folder);

        resultNames = files
            .where((e) => e.isDirectory())
            .map((e) => e.name)
            .toList();
      }

      return resultNames;
    } on Exception catch (e) {
      final error = e as dynamic;

      try {
        if (error.message != null) {
          return Future.error(error.message);
        }
      } catch (_) {}

      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }

  @override
  Future<void> writeToSelectedFolder({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      final String filePath = "$cleanedPath/connection-confirmation.txt";

      final file = await connect.createFile(filePath);

      IOSink writer = await connect.openWrite(file);
      writer.add(utf8.encode('Hello! RM-Mobile is successfully here!'));

      await writer.flush();
      await writer.close();
    } catch (e) {
      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }

  @override
  Future<ShopfrontResponse> getShopfronts({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  }) async {
    SmbConnect? connect;

    try {
      connect = await SmbConnect.connectAuth(
        host: address,
        domain: "",
        username: username,
        password: password,
      );

      logger.d("Host IP address: $address");
      logger.d("FULL : $fullPath");

      String cleanedPath = fullPath.replaceFirst(
        RegExp(r'^//\d{1,3}(\.\d{1,3}){3}'),
        '',
      );

      final String targetFile = "$cleanedPath/shopfronts.json";
      logger.d("Target SMB File Path: $targetFile");

      final file = await connect.file(targetFile);
      final stream = await connect.openRead(file);
      final String jsonContent = await utf8.decodeStream(stream);

      return ShopfrontResponse.fromJson(jsonDecode(jsonContent));
    } catch (e) {
      return Future.error("Error loading shopfronts: $e");
    } finally {
      await connect?.close();
    }
  }

  @override
  Future<void> writeStocktakeDataToSharedFolder({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName,
    required String fileContent,
    required bool isCheck,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }

      final String incomingPath = "$cleanedPath/incoming";
      final folder = await connect.file(incomingPath);
      final files = await connect.listFiles(folder);

      final int lastUnderscore = fileName.lastIndexOf('_');
      final String filePrefix = lastUnderscore > 0
          ? fileName.substring(0, lastUnderscore + 1)
          : fileName;

      if (isCheck) {
        for (final file in files) {
          if (!file.isDirectory() && file.name.startsWith(filePrefix)) {
            await connect.delete(file);
          }
        }
      }

      final String destinationPath = "$incomingPath/$fileName";
      final file = await connect.createFile(destinationPath);
      IOSink writer = await connect.openWrite(file);

      final List<int> gzBytes = GZipCodec().encode(utf8.encode(fileContent));
      writer.add(gzBytes);

      await writer.flush();
      await writer.close();
    } catch (e) {
      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }

  @override
  Future<bool> isShopfrontsFileExists({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  }) async {
    SmbConnect? connect;

    try {
      logger.d("Final stage of tracking cred: $username / $password");

      connect = await SmbConnect.connectAuth(
        host: address,
        domain: "",
        username: username,
        password: password,
      );

      String cleanedPath = fullPath.replaceFirst(
        RegExp(r'^//\d{1,3}(\.\d{1,3}){3}'),
        '',
      );

      final String targetFile = "$cleanedPath/shopfronts.json";
      final file = await connect.file(targetFile);
      final bool exists = file.isExists;

      logger.d("Shopfronts file existence at $targetFile: $exists");
      return exists;
    } catch (e) {
      logger.e("Error checking file existence: $e");
      return false;
    } finally {
      await connect?.close();
    }
  }

  @override
  Future<void> sendStockRequest({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName,
    required String fileContent,
    required String mobileID,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }

      final String outgoingPath = '$cleanedPath/outgoing';

      final folder = await connect.file(outgoingPath);
      final files = await connect.listFiles(folder);

      for (final file in files) {
        if (!file.isDirectory() &&
            file.name.startsWith('${mobileID}_request_')) {
          await connect.delete(file);
        }
      }

      final String destinationPath = "$cleanedPath/outgoing/$fileName";
      final file = await connect.createFile(destinationPath);
      IOSink writer = await connect.openWrite(file);
      writer.add(utf8.encode(fileContent));

      await writer.flush();
      await writer.close();
    } catch (e) {
      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }

  // @override
  // Future<Uint8List?> fetchLatestStockFile({
  //   required String address,
  //   required String fullPath,
  //   required String username,
  //   required String password,
  //   required String mobileName,
  // }) async {
  //   final connect = await SmbConnect.connectAuth(
  //     host: address,
  //     domain: "",
  //     username: username,
  //     password: password,
  //   );

  //   try {
  //     String cleanedPath = fullPath
  //         .replaceFirst(RegExp(r'^//'), '')
  //         .replaceFirst(address, '')
  //         .replaceFirst(RegExp(r'^/'), '');

  //     if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
  //     if (cleanedPath.endsWith('/')) {
  //       cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
  //     }

  //     final String targetDir = "$cleanedPath/outgoing";

  //     logger.d(mobileName);
  //     final folder = await connect.file(targetDir);

  //     List<SmbFile> files = await connect.listFiles(folder);

  //     final sanitizedMobileName = mobileName.replaceAll(' ', '_');

  //     final targetFile = files.where((f) {
  //       final nameMatch = f.name.contains("${sanitizedMobileName}_stocklookup");
  //       final extensionMatch = f.name.endsWith(".gz");
  //       return nameMatch && extensionMatch;
  //     }).toList();

  //     if (targetFile.isNotEmpty) {
  //       targetFile.sort(
  //         (a, b) => (b.createTime).compareTo(a.createTime),
  //       );
  //     } else {
  //       return null;
  //     }

  //     final fileToDownload = targetFile.first;
  //     logger.d("Target file identified: ${fileToDownload.name}");

  //     final stream = await connect.openRead(fileToDownload);
  //     final List<int> bytes = [];
  //     await for (var data in stream) {
  //       bytes.addAll(data);
  //     }

  //     await connect.delete(fileToDownload);

  //     return Uint8List.fromList(bytes);
  //   } catch (e) {
  //     return Future.error("SMB Error: ${e.toString()}");
  //   } finally {
  //     await connect.close();
  //   }
  // }

  @override
  Future<SmbFile?> pollForStocktakeValidationFile({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileNamePattern,
    required int maxRetries,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }

      final String targetDir = "$cleanedPath/outgoing/stocktakeValidation";
      final folder = await connect.file(targetDir);

      for (int i = 0; i < maxRetries; i++) {
        final files = await connect.listFiles(folder);

        final matches = files
            .where(
              (f) =>
                  !f.isDirectory() &&
                  f.name.contains(fileNamePattern) &&
                  f.name.endsWith(".gz"),
            )
            .toList();

        if (matches.isNotEmpty) {
          matches.sort((a, b) => (b.createTime).compareTo(a.createTime));
          return matches.first;
        }

        await Future.delayed(const Duration(seconds: 1));
        logger.d("Polling for $fileNamePattern... Attempt ${i + 1}");
      }

      return null;
    } finally {
      await connect.close();
    }
  }

  @override
  Future<Uint8List> downloadAndDeleteFile({
    required String address,
    required String username,
    required String password,
    required SmbFile fileToDownload,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      final stream = await connect.openRead(fileToDownload);
      final List<int> bytes = [];

      await for (var data in stream) {
        bytes.addAll(data);
      }

      await connect.delete(fileToDownload);
      return Uint8List.fromList(bytes);
    } finally {
      await connect.close();
    }
  }

  @override
  Future<SmbFile?> pollForFile({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileNamePattern,
    required int maxRetries,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }
      final String targetDir = "$cleanedPath/outgoing";
      final folder = await connect.file(targetDir);

      for (int i = 0; i < maxRetries; i++) {
        List<SmbFile> files = await connect.listFiles(folder);

        final targetFile = files
            .where(
              (f) => f.name.contains(fileNamePattern) && f.name.endsWith(".gz"),
            )
            .toList();

        //this compare the time and leave the old stale files
        if (targetFile.isNotEmpty) {
          targetFile.sort((a, b) => (b.createTime).compareTo(a.createTime));
          return targetFile.first;
        }

        await Future.delayed(const Duration(seconds: 1));
        logger.d("Polling for $fileNamePattern... Attempt ${i + 1}");
      }
      return null;
    } finally {
      await connect.close();
    }
  }

  @override
  Future<Uint8List> downloadFileBytes({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String shopfrontName,
    required String thumbFileName,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }

      String targetPath =
          "$cleanedPath/outgoing/$shopfrontName/Thumbnails/$thumbFileName";
      final file = await connect.file(targetPath);
      final stream = await connect.openRead(file);

      final List<int> bytes = [];
      await for (final data in stream) {
        bytes.addAll(data);
      }
      return Uint8List.fromList(bytes);
    } on Exception catch (e) {
      final error = e as dynamic;
      try {
        if (error.message != null) return Future.error(error.message);
      } catch (_) {}
      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }

  @override
  Future<Uint8List> downloadFullImageBytes({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String shopfrontName,
    required String pictureFileName,
  }) async {
    final connect = await SmbConnect.connectAuth(
      host: address,
      domain: "",
      username: username,
      password: password,
    );

    try {
      String cleanedPath = fullPath
          .replaceFirst(RegExp(r'^//'), '')
          .replaceFirst(address, '')
          .replaceFirst(RegExp(r'^/'), '');

      if (cleanedPath.startsWith('/')) cleanedPath = cleanedPath.substring(1);
      if (cleanedPath.endsWith('/')) {
        cleanedPath = cleanedPath.substring(0, cleanedPath.length - 1);
      }

      final String targetPath =
          "$cleanedPath/outgoing/$shopfrontName/Pictures/$pictureFileName";

      final file = await connect.file(targetPath);
      final stream = await connect.openRead(file);

      final List<int> bytes = [];
      await for (final data in stream) {
        bytes.addAll(data);
      }
      return Uint8List.fromList(bytes);
    } on Exception catch (e) {
      final error = e as dynamic;
      try {
        if (error.message != null) return Future.error(error.message);
      } catch (_) {}
      return Future.error(e.toString());
    } finally {
      await connect.close();
    }
  }
}
