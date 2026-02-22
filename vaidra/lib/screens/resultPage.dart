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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(title: Text(tr("results"))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: isDark ? const Color(0xFF1E1E1E) : null,
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
                    title: Text(condition, style: TextStyle(color: isDark ? Colors.white : null)),
                    subtitle: Text("${tr("confidence")}: $confidence%", style: TextStyle(color: isDark ? Colors.white70 : null)),
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
              color: isDark ? const Color(0xFF1E1E1E) : null,
              child: ListTile(
                title: Text(tr("first_aid"), style: TextStyle(color: isDark ? Colors.white : null)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.isNotEmpty 
                    ? steps.map((s) => Text("• $s", style: TextStyle(color: isDark ? Colors.white70 : null))).toList()
                    : [Text("No specific steps provided. Consult a doctor.", style: TextStyle(color: isDark ? Colors.white70 : null))]
                ),
              ),
            ),
            Card(
              color: isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
              child: ListTile(
                title: Text(
                  tr("watch_signs"),
                  style: TextStyle(color: isDark ? Colors.redAccent : Colors.red),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warnings.isNotEmpty
                    ? warnings.map((w) => Text("• $w", style: TextStyle(color: isDark ? Colors.white70 : null))).toList()
                    : [Text("Monitor for worsening symptoms.", style: TextStyle(color: isDark ? Colors.white70 : null))]
                ),
              ),
            ),
            Card(
              color: isDark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.local_hospital, color: isDark ? Colors.blueAccent : Colors.blue.shade900),
                    title: Text(
                      tr("nearby_hospitals"),
                      style: TextStyle(color: isDark ? Colors.blueAccent : Colors.blue.shade900, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Find hospitals near your location", style: TextStyle(color: isDark ? Colors.white70 : null)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.blueAccent : Colors.blue.shade900),
                    onTap: () => _call("https://www.google.com/maps/search/?api=1&query=hospitals+near+me"),
                  ),
                ],
              ),
            ),
            Card(
              color: isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.emergency, color: isDark ? Colors.redAccent : Colors.red.shade900),
                    title: Text(
                      tr("ambulance_numbers"),
                      style: TextStyle(color: isDark ? Colors.redAccent : Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: Text("National Ambulance", style: TextStyle(color: isDark ? Colors.white : null)),
                    subtitle: Text("102", style: TextStyle(color: isDark ? Colors.white70 : null)),
                    trailing: Icon(Icons.call, color: isDark ? Colors.redAccent : Colors.red),
                    onTap: () => _call("102"),
                  ),
                   ListTile(
                    title: Text("Emergency Response", style: TextStyle(color: isDark ? Colors.white : null)),
                    subtitle: Text("108", style: TextStyle(color: isDark ? Colors.white70 : null)),
                    trailing: Icon(Icons.call, color: isDark ? Colors.redAccent : Colors.red),
                    onTap: () => _call("108"),
                  ),
                  Divider(color: isDark ? Colors.white24 : null),
                  ListTile(
                    title: Text("Find Ambulance Nearby", style: TextStyle(color: isDark ? Colors.white : null)),
                    trailing: Icon(Icons.map, color: isDark ? Colors.redAccent : Colors.red),
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
