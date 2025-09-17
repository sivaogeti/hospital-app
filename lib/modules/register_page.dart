import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String _role = 'Patient';
  final _roles = ['Patient', 'Health Agent', 'Doctor', 'Management'];

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await AuthService.register(_idCtrl.text.trim(), _pwdCtrl.text.trim(), _role);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User already exists')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'Username')),
            TextFormField(controller: _pwdCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            DropdownButtonFormField(value: _role, items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _role = v!)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _onRegister, child: const Text('Create Account')),
          ]),
        ),
      ),
    );
  }
}
