import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6BBF8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'Frequently Asked Questions', [
              _buildFAQItem(context, 'How does Vaidra work?', 'Vaidra uses advanced AI to analyze medical images and reports to provide preliminary insights and health guidance.'),
              _buildFAQItem(context, 'Is my data secure?', 'Yes, we take privacy seriously. Your medical data is encrypted and handled according to strict safety standards.'),
              _buildFAQItem(context, 'Can I use this for diagnosis?', 'Vaidra is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.'),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Contact Us', [
              _buildContactItem(context, Icons.email_outlined, 'Email Support', 'support@vaidra.com'),
              _buildContactItem(context, Icons.language_outlined, 'Website', 'www.vaidra.com'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF6BBF8A))),
          const SizedBox(height: 8),
          Text(answer, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6BBF8A), size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
