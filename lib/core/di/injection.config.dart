// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/charging/data/datasources/charging_local_data_source.dart'
    as _i24;
import '../../features/charging/data/datasources/sqlite_charging_local_data_source.dart'
    as _i297;
import '../../features/charging/data/repositories/charging_repository_impl.dart'
    as _i180;
import '../../features/charging/domain/repositories/charging_repository.dart'
    as _i973;
import '../../features/charging/domain/usecases/add_charging_session.dart'
    as _i1010;
import '../../features/charging/domain/usecases/delete_charging_session.dart'
    as _i63;
import '../../features/charging/domain/usecases/get_charging_overview.dart'
    as _i595;
import '../../features/charging/domain/usecases/update_charging_session.dart'
    as _i907;
import '../../features/charging/presentation/bloc/charging_bloc.dart' as _i285;
import '../database/app_database.dart' as _i982;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i982.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i24.ChargingLocalDataSource>(
      () => _i297.SqliteChargingLocalDataSource(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i973.ChargingRepository>(
      () => _i180.ChargingRepositoryImpl(gh<_i24.ChargingLocalDataSource>()),
    );
    gh.lazySingleton<_i1010.AddChargingSession>(
      () => _i1010.AddChargingSession(gh<_i973.ChargingRepository>()),
    );
    gh.lazySingleton<_i63.DeleteChargingSession>(
      () => _i63.DeleteChargingSession(gh<_i973.ChargingRepository>()),
    );
    gh.lazySingleton<_i595.GetChargingOverview>(
      () => _i595.GetChargingOverview(gh<_i973.ChargingRepository>()),
    );
    gh.lazySingleton<_i907.UpdateChargingSession>(
      () => _i907.UpdateChargingSession(gh<_i973.ChargingRepository>()),
    );
    gh.factory<_i285.ChargingBloc>(
      () => _i285.ChargingBloc(
        gh<_i595.GetChargingOverview>(),
        gh<_i1010.AddChargingSession>(),
        gh<_i907.UpdateChargingSession>(),
        gh<_i63.DeleteChargingSession>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
