import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'pages/hrd_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Karyawan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      initialRoute: "/",

      routes: {
        "/": (context) => LoginPage(),
        "/login": (context) => LoginPage(),
      },

      // 🟢 Route dinamis untuk HRDPage
      onGenerateRoute: (settings) {
        if (settings.name == "/home") {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HRDPage(user: user),
          );
        }

        return null;
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
