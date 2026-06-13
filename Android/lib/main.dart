import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  await NotificationService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const FllManagerApp(),
    ),
  );
}

class FllManagerApp extends StatefulWidget {
  const FllManagerApp({super.key});

  @override
  State<FllManagerApp> createState() => _FllManagerAppState();
}

class _FllManagerAppState extends State<FllManagerApp> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<AppProvider, bool>((p) => p.isDarkMode);
    return MaterialApp(
      title: 'FLL Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('he', 'IL'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  Widget build(BuildContext context) {
    final status = context.select<AppProvider, AppStatus>((p) => p.status);

    return switch (status) {
      AppStatus.loading         => const _SplashScreen(),
      AppStatus.unauthenticated => const LoginScreen(),
      AppStatus.needsTeam       => const LoginScreen(),
      AppStatus.ready           => const ShellScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🤖', style: TextStyle(fontSize: 60)),
          SizedBox(height: 20),
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text('מתחבר...', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
