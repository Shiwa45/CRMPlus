import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/layout/desktop_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Remove the # from URL on web
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const EasyianApp(),
    ),
  );
}

class EasyianApp extends StatelessWidget {
  const EasyianApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Easyian CRM',
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: provider.loading
          ? const _SplashScreen()
          : provider.currentUser != null
              ? const DesktopShell()
              : const LoginScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
