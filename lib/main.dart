import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/update_checker.dart';
import 'core/api_keys.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'services/social_service.dart';
import 'services/admin_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/main_layout.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase başlatılamadı: $e');
  }

  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      // Şifre sıfırlama linkine tıklandığında hemen ekranı aç
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    }
  });
  
  // Tarih formatlarını başlat
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  // Tercihleri oku
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('isDarkMode') ?? false;
  final String? savedLang = prefs.getString('app_language');
  final ThemeMode initialTheme = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(RatixApp(initialTheme: initialTheme, initialLanguageCode: savedLang));
}

class RatixApp extends StatelessWidget {
  final ThemeMode initialTheme;
  final String? initialLanguageCode;

  const RatixApp({super.key, required this.initialTheme, this.initialLanguageCode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<SocialService>(create: (_) => SocialService()),
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialTheme: initialTheme)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLanguageCode: initialLanguageCode)),
      ],
      child: const RatixMaterialApp(),
    );
  }
}

class RatixMaterialApp extends StatelessWidget {
  const RatixMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Ratix',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      
      // -- DİL DESTEĞİ --
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // -- MODERN TEMA AYARLARI --
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: const UpdateChecker(child: AuthWrapper()),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "✦",
                    style: TextStyle(
                      fontSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),  
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }
        
        return const LoginScreen();
      },
    );
  }
}
