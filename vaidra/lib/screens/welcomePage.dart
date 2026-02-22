import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color lightTeal = Color(0xFFA8D5BA);
  static const Color mediumTeal = Color(0xFF6BBF8A);
  static const Color darkTeal = Color(0xFF4B9B6E);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final themeInstance = Theme.of(context);
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        final isDark = themeInstance.brightness == Brightness.dark;
        if (lang.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFE9F5EF),
            body: Center(child: CircularProgressIndicator(color: darkTeal)),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFE9F5EF),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Top bar without logo ---
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: lightTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: lightTeal, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: lang.currentLanguage,
                                isDense: true,
                                icon: Icon(Icons.keyboard_arrow_down, size: 16, color: darkTeal),
                                style: TextStyle(color: darkTeal, fontSize: 12, fontWeight: FontWeight.w500),
                                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                items: [
                                  DropdownMenuItem(value: 'English', child: Text(lang.translate('english'))),
                                  DropdownMenuItem(value: 'Tamil', child: Text(lang.translate('tamil'))),
                                  DropdownMenuItem(value: 'Hindi', child: Text(lang.translate('hindi'))),
                                ],
                                onChanged: (value) => lang.changeLanguage(value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: Text(lang.translate('login'), style: TextStyle(color: darkTeal, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(lang.translate('Welcome!!'), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ),
                  ),
                  // --- Large logo centered ---
                  Center(
                    child: Container(
                      height: 180,
                      width: 180,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/translations/vaidra.png', // <-- Your logo asset path
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: mediumTeal,
                            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              child: Text(lang.translate('create_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(lang.translate('or'), style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1877F2),
                                side: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              icon: const Icon(Icons.facebook, size: 20),
                              label: Text(lang.translate('continue_facebook'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF1877F2) : const Color(0xFF1877F2))),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: mediumTeal,
                                side: BorderSide(color: mediumTeal, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              icon: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: mediumTeal),
                                child: const Icon(Icons.g_mobiledata, size: 16, color: Colors.white),
                              ),
                              label: Text(lang.translate('continue_google'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : mediumTeal)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        lang.translate('terms'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 12, height: 1.4),
                      ),
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
