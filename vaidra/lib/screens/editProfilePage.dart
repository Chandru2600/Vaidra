import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'package:vaidra/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _conditionsController;
  late TextEditingController _allergiesController;
  String? _selectedGender;
  bool _isSaving = false;

  static const Color lightTeal = Color(0xFFA8D5BA);
  static const Color mediumTeal = Color(0xFF6BBF8A);
  static const Color darkTeal = Color(0xFF4B9B6E);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _ageController = TextEditingController(text: widget.userData['age']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.userData['address'] ?? '');
    _conditionsController = TextEditingController(text: widget.userData['conditions'] ?? '');
    _allergiesController = TextEditingController(text: widget.userData['allergies'] ?? '');
    _selectedGender = widget.userData['gender'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profileData = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
      };

      await ApiService().updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (context, lang, _) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            lang.translate('edit_profile'),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: lang.translate('name'),
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ageController,
                  label: lang.translate('age'),
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 150) {
                        return 'Please enter a valid age';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildGenderDropdown(lang),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: lang.translate('address'),
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _conditionsController,
                  label: 'Medical Conditions',
                  icon: Icons.medical_services_outlined,
                  maxLines: 2,
                  hint: 'e.g., Diabetes, Hypertension',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _allergiesController,
                  label: 'Allergies',
                  icon: Icons.warning_amber_outlined,
                  maxLines: 2,
                  hint: 'e.g., Peanuts, Penicillin',
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mediumTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            lang.translate('save_changes'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: mediumTeal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightTeal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumTeal, width: 2),
        ),
        filled: true,
        fillColor: lightTeal.withOpacity(0.1),
      ),
    );
  }

  Widget _buildGenderDropdown(LanguageProvider lang) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: lang.translate('gender'),
        prefixIcon: Icon(Icons.person, color: mediumTeal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightTeal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumTeal, width: 2),
        ),
        filled: true,
        fillColor: lightTeal.withOpacity(0.1),
      ),
      items: ['Male', 'Female', 'Other'].map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value);
      },
    );
  }
}
