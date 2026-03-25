import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'screens/home_screen.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const PathboardApp());
}

class PathboardApp extends StatelessWidget {
  const PathboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;

        final baseLight = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C3AED),
            brightness: Brightness.light,
          ),
          fontFamily: 'Poppins',
        );

        final baseDark = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C3AED),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Poppins',
        );

        final lightTheme = baseLight.copyWith(
          scaffoldBackgroundColor: const Color(0xFFFDF2FF),
          // ⬇️ removed `const` here
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2933),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );

        final darkTheme = baseDark.copyWith(
          // ⬇️ removed `const` here as well
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );

        return MaterialApp(
          title: 'Pathboard',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          home: const StartScreen(),
          onGenerateRoute: (settingsRoute) {
            if (settingsRoute.name == '/home') {
              return PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        curved,
                      ),
                      child: child,
                    ),
                  );
                },
              );
            }
            return null;
          },
        );
      },
    );
  }
}
