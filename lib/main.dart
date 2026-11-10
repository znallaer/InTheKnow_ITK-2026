import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/loading_page.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InTheKnowApp());
}

class InTheKnowApp extends StatelessWidget {
  const InTheKnowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In The Know',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const Duration _minSplash = Duration(milliseconds: 2600);

  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplash, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;

        if (!_splashDone || waiting) {
          return const LoadingPage();
        }

        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Campus Events'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ],
            ),
            body: Center(
              child: Text('Welcome, ${snapshot.data?.email}!'),
            ),
          );
        }

        return const LoginPage();
      },
    );
  }
}