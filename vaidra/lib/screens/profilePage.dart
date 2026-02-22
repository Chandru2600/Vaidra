import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'package:vaidra/services/api_service.dart';
import 'package:vaidra/screens/editProfilePage.dart';
import 'package:vaidra/providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color lightTeal = Color(0xFFA8D5BA);
  static const Color mediumTeal = Color(0xFF6BBF8A);
  static const Color darkTeal = Color(0xFF4B9B6E);

  // User data from API
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String? _errorMessage;
  int _scanCount = 0;
  
  // Settings toggles
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ApiService().getProfile();
      final scans = await ApiService().fetchRecentScans();
      
      setState(() {
        userData = profile;
        _scanCount = scans.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (context, lang, _) {
      return Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView(lang)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(lang),
                          _buildProfileCard(lang),
                          _buildStatsSection(lang),
                          _buildMenuSections(lang),
                        ],
                      ),
                    ),
        ),
      );
    });
  }

  Widget _buildErrorView(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: mediumTeal),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: lightTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new, size: 20, color: darkTeal),
              ),
            ),
            Text(
              lang.translate('profile'),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(LanguageProvider lang) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mediumTeal, darkTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: mediumTeal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration:
                  const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset('assets/translations/vaidra.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(userData?['name'] ?? 'User',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            if (userData?['age'] != null)
              Text('${lang.translate("age")}: ${userData!['age']}',
                  style:
                      TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 4),
            if (userData?['gender'] != null)
              Text('${lang.translate("gender")}: ${userData!['gender']}',
                  style:
                      TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(userData: userData ?? {}),
                    ),
                  );
                  if (result == true) {
                    _loadProfile(); // Reload profile after edit
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: mediumTeal),
                child: Text(lang.translate('edit_profile'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(LanguageProvider lang) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: lightTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.assignment_outlined, "0",
                lang.translate('appointments')),
            Container(width: 1, height: 40, color: lightTeal.withOpacity(0.3)),
            _buildStatItem(Icons.upload_file, _scanCount.toString(),
                lang.translate('reports_uploaded')),
            Container(width: 1, height: 40, color: lightTeal.withOpacity(0.3)),
            _buildStatItem(Icons.favorite, "85%",
                lang.translate('wellness_score')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: mediumTeal, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? lightTeal : darkTeal)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMenuSections(LanguageProvider lang) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _buildSectionTitle(lang.translate('personal_info')),
            _buildMenuCard([
              _buildMenuItem(Icons.person_outline, lang.translate('name'),
                  userData?['name']),
              _buildMenuItem(
                  Icons.email_outlined, lang.translate('email'), userData?['email']),
              if (userData?['age'] != null)
                _buildMenuItem(Icons.cake, lang.translate('age'), userData!['age'].toString()),
              if (userData?['gender'] != null)
                _buildMenuItem(
                    Icons.person, lang.translate('gender'), userData!['gender']),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle(lang.translate('settings')),
            _buildMenuCard([
              _buildMenuItem(
                Icons.notifications_outlined,
                lang.translate('notifications'),
                null,
                hasSwitch: true,
                switchValue: _notificationsEnabled,
                onSwitchChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildMenuItem(
                    Icons.dark_mode_outlined,
                    lang.translate('dark_mode'),
                    null,
                    hasSwitch: true,
                    switchValue: themeProvider.isDarkMode,
                    onSwitchChanged: (value) {
                      themeProvider.setDarkMode(value);
                    },
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildMenuCard([
              _buildMenuItem(Icons.help_outline, lang.translate('help_support'),
                  null,
                  hasArrow: true,
                  onTap: () => Navigator.pushNamed(context, '/help')),
              _buildMenuItem(Icons.privacy_tip_outlined,
                  lang.translate('privacy_policy'), null,
                  hasArrow: true,
                  onTap: () => Navigator.pushNamed(context, '/privacy')),
              _buildMenuItem(Icons.description_outlined,
                  lang.translate('terms_service'), null,
                  hasArrow: true,
                  onTap: () => Navigator.pushNamed(context, '/terms')),
            ]),
            OutlinedButton(
  onPressed: () {
    // 🔹 Add any session / token clear logic here if needed
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/', // Route name for WelcomePage
      (route) => false, // Remove all previous routes
    );
  },
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.green,
    side: const BorderSide(color: Colors.green, width: 1.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.logout, size: 20, color: Colors.green),
      const SizedBox(width: 10),
      Text(
        lang.translate('logout'),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
    ],
  ),
),

          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)));

  Widget _buildMenuCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children));
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String? value, {
    bool hasArrow = false,
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasSwitch ? null : onTap ?? () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: lightTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: mediumTeal)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    if (value != null) ...[
                      const SizedBox(height: 4),
                      Text(value,
                          style: TextStyle(
                              fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600])),
                    ]
                  ]),
            ),
            if (hasArrow)
              Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white54 : Colors.grey),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: mediumTeal,
              ),
          ]),
        ),
      ),
    );
  }
}
