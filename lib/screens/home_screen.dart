import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'auth/profile_screen.dart';
import 'auth/update_password_screen.dart';
import 'transformer/transformer_screens.dart';
import 'transformer/map_view_screen.dart';
import 'maintenance_task/maintenance_list_screen.dart';
import 'reporting/fault_report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  int _selectedIndex = 0;

  void logout() async {
    setState(() => isLoading = true);
    await authService.signOut();
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  final List<Widget> _screens = [
    HomeContent(),
    TransformerManagementScreen(),
    MapViewScreen(),
    MaintenanceListScreen(),
    FaultReportingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eneo Transformer Management"),
        actions: [
          StreamBuilder<User?>(
            stream: AuthService().user,  // Listen to auth state
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                // Check the role of the authenticated user
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (roleSnapshot.hasError) {
                      return const Center(child: Text('Error loading role'));
                    }

                    // final userRole = roleSnapshot.data!['role'] ?? 'user';

                    // if (userRole == 'admin') {
                      return IconButton(
                        icon: const Icon(Icons.dashboard),
                        onPressed: () {
                            Navigator.pushNamed(context, '/admin');
                          },
                      );
                    // } else {
                    //   return SizedBox.shrink();  // No icon for regular users
                    // }
                  },
                );
              } else {
                return TextButton(
                  child: const Text("Login", style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                );
              }
            },
          ),
          // Logout button visible when user is authenticated
          StreamBuilder<User?>(
            stream: AuthService().user,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: logout,
                  );
              } else {
                return SizedBox.shrink();  // No logout button for unauthenticated users
              }
            },
          ),
          // isLoading
          //     ? const Padding(
          //   padding: EdgeInsets.all(10.0),
          //   child: CircularProgressIndicator(color: Colors.white),
          // )
          //     :
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: logout,
          // ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.electric_bolt), label: 'Transformers'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Reports'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  Stream<List<Map<String, dynamic>>> getTransformers() {
    return FirebaseFirestore.instance
        .collection('transformers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  Stream<List<Map<String, dynamic>>> getAlerts() {
    return FirebaseFirestore.instance
        .collection('alerts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  Stream<List<Map<String, dynamic>>> getUpcomingMaintenance() {
    return FirebaseFirestore.instance
        .collection('maintenance_tasks')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTransformersOverview(),
          SizedBox(height: 16),
          _buildAlertsSection(),
          SizedBox(height: 16),
          _buildUpcomingMaintenance(),
        ],
      ),
    );
  }

  Widget _buildTransformersOverview() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getTransformers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final transformers = snapshot.data!;
        int activeCount = transformers.where((t) => t['status'] == 'Active').length;
        int underMaintenanceCount = transformers.where((t) => t['status'] == 'Under Maintenance').length;
        return Card(
          elevation: 5,
          child: ListTile(
            title: Text('Transformers Overview', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Transformers: $activeCount'),
                Text('Under Maintenance: $underMaintenanceCount'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getAlerts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final alerts = snapshot.data!;
        return alerts.isEmpty
            ? Center(child: Text('No alerts'))
            : Card(
          elevation: 5,
          child: Column(
            children: alerts.map((alert) {
              return ListTile(
                title: Text('Alert: ${alert['description']}'),
                subtitle: Text('Severity: ${alert['severity']}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingMaintenance() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getUpcomingMaintenance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final maintenanceTasks = snapshot.data!;
        return maintenanceTasks.isEmpty
            ? Center(child: Text('No upcoming maintenance'))
            : Card(
          elevation: 5,
          child: Column(
            children: maintenanceTasks.map((task) {
              final transformerId = task['transformer_id'];
              final scheduledDate = (task['scheduled_date'] as Timestamp).toDate();
              return ListTile(
                title: Text('Transformer: $transformerId'),
                subtitle: Text('Scheduled: ${scheduledDate.toString()}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
