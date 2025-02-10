import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

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

  // Stream to get transformers data
  Stream<List<Map<String, dynamic>>> getTransformers() {
    return FirebaseFirestore.instance
        .collection('transformers')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Stream to get alerts data
  Stream<List<Map<String, dynamic>>> getAlerts() {
    return FirebaseFirestore.instance
        .collection('alerts')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Stream to get maintenance tasks data
  Stream<List<Map<String, dynamic>>> getUpcomingMaintenance() {
    return FirebaseFirestore.instance
        .collection('maintenance_tasks')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          isLoading
              ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Transformers Overview with Pie Chart
            _buildTransformersOverview(),
            SizedBox(height: 16),

            // Alerts Section with Bar Chart
            _buildAlertsSection(),
            SizedBox(height: 16),

            // Upcoming Maintenance Section with Line Chart
            _buildUpcomingMaintenance(),
          ],
        ),
      ),
    );
  }

  // Transformers Overview Widget with Pie Chart
  Widget _buildTransformersOverview() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getTransformers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final transformers = snapshot.data!;
        int activeCount = transformers
            .where((transformer) => transformer['status'] == 'Active')
            .length;
        int underMaintenanceCount = transformers
            .where((transformer) => transformer['status'] == 'Under Maintenance')
            .length;

        // Data for pie chart
        final pieData = [
          PieChartSectionData(
            value: activeCount.toDouble(),
            color: Colors.green,
            title: 'Active: $activeCount',
            radius: 40,
          ),
          PieChartSectionData(
            value: underMaintenanceCount.toDouble(),
            color: Colors.orange,
            title: 'Under Maintenance: $underMaintenanceCount',
            radius: 40,
          ),
        ];

        return Card(
          elevation: 5,
          child: ListTile(
            title: Text('Transformers Overview',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PieChart(
                    PieChartData(
                      sections: pieData,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                    ),
                  ),
                ),
                Text('Active Transformers: $activeCount'),
                Text('Under Maintenance: $underMaintenanceCount'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Alerts Section Widget with Bar Chart
  Widget _buildAlertsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getAlerts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final alerts = snapshot.data!;
        final severityCount = <String, int>{'Low': 0, 'Medium': 0, 'High': 0};

        for (var alert in alerts) {
          String severity = alert['severity'];
          if (severityCount.containsKey(severity)) {
            severityCount[severity] = severityCount[severity]! + 1;
          }
        }

        List<BarChartGroupData> barData = [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: severityCount['Low']!.toDouble(),
                gradient: LinearGradient(colors: [Colors.green]),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: severityCount['Medium']!.toDouble(),
                gradient: LinearGradient(colors: [Colors.orange]),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: severityCount['High']!.toDouble(),
                gradient: LinearGradient(colors: [Colors.red]),
              ),
            ],
          ),
        ];


        return Card(
          elevation: 5,
          child: ListTile(
            title: Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: barData,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                Text('Low Severity: ${severityCount['Low']}'),
                Text('Medium Severity: ${severityCount['Medium']}'),
                Text('High Severity: ${severityCount['High']}'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Upcoming Maintenance Section Widget with Line Chart
  Widget _buildUpcomingMaintenance() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getUpcomingMaintenance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final maintenanceTasks = snapshot.data!;
        final scheduledDates = <DateTime, int>{};

        for (var task in maintenanceTasks) {
          DateTime scheduledDate = (task['scheduled_date'] as Timestamp).toDate();
          scheduledDates[scheduledDate] = (scheduledDates[scheduledDate] ?? 0) + 1;
        }

        final lineData = [
          LineChartBarData(spots: scheduledDates.entries.map((entry) {
            return FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value.toDouble());
          }).toList(), isCurved: true),
        ];

        return Card(
          elevation: 5,
          child: ListTile(
            title: Text('Upcoming Maintenance',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LineChart(
                    LineChartData(lineBarsData: lineData),
                  ),
                ),
                Text('Upcoming Maintenance Count: ${maintenanceTasks.length}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
