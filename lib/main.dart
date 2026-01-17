import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'local_db/local_db_dao.dart';
import 'local_db/sqlite/sqlite_dao_impl.dart';
import 'utils/dependency_injection_utils.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  LocalDbDAO.configure(SQLiteDAOImpl());
  await LocalDbDAO.instance.initDB();
  await di.init();
  runApp(MyApp());
}
