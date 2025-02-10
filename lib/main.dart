import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart'; // Import your AuthService class
import 'screens/auth/login_screen.dart'; // Import login screen
import 'screens/home_screen.dart'; // Import your HomePage
import 'screens/auth/profile_screen.dart'; // Import your ProfilePage
import 'screens/auth/update_password_screen.dart'; // Import your UpdatePasswordPage
import 'screens/transformer/transformer_screens.dart';
import 'screens/transformer/map_view_screen.dart';
import 'screens/maintenance_task/maintenance_list_screen.dart';
import 'screens/reporting/fault_report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eneo Transformer Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfilePage(),
        '/updatePassword': (context) => UpdatePasswordPage(),
        '/transformer': (context) => TransformerManagementScreen(),
        '/map': (context) => MapViewScreen(),
        '/task': (context) => MaintenanceListScreen(),
        '/reporting': (context) => FaultReportingScreen(),
      },
    );
  }
}
