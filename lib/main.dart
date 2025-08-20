import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pending_verification_screen.dart';
import 'screens/chat/chat_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ensure native Firebase config is added
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ⬇️ Providers live ABOVE MaterialApp
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..bind()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MoodMind Consultant',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const _RootGate(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const PendingVerificationScreen(),
          '/chats': (_) => const ChatListScreen(),
        },
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const LoginScreen();
    }
    if (!auth.isVerifiedConsultant) {
      return const PendingVerificationScreen();
    }
    return const ChatListScreen();
  }
}
