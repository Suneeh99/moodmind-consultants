import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as fo;
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pending_verification_screen.dart';
import 'screens/home/home_screen.dart';

class MoodMindConsultantApp extends StatefulWidget {
  const MoodMindConsultantApp({super.key});

  @override
  State<MoodMindConsultantApp> createState() => _MoodMindConsultantAppState();
}

class _MoodMindConsultantAppState extends State<MoodMindConsultantApp> {
  bool _init = false;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Firebase.initializeApp(options: fo.DefaultFirebaseOptions.currentPlatform);
      setState(() => _init = true);
    } catch (e) {
      setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_err != null) {
      return MaterialApp(home: Scaffold(body: Center(child: Text('Init error: $_err'))));
    }
    if (!_init) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return ChangeNotifierProvider(
      create: (_) => AuthService()..bind(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MoodMind Consultant',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (auth.user == null) return const LoginScreen();
    if (!auth.isVerifiedConsultant) return const PendingVerificationScreen();
    return const HomeScreen();
  }
}
