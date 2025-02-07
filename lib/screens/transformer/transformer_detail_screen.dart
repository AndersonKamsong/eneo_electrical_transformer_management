import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransformerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transformerData;

  const TransformerDetailsScreen({Key? key, required this.transformerData}) : super(key: key);

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transformer Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity: ${transformerData['capacity']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Location: ${transformerData['location']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Latitude: ${transformerData['latitude']}', style: TextStyle(fontSize: 16)),
            Text('Longitude: ${transformerData['longitude']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Status: ${transformerData['status']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text(
              'Installation Date: ${DateFormat.yMMMd().format((transformerData['installationDate'] as Timestamp).toDate())}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(transformerData['latitude'], transformerData['longitude']),
                icon: Icon(Icons.map),
                label: Text('Open in Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
