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

  final Map<String, LatLng> _zoneCoordinates = {
    "All": LatLng(3.848, 11.502),
    "Central": LatLng(3.848, 11.502),
    "Littoral": LatLng(4.050, 9.767),
    "West": LatLng(5.500, 10.417),
    "North": LatLng(8.500, 13.667),
    "South": LatLng(2.833, 11.167),
    "Northwest": LatLng(6.000, 10.500),
    "Southwest": LatLng(4.583, 9.367),
    "East": LatLng(4.250, 14.167),
    "Adamawa": LatLng(7.500, 13.500),
    "Far North": LatLng(10.500, 14.250),
  };

  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
      _mapController.move(_zoneCoordinates[_selectedZone]!, 13.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transformer Map View')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: ["All", "Active", "Under Maintenance", "Faulty"].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _updateFilters();
                  },
                ),
                DropdownButton<String>(
                  value: _selectedZone,
                  items: _zoneCoordinates.keys.map((zone) {
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
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _zoneCoordinates["All"]!,
                initialZoom: 13.0,
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
