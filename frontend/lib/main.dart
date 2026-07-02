import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/socket_provider.dart';
import 'core/theme/theme.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final loggedIn = await authProvider.tryAutoLogin();
    
    if (loggedIn && mounted) {
      final user = authProvider.currentUser!;
      // Initialize socket connection
      socketProvider.connectSocket(user.id, user.username);
      // Initialize socket message/receipt listeners
      chatProvider.initSocketListeners(user.id);
    }

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_rounded, size: 64, color: Color(0xFF00A884)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          // Pass dark mode settings down to Home Screen
          final state = context.findAncestorStateOfType<_MyAppState>();
          return HomeScreen(
            isDarkMode: state?._isDarkMode ?? false,
            onToggleTheme: (val) => state?._toggleTheme(val),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
