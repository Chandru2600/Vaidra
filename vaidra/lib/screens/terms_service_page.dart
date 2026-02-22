import 'package:flutter/material.dart';

class TermsServicePage extends StatelessWidget {
  const TermsServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Last updated: February 2026', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 24),
            _buildText(context, 'By using Vaidra, you agree to these Terms of Service. Please read them carefully.'),
            _buildSection(context, '1. Medical Disclaimer', 'Vaidra provides AI-based preliminary medical insights for information purposes ONLY. It is NOT a medical device and should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician.'),
            _buildSection(context, '2. Use of Service', 'You must provide accurate information when using the app. You are responsible for maintaining the confidentiality of your account.'),
            _buildSection(context, '3. Limitation of Liability', 'Vaidra and its creators are not liable for any health decisions made based on the AI analysis results.'),
            _buildSection(context, '4. Changes to Terms', 'We may update these terms occasionally. Your continued use of the app signifies acceptance of any changes.'),
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
