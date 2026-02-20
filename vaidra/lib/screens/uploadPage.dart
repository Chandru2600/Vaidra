import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vaidra/screens/resultPage.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _image;
  final picker = ImagePicker();

  Future _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("upload_photo".tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _image != null
              ? FutureBuilder<dynamic>(
                  future: _image!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, height: 200);
                    }
                    return CircularProgressIndicator();
                  },
                )
              : Placeholder(fallbackHeight: 200),
          SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: Icon(Icons.camera_alt),
              label: Text("take_photo".tr())),
          ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library),
              label: Text("upload_photo".tr())),
          SizedBox(height: 20),
          if (_image != null)
            ElevatedButton(
                onPressed: () async {
                  try {
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analyzing...")));
                    
                    // Upload
                    final res = await ApiService().uploadScan(_image!, null);
                    final result = res['result'];

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ResultsScreen(
                                imageFile: _image!,
                                condition: result['condition'] ?? "Unknown",
                                confidence: (result['confidence'] ?? 0).toInt(),
                                severity: result['severity'] ?? "Minor",
                                steps: result['steps'] ?? [],
                                warnings: result['warnings'] ?? [],
                            )));
                  } catch (e) {
                      String errorMessage = e.toString();
                      if (errorMessage.contains("429")) {
                        errorMessage = "Server busy (Rate Limit). Please wait a moment.";
                      } else if (errorMessage.contains("500")) {
                        errorMessage = "Server error. Please try again.";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                  }
                },
                child: Text("See Results"))
        ]),
      ),
    );
  }
}

class NearbyFacility {
  final String name;
  final String phone;
  NearbyFacility({required this.name, required this.phone});
}
