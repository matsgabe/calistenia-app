import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gjupbdselwkmolbeocwa.supabase.co',
    publishableKey: 'sb_publishable_PflsWSeJqaS-EhjmlAPCXw_hYWjj9HT',
  );

  runApp(const CalisteniaApp());
}

class CalisteniaApp extends StatelessWidget {
  const CalisteniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calistenia App',
      theme: ThemeData.dark(),
      home: const AuthScreen(),
    );
  }
}
