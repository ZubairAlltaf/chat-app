import 'package:flutter/material.dart';
import 'package:my_chat_app/splashpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

const supabaseUrl = 'https://pnwbhfzicmyetyaugkxd.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBud2JoZnppY215ZXR5YXVna3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4OTcxNTYsImV4cCI6MjA1NTQ3MzE1Nn0.6u_jcJnLXmim9tGa1oFdeC8hON_ZCp9nQ0Pc3aLDYLM'; // your key here

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Chat App',
      theme: appTheme,
      home: SplashPage(),
    );
  }
}
