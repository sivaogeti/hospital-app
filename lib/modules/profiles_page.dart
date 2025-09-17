// lib/modules/profiles_page.dart
import 'package:flutter/material.dart';

class ProfilesPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfilesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profiles'),
        backgroundColor: const Color(0xFF0F57A3),
      ),
      body: Container(
        color: const Color(0xFFF6F8FB),
        child: const Center(child: Text('Health Profiles - placeholder')),
      ),
    );
  }
}
