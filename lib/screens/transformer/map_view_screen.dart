import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'transformer_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final List<Marker> _markers = [];
  String _selectedStatus = "All";
  String _selectedZone = "All";

  // Predefined zones (example: Cameroon regions)
  final List<String> _zones = ["All", "Yaoundé", "Douala", "Bafoussam"];
  final List<String> _statuses = ["All", "Active", "Under Maintenance", "Faulty"];

  @override
  void initState() {
    super.initState();
    _fetchTransformers();
  }

  void _fetchTransformers() async {
    FirebaseFirestore.instance.collection('transformers').get().then((querySnapshot) {
      List<Marker> newMarkers = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        if (_selectedStatus != "All" && data['status'] != _selectedStatus) continue;
        if (_selectedZone != "All" && data['zone'] != _selectedZone) continue;

        newMarkers.add(
          Marker(
            point: LatLng(data['latitude'], data['longitude']),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Navigate to TransformerDetailsScreen with transformer data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransformerDetailsScreen(transformerData: data),
                  ),
                );
              },
              child: Icon(
                Icons.location_on,
                color: _getMarkerColor(data['status']),
                size: 40,
              ),
            ),
          ),
        );
      }
      setState(() => _markers.addAll(newMarkers));
    });
  }

  Color _getMarkerColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "Under Maintenance":
        return Colors.yellow;
      case "Faulty":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _updateFilters() {
    setState(() {
      _markers.clear();
      _fetchTransformers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transformer Map View')),
      body: Column(
        children: [
          // Filter Dropdowns
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _updateFilters();
                  },
                ),
                DropdownButton<String>(
                  value: _selectedZone,
                  items: _zones.map((zone) {
                    return DropdownMenuItem(value: zone, child: Text(zone));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedZone = value!);
                    _updateFilters();
                  },
                ),
              ],
            ),
          ),
          // Map View
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(3.848, 11.502),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// // TransformerDetailsScreen
// class TransformerDetailsScreen extends StatelessWidget {
//   final Map<String, dynamic> transformerData;
//
//   TransformerDetailsScreen({required this.transformerData});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Transformer Details'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('ID: ${transformerData['id']}', style: TextStyle(fontSize: 18)),
//             Text('Capacity: ${transformerData['capacity']}', style: TextStyle(fontSize: 18)),
//             Text('Location: ${transformerData['location']}', style: TextStyle(fontSize: 18)),
//             Text('Status: ${transformerData['status']}', style: TextStyle(fontSize: 18)),
//             Text('Installation Date: ${transformerData['installationDate'].toDate().toString()}', style: TextStyle(fontSize: 18)),
//             Text('Latitude: ${transformerData['latitude']}', style: TextStyle(fontSize: 18)),
//             Text('Longitude: ${transformerData['longitude']}', style: TextStyle(fontSize: 18)),
//           ],
//         ),
//       ),
//     );
//   }
// }
