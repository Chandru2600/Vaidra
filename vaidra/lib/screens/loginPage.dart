import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaidra/screens/language_provider.dart';
import '../services/api_service.dart';

const Color kBgLight = Color(0xFFE9F5EF);
const Color kCardWhite = Colors.white;
const Color kAccentGreen = Color(0xFF2E7D5C);

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String emailOrPhone = '';
  String password = '';
  bool isLoading = false;
  bool obscure = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final response = await ApiService().login(emailOrPhone, password);
      
      if (mounted) {
        setState(() => isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: kBgLight,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                  decoration: BoxDecoration(
                    color: kCardWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 28.0),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/translations/vaidra.png',
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          lang.translate('login'),
                          style: TextStyle(
                            color: kAccentGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: lang.translate('email_or_phone'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: Icon(Icons.person),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              (value == null || value.isEmpty) ? lang.translate('required') : null,
                          onChanged: (val) => emailOrPhone = val,
                        ),
                        SizedBox(height: 18),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: lang.translate('password'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                            ),
                          ),
                          obscureText: obscure,
                          validator: (value) =>
                              (value == null || value.isEmpty) ? lang.translate('required') : null,
                          onChanged: (val) => password = val,
                        ),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: kAccentGreen,
                            ),
                            child: Text(lang.translate('forgot_password')),
                          ),
                        ),
                        SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: isLoading ? null : _login,
                            child: isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    lang.translate('login'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang.translate('new_user') + " ",
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                lang.translate('register'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: kAccentGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
