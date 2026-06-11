import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/routes/app_router.dart';

import 'core/theme/app_theme.dart';
import 'di_injection/dependency_injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  /// STEP 1: INIT DI
  await setupDependencies();
  runApp(  MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({
    super.key,

  });
  @override
  Widget build(BuildContext context) {
    final authBloc = getIt<AuthBloc>();
    authBloc.add(const AuthCheckRequested());
    return MultiBlocProvider(
      providers: [
        /// GLOBAL BLOCS ONLY
        BlocProvider.value(
          value: authBloc,
        ),
      ],
      child: MaterialApp.router(
        title: 'Seshlly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: buildRouter(authBloc),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              1.0,
            ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.5),
          ),
          child: child!,
        ),
      ),
    );
  }
}
