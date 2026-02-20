import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:vaidra/screens/uploadPage.dart';
import 'package:vaidra/screens/welcomePage.dart';
import 'package:vaidra/screens/loginPage.dart';
import 'package:vaidra/screens/homePage.dart';
import 'package:vaidra/screens/profilePage.dart';
import 'package:image_picker/image_picker.dart'; // Add this

class ResultsScreen extends StatelessWidget {
  final XFile imageFile; // Changed from String imagePath
  final String condition;
  final int confidence;
  final String severity;
  final List<dynamic> steps;
  final List<dynamic> warnings;

  ResultsScreen({
    required this.imageFile,
    required this.condition,
    required this.confidence,
    required this.severity,
    required this.steps,
    required this.warnings,
  });

  Future<void> _call(String urlOrPhone) async {
    Uri uri;
    if (urlOrPhone.startsWith("http")) {
      uri = Uri.parse(urlOrPhone);
    } else {
      uri = Uri(scheme: 'tel', path: urlOrPhone);
    }
    
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    }
  }

  Color _sevColor(String s) {
    switch (s) {
      case "Urgent":
        return Colors.red;
      case "Moderate":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("results"))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Column(
                children: [
                  FutureBuilder<dynamic>(
                    future: imageFile.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                      return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                    },
                  ),
                  ListTile(
                    title: Text(condition),
                    subtitle: Text("${tr("confidence")}: $confidence%"),
                    trailing: Chip(
                      label: Text("${tr('severity')}: $severity"),
                      backgroundColor: _sevColor(severity),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text(tr("first_aid")),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.isNotEmpty 
                    ? steps.map((s) => Text("• $s")).toList()
                    : [Text("No specific steps provided. Consult a doctor.")]
                ),
              ),
            ),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                title: Text(
                  tr("watch_signs"),
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warnings.isNotEmpty
                    ? warnings.map((w) => Text("• $w")).toList()
                    : [Text("Monitor for worsening symptoms.")]
                ),
              ),
            ),
            Card(
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.local_hospital, color: Colors.blue.shade900),
                    title: Text(
                      tr("nearby_hospitals"),
                      style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Find hospitals near your location"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade900),
                    onTap: () => _call("https://www.google.com/maps/search/?api=1&query=hospitals+near+me"),
                  ),
                ],
              ),
            ),
            Card(
              color: Colors.red.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.emergency, color: Colors.red.shade900),
                    title: Text(
                      tr("ambulance_numbers"),
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: Text("National Ambulance"),
                    subtitle: Text("102"),
                    trailing: Icon(Icons.call, color: Colors.red),
                    onTap: () => _call("102"),
                  ),
                   ListTile(
                    title: Text("Emergency Response"),
                    subtitle: Text("108"),
                    trailing: Icon(Icons.call, color: Colors.red),
                    onTap: () => _call("108"),
                  ),
                  Divider(),
                  ListTile(
                    title: Text("Find Ambulance Nearby"),
                    trailing: Icon(Icons.map, color: Colors.red),
                    onTap: () => _call("https://www.google.com/maps/search/?api=1&query=ambulance+near+me"),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _call("9999999999"),
              icon: Icon(Icons.phone),
              label: Text(tr("call_doctor")),
            )
          ],
        ),
      ),
    );
  }
}
