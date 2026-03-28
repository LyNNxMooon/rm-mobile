
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/dependency_injection_utils.dart' as di;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'local_db/sqlite/sqlite_dao_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_common_ffi for Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

 // final view = WidgetsBinding.instance.platformDispatcher.views.first;

 // final double physicalShortestSide = view.physicalSize.shortestSide;
 // final double devicePixelRatio = view.devicePixelRatio;
 // final double logicalShortestSide = physicalShortestSide / devicePixelRatio;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  LocalDbDAO.configure(SQLiteDAOImpl());
  await LocalDbDAO.instance.initDB();
  await di.init();

  runApp(const MyApp());
}