import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:seshlly/features/dashboard/profile/domain/repositories/profile_repository.dart';
import 'package:seshlly/features/auth/domain/usecases/logout_usecase.dart';
import 'package:seshlly/features/auth/domain/usecases/register_usecase.dart';
import 'package:seshlly/features/dashboard/profile/domain/usecases/update_profile_usecase.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_bloc.dart';

import '../core/api/dio_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/storage_service.dart';
import '../features/auth/data/datasource/auth_remote_datasource.dart';
import '../features/auth/data/repository_impl/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/profile/data/datasource/profile_remote_datasource.dart';
import '../features/dashboard/profile/data/repository_impl/profile_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  /// CORE

  getIt.registerLazySingleton<Dio>(() => Dio());

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt()));

  /// AUTH
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt(), getIt(), getIt(), getIt()),
  );

  /// Profile
  getIt.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasource(getIt()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt(), getIt(), getIt()),
  );

  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => OnloadProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
}
