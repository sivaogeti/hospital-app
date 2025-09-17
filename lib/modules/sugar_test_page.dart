// lib/modules/sugar_test_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'db.dart'; // make sure this path matches your project

class SugarTestPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? username;

  const SugarTestPage({Key? key, this.user, this.username}) : super(key: key);

  @override
  State<SugarTestPage> createState() => _SugarTestPageState();
}

class _SugarTestPageState extends State<SugarTestPage> {
  // --- form state ---
  final _formKey = GlobalKey<FormState>();

  int? _selectedPatientId;
  String? _selectedPatientName;
  String _testType = 'RBS'; // RBS | FBS | PPBS | HbA1c
  double _result = 0;
  String _lastMeal = '';
  String _history = '';
  String _symptoms = '';
  String _notes = '';
  int _followupDays = 0;

  // --- lists / loading ---
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _recent = [];

  // selection for bulk actions (if needed later)
  final Set<int> _selectedRows = {};

  String get _username =>
      (widget.user != null && widget.user!['username'] != null && (widget.user!['username'] as String).isNotEmpty)
          ? (widget.user!['username'] as String)
          : (widget.username ?? 'unknown');

  @override
  void initState() {
    super.initState();
    _loadPatientsSafely();
    _loadRecentSafely();
  }

  /// Defensive loader: catches DB errors and ensures consistent UI state
  Future<void> _loadPatientsSafely() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Pull only columns we show in the dropdown for speed & safety
      final db = await DBHelper.database;
      final rows = await db.rawQuery(
        'SELECT id, name, IFNULL(age, 0) AS age, IFNULL(gender, "") AS gender, IFNULL(village, "") AS village '
        'FROM patients ORDER BY name COLLATE NOCASE',
      );
      if (!mounted) return;
      setState(() {
        _patients = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load patients: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadRecentSafely() async {
    try {
      final recent = await DBHelper.getRecentSugarTests(limit: 50);
      if (!mounted) return;
      setState(() => _recent = recent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load recent tests: $e');
    }
  }

  // --- helpers -------------------------------------------------------------

  void _onPatientChanged(Map<String, dynamic>? row) {
    setState(() {
      _selectedPatientId = row?['id'] as int?;
      _selectedPatientName = row?['name'] as String?;
    });
  }

  String _patientDisplay(Map<String, dynamic> p) {
    final age = p['age'] ?? '';
    final gender = (p['gender'] ?? '').toString();
    final village = (p['village'] ?? '').toString();
    final parts = [
      '#${p['id']} · ${p['name']}',
      if (gender.isNotEmpty || (age is int && age > 0)) '(${gender.isNotEmpty ? gender : ''}${gender.isNotEmpty && (age is int && age > 0) ? ', ' : ''}${(age is int && age > 0) ? '$age yrs' : ''})',
      if (village.isNotEmpty) '— $village',
    ];
    return parts.join(' ');
  }

  bool get _canSave =>
      _selectedPatientId != null &&
      _result > 0 &&
      _lastMeal.trim().isNotEmpty &&
      !_loading;

  Future<void> _save() async {
    if (!_canSave) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final values = <String, dynamic>{
        'fk_patient_id': _selectedPatientId,
        'test_type': _testType, // RBS | FBS | PPBS | HbA1c
        'history': _history.trim().isEmpty ? null : _history.trim(),
        'symptoms': _symptoms.trim().isEmpty ? null : _symptoms.trim(),
        'last_meal_time': _lastMeal.trim(),
        'notes': _notes.trim().isEmpty ? null : _notes.trim(),
        'followup_days': _followupDays,
        'recorded_by': _username,
      };

      // map result into the right column based on test type
      switch (_testType) {
        case 'RBS':
          values['random'] = _result.round();
          break;
        case 'FBS':
          values['fasting'] = _result.round();
          break;
        case 'PPBS':
          values['pp'] = _result.round();
          break;
        case 'HbA1c':
          values['hba1c'] = _result;
          break;
      }

      await DBHelper.insertBloodSugar(values);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sugar test saved')),
      );

      // reset minimal fields
      setState(() {
        _testType = 'RBS';
        _result = 0;
        _lastMeal = '';
        _history = '';
        _symptoms = '';
        _notes = '';
        _followupDays = 0;
      });

      await _loadRecentSafely();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- UI -----------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0F57A3),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Sugar Blood Test',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Record blood sugar results for a patient.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _patients.isEmpty && (_recent.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(),
        Container(
          color: const Color(0xFFF6F8FB),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildPatientPickerCard(),
              const SizedBox(height: 12),
              _buildFormCard(),
              const SizedBox(height: 12),
              _buildRecentCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientPickerCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Patient', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedPatientId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose patient',
              ),
              items: _patients
                  .map((p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(_patientDisplay(p)),
                      ))
                  .toList(),
              onChanged: (id) {
                final row = _patients.firstWhere((p) => p['id'] == id, orElse: () => {});
                _onPatientChanged(row.isEmpty ? null : row);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // test type + result
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _testType,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Test type *', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'RBS', child: Text('RBS (Random)')),
                        DropdownMenuItem(value: 'FBS', child: Text('FBS (Fasting)')),
                        DropdownMenuItem(value: 'PPBS', child: Text('PPBS (Postprandial)')),
                        DropdownMenuItem(value: 'HbA1c', child: Text('HbA1c')),
                      ],
                      onChanged: (v) => setState(() => _testType = v ?? 'RBS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _result == 0 ? '' : _result.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Result *',
                        hintText: 'mg/dL or % for HbA1c',
                        border: OutlineInputBorder(),
                      ),
                      validator: (t) {
                        final v = double.tryParse((t ?? '').trim()) ?? 0;
                        if (v <= 0) return 'Enter a value > 0';
                        return null;
                      },
                      onChanged: (t) => _result = double.tryParse(t.trim()) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // last meal
              TextFormField(
                initialValue: _lastMeal,
                decoration: const InputDecoration(
                  labelText: 'Last meal time *',
                  hintText: 'e.g., 2 hours ago or 07:30 AM',
                  border: OutlineInputBorder(),
                ),
                validator: (t) => (t == null || t.trim().isEmpty) ? 'Required' : null,
                onChanged: (t) => _lastMeal = t,
              ),
              const SizedBox(height: 12),

              // history + symptoms
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Any history',
                        hintText: 'Known diabetes, on medication, etc.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => _history = t,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Any other symptoms',
                        hintText: 'Polyuria, polydipsia, weight loss…',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => _symptoms = t,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // notes + follow-up + save
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => _notes = t,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _followupDays == 0 ? '' : '$_followupDays',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Follow-up in (days)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => _followupDays = int.tryParse(t.trim()) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _canSave ? _save : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent tests', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _recent.isEmpty
                ? const Text('No tests recorded yet.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Patient')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Result')),
                        DataColumn(label: Text('Last meal')),
                        DataColumn(label: Text('Taken at')),
                        DataColumn(label: Text('Follow-up (days)')),
                      ],
                      rows: _recent.map((row) => _toDataRow(row)).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  DataRow _toDataRow(Map<String, dynamic> row) {
    final id = row['id'];
    final pid = row['fk_patient_id'];
    final t = (row['test_type'] ?? '').toString();
    final lastMeal = (row['last_meal_time'] ?? '').toString();
    final takenAt = (row['recorded_at'] ?? '').toString();
    final fup = (row['followup_days'] ?? 0).toString();

    String resultStr = '';
    if (t == 'HbA1c') {
      final r = (row['hba1c'] ?? 0).toString();
      resultStr = '$r %';
    } else if (t == 'FBS') {
      resultStr = '${row['fasting'] ?? ''} mg/dL';
    } else if (t == 'PPBS') {
      resultStr = '${row['pp'] ?? ''} mg/dL';
    } else {
      resultStr = '${row['random'] ?? ''} mg/dL';
    }

    return DataRow(
      selected: _selectedRows.contains(id),
      onSelectChanged: (_) {
        setState(() {
          if (_selectedRows.contains(id)) {
            _selectedRows.remove(id);
          } else {
            _selectedRows.add(id as int);
          }
        });
      },
      cells: [
        DataCell(Text('$id')),
        DataCell(Text('#$pid')),
        DataCell(Text(t)),
        DataCell(Text(resultStr)),
        DataCell(Text(lastMeal)),
        DataCell(Text(takenAt)),
        DataCell(Text(fup)),
      ],
    );
  }

  // small helpers for numeric input fields if you want to reuse
  Widget _numField(String label, void Function(String) onChanged, {double val = 0}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: val == 0.0 ? '' : val.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Enter $label',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onChanged: onChanged,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F57A3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F57A3),
        elevation: 0,
        title: const Text('Sugar Blood Test'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Container(
        color: const Color(0xFFF6F8FB),
        child: _buildBody(),
      ),
    );
  }
}
