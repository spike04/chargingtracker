import 'package:injectable/injectable.dart';

import '../database/app_database.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
