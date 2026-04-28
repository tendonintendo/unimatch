// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/match_provider.dart';
import 'providers/swipe_provider.dart';
import 'screens/shell/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'repositories/auth_repository.dart';
import 'repositories/swipe_repository.dart';
import 'repositories/match_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/chat_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'matches',
        channelName: 'Matches',
        channelDescription: 'New match notifications',
        importance: NotificationImportance.Max,
      ),
    ],
  );

  await AwesomeNotifications().requestPermissionToSendNotifications();

  runApp(const UniMatchApp());
}

class UniMatchApp extends StatelessWidget {
  const UniMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final storageService = StorageService();

    final authRepo = AuthRepository(firestoreService);
    final userRepo = UserRepository(firestoreService);
    final swipeRepo = SwipeRepository(firestoreService);
    final matchRepo = MatchRepository(firestoreService);
    final chatRepo = ChatRepository(firestoreService);

    return MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<StorageService>.value(value: storageService),
        Provider<ChatRepository>.value(value: chatRepo),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          final user = auth.user;

          if (user != null) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => SwipeProvider(swipeRepo, user.uid, user.role),
                ),
                ChangeNotifierProvider(
                  create: (_) => MatchProvider(matchRepo, userRepo, user.uid),
                ),
              ],
              child: MaterialApp(
                title: 'Tutor Match',
                debugShowCheckedModeBanner: false,
                theme: _buildTheme(Brightness.light),
                darkTheme: _buildTheme(Brightness.dark),
                themeMode: ThemeMode.system,
                home: const AppShell(),
              ),
            );
          }

          return MaterialApp(
            title: 'Tutor Match',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: ThemeMode.system,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = const Color(0xFF6C63FF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: seed,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF6C63FF),
        showUnselectedLabels: true,
      ),
    );
  }
}