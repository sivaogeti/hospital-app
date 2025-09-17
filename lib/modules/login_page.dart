// lib/modules/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String _role = 'Patient';
  final _roles = ['Patient', 'Health Agent', 'Doctor', 'Management'];
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final username = _idCtrl.text.trim();
      final password = _pwdCtrl.text;
      final role = _role;

      // Use the AuthService (registered in ../services/auth_service.dart)
      final userRow = await AuthService.login(username, password, role);

      if (!mounted) return;
      setState(() => _loading = false);

      if (userRow != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: {
            'username': userRow['username'],
            'role': userRow['role'],
            'name': userRow['name'],
          })),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid username / password / role')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF0F57A3),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/hospital_logo.jpg',
                      height: 100,
                      cacheWidth: (width * 0.6).round().clamp(200, 720),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Login card (constrained for large screens)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width > 420 ? 420 : width * 0.92),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),
                            const Text('Login ID (User ID)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _idCtrl,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                              ),
                              validator: (s) => (s == null || s.isEmpty) ? 'Please enter login id' : null,
                            ),
                            const SizedBox(height: 12),

                            const Text('Password', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pwdCtrl,
                              obscureText: true,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                              ),
                              validator: (s) => (s == null || s.isEmpty) ? 'Please enter password' : null,
                            ),

                            const SizedBox(height: 12),
                            const Text('Role', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _role,
                                  isExpanded: true,
                                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _role = v);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: _loading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Register')),
                                TextButton(onPressed: () {}, child: const Text('Forgot password?')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}