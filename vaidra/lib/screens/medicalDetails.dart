import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class MedicalDetailsPage extends StatefulWidget {
  const MedicalDetailsPage({Key? key}) : super(key: key);

  @override
  State<MedicalDetailsPage> createState() => _MedicalDetailsPageState();
}

class _MedicalDetailsPageState extends State<MedicalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();

  String? _selectedGender;
  final List<String> _selectedConditions = [];
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF6B9C7A);
  static const Color lightGreen = Color(0xFFE8F4EA);
  static const Color backgroundColor = Color(0xFFF5F7F5);
  static const Color textDark = Color(0xFF2D3E2D);
  static const Color textLight = Color(0xFF6B7B6B);

  final List<String> _genderOptionsKeys = [
    'male',
    'female',
    'other',
    'prefer_not_say'
  ];

  final List<String> _healthConditions = [
    "Diabetes",
    "High Blood Pressure",
    "Heart Disease",
    "Asthma",
    "Arthritis",
    "High Cholesterol",
    "Thyroid Issues",
    "Kidney Disease",
    "Mental Health",
    "Cancer",
    "Obesity",
    "Other"
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

 void _handleContinue(LanguageProvider lang) async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // ✅ Prevent navigation errors

    setState(() => _isLoading = false);

    Navigator.pushNamed(context, '/location'); // ✅ Make sure this exists in routes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.translate('medical_saved')),
        backgroundColor: primaryGreen,
      ),
    );
  }
}


  String? _validateAge(LanguageProvider lang, String? value) {
    if (value == null || value.isEmpty) {
      return lang.translate('age_required');
    }
    int? age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return lang.translate('age_invalid');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (context, lang, _) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(lang.translate('medical_details'),
              style: const TextStyle(
                  color: textDark, fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.translate('medical_details'),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 8),
                  Text(lang.translate('medical_subtitle'),
                      style:
                          const TextStyle(fontSize: 16, color: textLight)),
                  const SizedBox(height: 40),

                  // Age Field
                  Text(lang.translate('age'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: lang.translate('enter_age'),
                      prefixIcon:
                          const Icon(Icons.cake, color: primaryGreen),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => _validateAge(lang, val),
                  ),
                  const SizedBox(height: 24),

                  // Gender
                  Text(lang.translate('gender'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      children: _genderOptionsKeys.map((key) {
                        return RadioListTile<String>(
                          title: Text(lang.translate(key)),
                          value: key,
                          groupValue: _selectedGender,
                          activeColor: primaryGreen,
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Health Conditions
                  Text(lang.translate('known_health_conditions'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 8),
                  Text(lang.translate('select_all_apply'),
                      style: const TextStyle(
                          fontSize: 14, color: textLight)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _healthConditions.map((condition) {
                        bool isSelected =
                            _selectedConditions.contains(condition);
                        return FilterChip(
                          label: Text(condition),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _toggleCondition(condition);
                          }),
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: lightGreen,
                          checkmarkColor: primaryGreen,
                          labelStyle: TextStyle(
                              color: isSelected ? primaryGreen : textDark),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Allergies
                  Text(lang.translate('allergies'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 8),
                  Text(lang.translate('allergies_hint'),
                      style: const TextStyle(
                          fontSize: 14, color: textLight)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _allergiesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: lang.translate('allergies_examples'),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.warning_amber,
                            color: primaryGreen),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleContinue(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(lang.translate('continue'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip for now
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/location');
                      },
                      child: Text(lang.translate('skip_for_now'),
                          style: const TextStyle(
                              color: textLight,
                              fontSize: 16,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }
}
