// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/home_page.dart'; // your home page

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  String _selectedRole = 'Health Agent';
  final List<String> _roles = ['Patient', 'Health Agent', 'Doctor', 'Management'];
  bool _loading = false;

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final username = _idCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final role = _selectedRole;

    final auth = AuthService();
    final userRow = await auth.login(username, pwd, role);
    setState(() => _loading = false);
    if (userRow == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed (invalid user/password/role)')));
      return;
    }

    // success: navigate to home and pass username+role
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(username: username, role: role)));
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use your existing styled card; this is a condensed example:
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // ... logo
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'Username'), validator: (s)=> (s==null || s.isEmpty)?'Enter username':null),
                    TextFormField(controller: _pwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (s)=> (s==null||s.isEmpty)?'Enter password':null),
                    DropdownButtonFormField<String>(value: _selectedRole, items: _roles.map((r)=>DropdownMenuItem(value:r,child:Text(r))).toList(), onChanged: (v)=>setState(()=>_selectedRole=v!)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loading?null:_onSignIn, child: _loading?const CircularProgressIndicator():const Text('Sign In')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
