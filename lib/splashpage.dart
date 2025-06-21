import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registerpage.dart';
import 'user_list_page.dart';
import 'constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);

    final session = supabase.auth.currentSession;
    if (session == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          RegisterPage.route(),
              (route) => false,
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => UserListPage()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}