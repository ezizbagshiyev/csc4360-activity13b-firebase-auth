import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(AuthApp(service: AuthService()));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Unable to initialize Firebase. Check configuration and restart.',
            ),
          ),
        ),
      ),
    );
  }
}

class AuthApp extends StatelessWidget {
  const AuthApp({super.key, required this.service});
  final AuthService service;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Access',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087e8b)),
      useMaterial3: true,
    ),
    home: StreamBuilder<User?>(
      stream: service.authState,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Session unavailable. Restart and try again.'),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? AccountScreen(service: service)
            : AccountScreen(
                key: ValueKey(snapshot.data!.uid),
                service: service,
                signedIn: true,
              );
      },
    ),
  );
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.service,
    this.signedIn = false,
  });
  final AuthService service;
  final bool signedIn;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      currentPassword = TextEditingController();
  bool register = false, busy = false, needsRecentLogin = false;
  String? feedback;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    currentPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      if (widget.signedIn) {
        if (needsRecentLogin) {
          await widget.service.reauthenticate(currentPassword.text);
        }
        await widget.service.updatePassword(password.text);
        if (mounted) {
          setState(() {
            feedback = 'Password updated. Use your new password next time you sign in.';
            needsRecentLogin = false;
          });
          password.clear();
          currentPassword.clear();
        }
      } else if (register) {
        await widget.service.register(email.text.trim(), password.text);
      } else {
        await widget.service.signIn(email.text.trim(), password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'requires-recent-login') {
            needsRecentLogin = true;
            feedback =
                'Enter your current password below, then verify and retry.';
          } else {
            feedback = authMessage(e.code);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => feedback = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> signOut() async {
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await widget.service.signOut();
    } catch (_) {
      if (mounted) {
        setState(() => feedback = 'Sign-out failed. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.signedIn ? 'Your profile' : 'Campus Access'),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.signedIn
                      ? Icons.verified_user_outlined
                      : Icons.school_outlined,
                  size: 64,
                  color: const Color(0xff087e8b),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.signedIn
                      ? 'You are signed in'
                      : register
                      ? 'Create your account'
                      : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (widget.signedIn) ...[
                  SelectableText(
                    widget.service.currentUser?.email ?? 'Email unavailable',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This profile is available only while authenticated.',
                  ),
                  const Divider(height: 36),
                  Text(
                    'Update password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ] else ...[
                  Text(
                    register
                        ? 'Register to access your protected profile.'
                        : 'Sign in to view your profile securely.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: validateEmail,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: widget.signedIn ? 'New password' : 'Password',
                    helperText: 'At least 6 characters',
                    border: const OutlineInputBorder(),
                  ),
                  validator: validatePassword,
                ),
                if (needsRecentLogin)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      controller: currentPassword,
                      enabled: !busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your current password.'
                          : null,
                    ),
                  ),
                const SizedBox(height: 20),
                if (feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(feedback!, semanticsLabel: feedback),
                  ),
                if (busy) const Center(child: CircularProgressIndicator()),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    widget.signedIn
                        ? (needsRecentLogin
                              ? 'Verify and retry update'
                              : 'Update password')
                        : register
                        ? 'Register'
                        : 'Sign in',
                  ),
                ),
                if (widget.signedIn) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: busy ? null : signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ] else
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              register = !register;
                              feedback = null;
                              password.clear();
                              form.currentState?.reset();
                            });
                          },
                    child: Text(
                      register
                          ? 'Already registered? Sign in'
                          : 'New here? Create account',
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Activity 13B · Firebase Authentication',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
