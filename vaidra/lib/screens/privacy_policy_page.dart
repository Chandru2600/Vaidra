import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Last updated: February 2026', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 24),
            _buildText(context, 'At Vaidra, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal and medical information.'),
            _buildSection(context, '1. Information We Collect', 'We collect information you provide directly to us, such as your profile details and the medical images or reports you upload for analysis.'),
            _buildSection(context, '2. How We Use Your Information', 'We use your information to provide AI-powered insights, improve our health analysis models, and provide customer support.'),
            _buildSection(context, '3. Data Security', 'We implement industry-standard security measures to protect your data from unauthorized access or disclosure.'),
            _buildSection(context, '4. Your Rights', 'You have the right to access, correct, or delete your personal information at any time through the app profile settings.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          _buildText(context, content),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(fontSize: 16, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
    );
  }
}
