
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/dependency_injection_utils.dart' as di;

import 'app.dart';
import 'local_db/sqlite/sqlite_dao_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final view = WidgetsBinding.instance.platformDispatcher.views.first;

  final double physicalShortestSide = view.physicalSize.shortestSide;
  final double devicePixelRatio = view.devicePixelRatio;
  final double logicalShortestSide = physicalShortestSide / devicePixelRatio;

  if (logicalShortestSide < 600) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  LocalDbDAO.configure(SQLiteDAOImpl());
  await LocalDbDAO.instance.initDB();
  await di.init();

  runApp(const MyApp());
}