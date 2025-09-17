// lib/modules/patient_search_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'db.dart';
import 'app_header.dart';

class PatientSearchPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const PatientSearchPage({super.key, this.user});

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final rows = await DBHelper.getAllPatients();
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.user != null && widget.user!['username'] != null) ? widget.user!['username'].toString() : 'healthagent1';
    final role = (widget.user != null && widget.user!['role'] != null) ? widget.user!['role'].toString() : 'Health Agent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        AppHeader(username: username, role: role, onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPatients,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (ctx, i) {
                final r = _rows[i];
                return Card(
                  child: ListTile(
                    leading: (r['photo_path'] != null && (r['photo_path'] as String).isNotEmpty) ? CircleAvatar(backgroundImage: FileImage(File(r['photo_path']))) : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(r['name'] ?? ''),
                    subtitle: Text('${r['age'] ?? ''} • ${r['village'] ?? ''}'),
                    trailing: Text(r['mobile'] ?? ''),
                    onTap: () {
                      showDialog(context: context, builder: (_) => AlertDialog(title: Text(r['name'] ?? ''), content: Text('Aadhar: ${r['aadhar'] ?? ''}\nPhone: ${r['phone'] ?? ''}\nVillage: ${r['village'] ?? ''}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
