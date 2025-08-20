import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final linkedinC = TextEditingController();
  final qualsC = TextEditingController();

  bool loading = false;
  String? error;

  String? _validateLinkedIn(String input) {
    final v = input.trim();
    if (v.isEmpty) return 'Please enter your LinkedIn URL';
    final lower = v.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return 'LinkedIn URL must start with http:// or https://';
    }
    if (!lower.contains('linkedin.com')) {
      return 'Please provide a valid LinkedIn profile (linkedin.com)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = context.read<AuthService>();
      final name = nameC.text.trim();
      final email = emailC.text.trim();
      final pass = passC.text; // don't trim passwords
      final linkedin = linkedinC.text.trim();
      final quals = qualsC.text.trim();

      if (name.isEmpty) throw Exception('Please enter your full name');
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      if (pass.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }
      final linkedInErr = _validateLinkedIn(linkedin);
      if (linkedInErr != null) throw Exception(linkedInErr);

      final err = await auth
          .registerConsultantWithApplication(
            email: email,
            password: pass,
            displayName: name,
            linkedinUrl: linkedin,
            qualifications: quals,
          )
          .timeout(const Duration(seconds: 30));

      if (err != null && err.isNotEmpty) {
        setState(() => error = err);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted for review')),
      );
    } on TimeoutException {
      setState(
        () => error = 'Request timed out. Check your connection and try again.',
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    linkedinC.dispose();
    qualsC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultant registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameC,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkedinC,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'LinkedIn profile URL',
                hintText: 'https://www.linkedin.com/in/username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qualsC,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                labelText: 'Qualifications',
                hintText:
                    'e.g.\n• MSc in Clinical Psychology, University X\n• 5+ years CBT practice\n• Licensed (Reg#12345)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account & submit application'),
            ),
            const SizedBox(height: 12),
            const Text(
              'An admin will review your application. You can log in, but features stay locked until verified.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
