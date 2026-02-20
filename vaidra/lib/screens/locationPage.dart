import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class LocationDetailsPage extends StatefulWidget {
  const LocationDetailsPage({Key? key}) : super(key: key);

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isDetectingLocation = false;
  bool _isLoading = false;
  bool _locationDetected = false;
  bool _useManualEntry = false;

  // Color theme matching Vaidra
  static const Color primaryGreen = Color(0xFF6B9C7A);
  static const Color lightGreen = Color(0xFFE8F4EA);
  static const Color darkGreen = Color(0xFF4A7C59);
  static const Color backgroundColor = Color(0xFFF5F7F5);
  static const Color textDark = Color(0xFF2D3E2D);
  static const Color textLight = Color(0xFF6B7B6B);

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation(LanguageProvider lang) async {
    setState(() {
      _isDetectingLocation = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isDetectingLocation = false;
      _locationDetected = true;
      _cityController.text = 'Chennai';
      _stateController.text = 'Tamil Nadu';
      _countryController.text = 'India';
      _pincodeController.text = '600001';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('location_saved')),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  void _handleSaveLocation(LanguageProvider lang) async {
    if (_useManualEntry && !_formKey.currentState!.validate()) return;

    if (!_locationDetected && !_useManualEntry) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('detect_location_or_manual')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('profile_setup_done')),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  void _toggleManualEntry() {
    setState(() {
      _useManualEntry = !_useManualEntry;
      if (_useManualEntry) {
        _locationDetected = false;
        _cityController.clear();
        _stateController.clear();
        _countryController.clear();
        _pincodeController.clear();
      }
    });
  }

  String? _validateField(LanguageProvider lang, String? value, String key) {
    if (value == null || value.trim().isEmpty) {
      return lang.translate(key);
    }
    return null;
  }

  String? _validatePincode(LanguageProvider lang, String? value) {
    if (value == null || value.trim().isEmpty) {
      return lang.translate('pincode_required');
    }
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return lang.translate('pincode_invalid');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/translations/vaidra.png',
                    width: 18,
                    height: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Vaidra', // Brand name static
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(lang.translate('location_details'),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 8),
                  Text(lang.translate('location_subtitle'),
                      style: const TextStyle(fontSize: 16, color: textLight)),
                  const SizedBox(height: 40),

                  // GPS Detection Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _locationDetected
                              ? primaryGreen
                              : Colors.grey.shade300,
                          width: _locationDetected ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _locationDetected
                              ? Icons.check_circle
                              : Icons.gps_fixed,
                          color:
                              _locationDetected ? primaryGreen : textLight,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _locationDetected
                              ? lang.translate('location_detected')
                              : lang.translate('auto_detect_location'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:
                                _locationDetected ? primaryGreen : textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _locationDetected
                              ? lang.translate('location_detected_msg')
                              : lang.translate('allow_gps'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: textLight),
                        ),
                        const SizedBox(height: 16),
                        if (!_locationDetected && !_useManualEntry)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isDetectingLocation
                                  ? null
                                  : () => _detectLocation(lang),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white),
                              icon: _isDetectingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.my_location, size: 20),
                              label: Text(_isDetectingLocation
                                  ? lang.translate('detecting')
                                  : lang.translate('detect_my_location')),
                            ),
                          ),
                        if (_locationDetected)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lightGreen.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_cityController.text}, ${_stateController.text}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textDark),
                                ),
                                Text(
                                  '${_countryController.text} - ${_pincodeController.text}',
                                  style: const TextStyle(
                                      fontSize: 14, color: textLight),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Manual Entry Toggle
                  InkWell(
                    onTap: _toggleManualEntry,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _useManualEntry ? lightGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _useManualEntry
                                ? primaryGreen
                                : Colors.grey.shade300,
                            width: _useManualEntry ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_location_alt,
                              color: _useManualEntry
                                  ? primaryGreen
                                  : textLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lang.translate('enter_location_manually'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _useManualEntry
                                    ? primaryGreen
                                    : textDark,
                              ),
                            ),
                          ),
                          Icon(
                            _useManualEntry
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: _useManualEntry
                                ? primaryGreen
                                : textLight,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Manual Entry Form
                  if (_useManualEntry) ...[
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: '${lang.translate("city_required").replaceAll(" is required", "")} *',
                              prefixIcon: const Icon(Icons.location_city,
                                  color: primaryGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                _validateField(lang, value, 'city_required'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: '${lang.translate("state_required").replaceAll(" is required", "")} *',
                              prefixIcon: const Icon(Icons.map,
                                  color: primaryGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                _validateField(lang, value, 'state_required'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _countryController,
                            decoration: InputDecoration(
                              labelText: '${lang.translate("country_required").replaceAll(" is required", "")} *',
                              prefixIcon: const Icon(Icons.public,
                                  color: primaryGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                _validateField(lang, value, 'country_required'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${lang.translate("pincode_required").replaceAll(" is required", "")} *',
                              prefixIcon: const Icon(Icons.pin_drop,
                                  color: primaryGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                _validatePincode(lang, value),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Complete Setup Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleSaveLocation(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(lang.translate('complete_setup'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      child: Text(lang.translate('skip_continue'),
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
        );
      },
    );
  }
}
