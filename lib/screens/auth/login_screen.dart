import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MoodMind Consultant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : () async {
                setState(() { loading = true; error = null; });
                final err = await context.read<AuthService>().signIn(emailC.text.trim(), passC.text.trim());
                if (err != null) setState(() => error = err);
                setState(() => loading = false);
              },
              child: loading ? const SizedBox(height: 16, width:16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('New consultant? Register'),
            )
          ],
        ),
      ),
    );
  }
}
