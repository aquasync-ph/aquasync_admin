import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const AquaSyncAdminApp());
}

class AquaSyncAdminApp extends StatefulWidget {
  const AquaSyncAdminApp({super.key});

  @override
  State<AquaSyncAdminApp> createState() => _AquaSyncAdminAppState();
}

class _AquaSyncAdminAppState extends State<AquaSyncAdminApp> {
  bool _isLoggedIn = false;
  String _loggedInUser = 'Admin';
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Elegant 1.6s branded startup splash experience
    await Future.delayed(const Duration(milliseconds: 1600));
    if (SupabaseService.isAuthenticated) {
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final profile = await SupabaseService.fetchProfile(user.id);
          final role = profile?['role']?.toString().trim().toLowerCase();
          if (role == 'admin') {
            _loggedInUser = profile?['full_name'] ??
                profile?['name'] ??
                profile?['username'] ??
                user.email?.split('@').first ??
                'Admin';
            _isLoggedIn = true;
          } else {
            await SupabaseService.signOut();
            _isLoggedIn = false;
          }
        } catch (_) {
          await SupabaseService.signOut();
          _isLoggedIn = false;
        }
      }
    }
    if (mounted) {
      setState(() {
        _isInitLoading = false;
      });
    }
  }

  void _handleLoginSuccess(String username) {
    setState(() {
      _loggedInUser = username.isNotEmpty ? username : 'Admin';
      _isLoggedIn = true;
    });
  }

  void _handleLogout() async {
    await SupabaseService.signOut();
    setState(() {
      _isLoggedIn = false;
      _loggedInUser = 'Admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'AquaSync Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
        cardColor: Colors.white,
        primaryColor: const Color(0xFF0098DA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0098DA),
          primary: const Color(0xFF0098DA),
          secondary: const Color(0xFF1B4965),
          surface: Colors.white,
          onSurface: const Color(0xFF0B1D2A),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0B1D2A)),
          bodyMedium: TextStyle(color: Color(0xFF0B1D2A)),
          bodySmall: TextStyle(color: Color(0xFF5A5E63)),
          titleLarge: TextStyle(color: Color(0xFF0B1D2A)),
          titleMedium: TextStyle(color: Color(0xFF0B1D2A)),
          titleSmall: TextStyle(color: Color(0xFF0B1D2A)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE6F3FA),
          hintStyle: const TextStyle(color: Color(0xFF5A5E63)),
          labelStyle: const TextStyle(color: Color(0xFF0098DA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5),
          ),
        ),
      ),
      home: _isInitLoading
          ? const SplashScreen()
          : _isLoggedIn
              ? DashboardMainScreen(
                  adminName: _loggedInUser,
                  onLogout: _handleLogout,
                )
              : LoginScreen(
                  onLoginSuccess: _handleLoginSuccess,
                ),
    );
  }
}
