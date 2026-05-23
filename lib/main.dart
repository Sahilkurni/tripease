import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'firebase_options.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Session & Theme
  await authService.initSession();
  final initialTheme = await ThemeService.loadTheme();
  themeNotifier.value = initialTheme;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // debugPrint("Firebase init error: $e");
  }
  themeNotifier.addListener(() {
    ThemeService.saveTheme(themeNotifier.value);
  });

  runApp(const ProviderScope(child: TripEaseApp()));
}

class TripEaseApp extends StatelessWidget {
  const TripEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        // Update status bar brightness based on current theme
        // Update status bar brightness based on current theme
        final isDark = mode == ThemeMode.dark || 
                      (mode == ThemeMode.system && 
                       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
        
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp.router(
          title: 'TripEase',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
