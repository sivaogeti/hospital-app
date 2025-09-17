// lib/modules/record_vitals_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db.dart'; // make sure this path matches your project (lib/modules/db.dart)

class RecordVitalsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const RecordVitalsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<RecordVitalsPage> createState() => _RecordVitalsPageState();
}

class _RecordVitalsPageState extends State<RecordVitalsPage> {
  // PUBLIC getters for convenience (so rest of file can reference username/role)
  String get username => widget.user['username']?.toString() ?? '';
  String get role => widget.user['role']?.toString() ?? '';

  // Loading / error state
  bool _loading = false;
  String? _error;

  // Patients and villages loaded from DB
  List<Map<String, dynamic>> _patients = [];
  List<String> _villages = [];

  // Selected patient and village
  int? _selectedPatientId;
  String _selectedVillage = 'All';

  // Form controllers and keys
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _resultCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _historyCtrl = TextEditingController();
  final TextEditingController _symptomsCtrl = TextEditingController();
  final TextEditingController _lastMealCtrl = TextEditingController();
  final TextEditingController _followupCtrl = TextEditingController();

  String _selectedTest = 'RBS';
  final List<String> _testTypes = ['RBS', 'FBS', 'PPBS', 'HbA1c'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // set a default last meal hint
    _lastMealCtrl.text = '';
  }

  @override
  void dispose() {
    _resultCtrl.dispose();
    _notesCtrl.dispose();
    _historyCtrl.dispose();
    _symptomsCtrl.dispose();
    _lastMealCtrl.dispose();
    _followupCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load patients
      List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      try {
        final r = await DBHelper.getAllPatients();
        // normalize to List<Map<String,dynamic>>
        rows = (r is List) ? List<Map<String, dynamic>>.from(r) : <Map<String, dynamic>>[];
      } catch (e) {
        // If helper doesn't exist, rethrow so outer catch shows error
        rethrow;
      }

      // Load villages from patients (unique)
      final villages = <String>{'All'};
      for (final p in rows) {
        final v = (p['village'] ?? '').toString().trim();
        if (v.isNotEmpty) villages.add(v);
      }

      if (!mounted) return;
      setState(() {
        _patients = rows;
        _villages = villages.toList();
        // default selected patient if available
        _selectedPatientId = _patients.isNotEmpty ? ( _patients.first['id'] as int? ?? int.tryParse('${_patients.first['id']}') ) : null;
        _selectedVillage = _villages.isNotEmpty ? _villages.first : 'All';
        _loading = false;
      });
    } catch (e, st) {
      // Show helpful error message (DB schema mismatch etc)
      // ignore: avoid_print
      print('Error loading initial data: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load patients: $e';
      });
    }
  }

  // Helper to get patient display string
  String _patientLabel(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? '?';
    final name = (p['name'] ?? 'Unknown').toString();
    final gender = (p['gender'] ?? '').toString();
    final village = (p['village'] ?? '').toString();
    final genderTag = gender.isNotEmpty ? ' ($gender)' : '';
    final villageTag = village.isNotEmpty ? ' — $village' : '';
    return '#$id · $name$genderTag$villageTag';
  }

  Future<void> _saveVitals() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a patient first')));
      return;
    }

    double parsedResult = 0.0;
    try {
      parsedResult = double.parse(_resultCtrl.text.trim());
    } catch (_) {
      parsedResult = 0.0;
    }

    final nowIso = DateTime.now().toIso8601String();

    final values = <String, dynamic>{
      'patient_id': _selectedPatientId,
      'test_type': _selectedTest,
      'result': parsedResult,
      'history': _historyCtrl.text.trim(),
      'symptoms': _symptomsCtrl.text.trim(),
      'last_meal': _lastMealCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'recorded_by': username,
      'created_at': nowIso,
    };

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // insert into DB using DBHelper
      if (!mounted) return;
      await DBHelper.insertVitals(values);
      // success feedback
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved sugar test')));
      // clear a few fields but keep patient selected
      _resultCtrl.text = '';
      _notesCtrl.text = '';
      _historyCtrl.text = '';
      _symptomsCtrl.text = '';
      _lastMealCtrl.text = '';
      _followupCtrl.text = '';
    } catch (e, st) {
      // ignore: avoid_print
      print('Failed to save vitals: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to save: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  // builds top header (blue background with username & role), matches home page
  Widget _topHeader() {
    return Container(
      color: const Color(0xFF0F57A3),
      padding: const EdgeInsets.only(top: 8, left: 14, right: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('Sugar Blood Test', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(role, style: const TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 8),
          // small logos row (centered)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 260,
                height: 40,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.asset('assets/images/hospital_logo.jpg', height: 36, fit: BoxFit.contain),
                      // you can add more small logos if needed
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Village selector
            const Text('Village (filter patients)', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedVillage,
              items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedVillage = v;
                  // if village changed, filter selected patient to first in that village
                  if (v != 'All') {
                    final match = _patients.firstWhere(
                      (p) => (p['village'] ?? '').toString() == v,
                      orElse: () => <String, dynamic>{},
                    );
                    _selectedPatientId = match['id'] as int?;
                  } else {
                    // All -> keep current selection if still present
                    if (_patients.isNotEmpty && !_patients.any((p) => p['id'] == _selectedPatientId)) {
                      _selectedPatientId = _patients.first['id'] as int?;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            // Patient selector (filtered by village)
            const Text('Patient', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedPatientId,
              items: _patients
                  .where((p) => _selectedVillage == 'All' || (p['village'] ?? '').toString() == _selectedVillage)
                  .map((p) {
                final id = p['id'] is int ? p['id'] as int : int.tryParse('${p['id']}') ?? 0;
                return DropdownMenuItem<int>(value: id, child: Text(_patientLabel(p)));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedPatientId = v;
                });
              },
              validator: (v) => v == null ? 'Select patient' : null,
            ),
            const SizedBox(height: 12),

            // Row: Test type + result
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Test Type *', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTest,
                      items: _testTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedTest = v ?? _selectedTest),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Result (mg/dL or % for HbA1c)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _resultCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (s) {
                        if (s == null || s.trim().isEmpty) return 'Enter result';
                        final v = double.tryParse(s.trim());
                        if (v == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // History & symptoms in two-column layout
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Any history', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _historyCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Known diabetes, on medication, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Any other symptoms', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _symptomsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Polyuria, polydipsia, weight loss, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Last meal time + follow-up days
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Last meal time *', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastMealCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g., 2 hours ago, 07:30 AM',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (s) => (s == null || s.trim().isEmpty) ? 'Enter last meal time' : null,
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Follow-up (in days)', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _followupCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 30',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Notes
            const Text('Notes', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Anything else to add…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            const SizedBox(height: 18),

            // Save button row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveVitals,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Test', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            // clear the form
                            _resultCtrl.text = '';
                            _notesCtrl.text = '';
                            _historyCtrl.text = '';
                            _symptomsCtrl.text = '';
                            _lastMealCtrl.text = '';
                            _followupCtrl.text = '';
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared')));
                          },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use SafeArea to preserve top blue header look across pages
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Sugar Blood Test'),
        backgroundColor: const Color(0xFF0F57A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // top header matches home page (blue band)
          _topHeader(),
          // page content area
          Expanded(
            child: Container(
              color: const Color(0xFFF6F8FB),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _bodyContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
