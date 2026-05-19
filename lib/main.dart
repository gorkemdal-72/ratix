import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Türkçe tarih formatını başlat
  await initializeDateFormatting('tr_TR', null);

  // Tema tercihini oku
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('isDarkMode') ?? false;
  final ThemeMode initialTheme = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(RatixApp(initialTheme: initialTheme));
}

class RatixApp extends StatelessWidget {
  final ThemeMode initialTheme;

  const RatixApp({super.key, required this.initialTheme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialTheme: initialTheme)),
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

    return MaterialApp(
      title: 'Ratix',
      debugShowCheckedModeBanner: false,
      
      // -- MODERN TEMA AYARLARI --
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: const AuthWrapper(),
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
                  // Branded loading
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
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}