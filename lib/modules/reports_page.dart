// lib/modules/reports_page.dart
import 'package:flutter/material.dart';
import 'db.dart';

class ReportsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ReportsPage({super.key, required this.user});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loading = true;
  int _patients = 0;
  int _vitals = 0;
  int _tests = 0;
  int _inventory = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final counts = await DBHelper.countsForReports();
      if (!mounted) return;
      setState(() {
        _patients = counts['patients'] ?? 0;
        _vitals = counts['vitals'] ?? 0;
        _tests = counts['tests'] ?? 0;
        _inventory = counts['inventory'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading counts: $e';
        _loading = false;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0F57A3),
      padding: const EdgeInsets.only(top: 20, left: 14, right: 14, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reports', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        Text(widget.user['username'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        if ((widget.user['role'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(widget.user['role'], style: const TextStyle(color: Colors.white70))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF0F57A3),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: const Color(0xFFF6F8FB),
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadCounts, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text('Patients', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('$_patients', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ])),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text('Vitals recorded', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('$_vitals', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ])),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text('Sugar tests', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('$_tests', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ])),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text('Inventory items', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('$_inventory', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ])),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Quick actions', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export CSV (not implemented)'))), icon: const Icon(Icons.download), label: const Text('Export CSV')),
                                  ElevatedButton.icon(onPressed: _loadCounts, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('This report page uses the values provided by DBHelper.countsForReports().'),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
