import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTransformerScreen extends StatefulWidget {
  @override
  _AddTransformerScreenState createState() => _AddTransformerScreenState();
}

class _AddTransformerScreenState extends State<AddTransformerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  DateTime? _installationDate;
  String _status = 'Active';
  String _zone = 'Central';  // Default zone

  // List of regions in Cameroon
  List<String> zones = [
    'Central', 'Littoral', 'West', 'North', 'South', 'Northwest', 'Southwest',
    'East', 'Adamawa', 'Far North'
  ];

  Future<void> _addTransformer() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('transformers').doc(_idController.text).set({
          'id': _idController.text,
          'capacity': _capacityController.text,
          'location': _locationController.text,
          'latitude': double.parse(_latitudeController.text),
          'longitude': double.parse(_longitudeController.text),
          'installationDate': _installationDate ?? DateTime.now(),
          'status': _status,
          'zone': _zone, // Adding the zone attribute
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transformer added successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transformer')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(labelText: 'Transformer ID'),
                validator: (value) => value!.isEmpty ? 'Please enter an ID' : null,
              ),
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(labelText: 'Capacity (kVA)'),
                validator: (value) => value!.isEmpty ? 'Please enter capacity' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Please enter location' : null,
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter valid latitude' : null,
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter valid longitude' : null,
              ),
              ListTile(
                title: Text(
                  _installationDate == null
                      ? 'Select Installation Date'
                      : 'Installed on: ${DateFormat.yMMMd().format(_installationDate!)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _installationDate = pickedDate;
                    });
                  }
                },
              ),
              DropdownButtonFormField(
                value: _status,
                items: ['Active', 'Under Maintenance', 'Faulty'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value.toString();
                  });
                },
                decoration: InputDecoration(labelText: 'Status'),
              ),
              // Dropdown for selecting Zone (Region)
              DropdownButtonFormField(
                value: _zone,
                items: zones.map((zone) {
                  return DropdownMenuItem(value: zone, child: Text(zone));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _zone = value.toString();
                  });
                },
                decoration: InputDecoration(labelText: 'Zone (Region)'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTransformer,
                child: Text('Add Transformer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
