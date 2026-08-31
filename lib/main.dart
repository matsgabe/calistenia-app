import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart'; // Import da tela de login

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gjupbdselwkmolbeocwa.supabase.co',
    publishableKey: 'sb_publishable_PflsWSeJqaS-EhjmlAPCXw_hYWjj9HT',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calistenia App',
      theme: ThemeData.dark(),
      home: const LoginScreen(), // Inicia na tela de Login limpa
    );
  }
}
