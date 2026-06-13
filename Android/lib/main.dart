import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  static const _currentVersion = '1.0.0';
  bool _updateChecked = false;

  bool _isNewer(String remote) {
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = _currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('https://fll-manger.web.app/version.json'));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final remote = data['androidVersion'] as String?;
      final downloadUrl = data['downloadUrl'] as String?;
      if (remote != null && _isNewer(remote) && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('עדכון זמין! 🎉',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            content: Text(
              'גרסה $remote זמינה!\nהגרסה שלך: $_currentVersion',
              style: TextStyle(color: AppColors.textSecondary),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('אחר כך', style: TextStyle(color: AppColors.textSecondary)),
              ),
              if (downloadUrl != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('הורד עדכון'),
                ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppProvider, AppStatus>((p) => p.status);

    if (status == AppStatus.ready) {
      Future.delayed(const Duration(seconds: 5), _checkForUpdates);
    }

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
