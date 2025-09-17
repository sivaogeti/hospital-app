// lib/modules/patients_page.dart
import 'package:flutter/material.dart';
import 'patient_new_page.dart';
import 'patient_search_page.dart';
import 'app_header.dart';

class PatientsPage extends StatelessWidget {
  // optional user map, if null we'll show defaults
  final Map<String, dynamic>? user;

  const PatientsPage({super.key, this.user});

  String get _username => (user != null && user!['username'] != null) ? user!['username'].toString() : 'healthagent1';
  String get _role => (user != null && user!['role'] != null) ? user!['role'].toString() : 'Health Agent';

  @override
  Widget build(BuildContext context) {
    final cards = [
      {'title': 'New', 'icon': Icons.person_add_alt_1, 'page': PatientNewPage(user: user)},
      {'title': 'Search', 'icon': Icons.search, 'page': PatientSearchPage(user: user)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // header uses username/role (defaults used when null)
          AppHeader(username: _username, role: _role, onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: cards.map((c) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => c['page'] as Widget));
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(c['icon'] as IconData, size: 44, color: Colors.deepPurple),
                        const SizedBox(height: 12),
                        Text(c['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
