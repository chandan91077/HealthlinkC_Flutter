import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_router.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/providers/app_preferences_provider.dart';
import 'package:healthlink_connect_flutter/core/theme/app_theme.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => sl<AuthProvider>()..hydrate(),
        ),
        ChangeNotifierProvider<AppPreferencesProvider>(
          create: (_) => sl<AppPreferencesProvider>()..hydrate(),
        ),
      ],
      child: Consumer<AppPreferencesProvider>(
        builder: (context, preferences, _) {
          return MaterialApp.router(
            title: 'HealthLink Connect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: preferences.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
