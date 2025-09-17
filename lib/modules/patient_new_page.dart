// lib/modules/patient_new_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'db.dart';
import 'app_header.dart';

class PatientNewPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const PatientNewPage({super.key, this.user});

  @override
  State<PatientNewPage> createState() => _PatientNewPageState();
}

class _PatientNewPageState extends State<PatientNewPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'Male';
  final _mobileCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String _diet = 'Vegetarian';
  final _breakfastCtrl = TextEditingController();
  final _lunchCtrl = TextEditingController();
  final _dinnerCtrl = TextEditingController();
  String _tobacco = 'No';
  String _alcohol = 'No';
  String _activity = 'Sedentary';
  final _familyCtrl = TextEditingController();

  XFile? _pickedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherCtrl.dispose();
    _ageCtrl.dispose();
    _mobileCtrl.dispose();
    _phoneCtrl.dispose();
    _aadharCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _breakfastCtrl.dispose();
    _lunchCtrl.dispose();
    _dinnerCtrl.dispose();
    _familyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final file = await _picker.pickImage(source: src, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (file != null) setState(() => _pickedPhoto = file);
    } catch (e) {
      debugPrint('pick photo error: $e');
    }
  }

  Future<String?> _savePhotoToApp(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'patient_photos'));
      if (!await folder.exists()) await folder.create(recursive: true);
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final dest = File(p.join(folder.path, filename));
      await File(file.path).copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('save photo error: $e');
      return null;
    }
  }

  Future<void> _savePatient() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    String? photoPath;
    if (_pickedPhoto != null) {
      photoPath = await _savePhotoToApp(_pickedPhoto!);
    }

    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final now = DateTime.now().toIso8601String();

    final values = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'father_name': _fatherCtrl.text.trim(),
      'age': age,
      'gender': _gender,
      'phone': _phoneCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      'aadhar': _aadharCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'village': _villageCtrl.text.trim(),
      'photo_path': photoPath,
      'diet': _diet,
      'breakfast': _breakfastCtrl.text.trim(),
      'lunch': _lunchCtrl.text.trim(),
      'dinner': _dinnerCtrl.text.trim(),
      'tobacco': _tobacco,
      'alcohol': _alcohol,
      'activity_level': _activity,
      'family_history': _familyCtrl.text.trim(),
      'created_at': now,
    };

    try {
      await DBHelper.insertPatient(values);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient saved')));
      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _fatherCtrl.clear();
    _ageCtrl.clear();
    _gender = 'Male';
    _mobileCtrl.clear();
    _phoneCtrl.clear();
    _aadharCtrl.clear();
    _addressCtrl.clear();
    _villageCtrl.clear();
    _diet = 'Vegetarian';
    _breakfastCtrl.clear();
    _lunchCtrl.clear();
    _dinnerCtrl.clear();
    _tobacco = 'No';
    _alcohol = 'No';
    _activity = 'Sedentary';
    _familyCtrl.clear();
    _pickedPhoto = null;
    setState(() {});
  }

  Widget _buildFormContents() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name *'), validator: (s) => (s == null || s.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _fatherCtrl, decoration: const InputDecoration(labelText: "Father's name")),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _gender,
              items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _gender = v ?? 'Male'),
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: TextFormField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile'))),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _aadharCtrl, decoration: const InputDecoration(labelText: 'Aadhar no')),
        const SizedBox(height: 12),
        TextFormField(controller: _addressCtrl, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        TextFormField(controller: _villageCtrl, decoration: const InputDecoration(labelText: 'Village')),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text('Camera'), onPressed: () => _pickPhoto(ImageSource.camera)),
          ElevatedButton.icon(icon: const Icon(Icons.photo), label: const Text('Gallery'), onPressed: () => _pickPhoto(ImageSource.gallery)),
          if (_pickedPhoto != null) SizedBox(width: 8),
          if (_pickedPhoto != null)
            SizedBox(height: 72, child: AspectRatio(aspectRatio: 1, child: Image.file(File(_pickedPhoto!.path), fit: BoxFit.cover))),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft, child: Text('Diet & Lifestyle', style: TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _diet,
          items: ['Vegetarian', 'Non-vegetarian', 'Vegan', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _diet = v ?? 'Vegetarian'),
          decoration: const InputDecoration(labelText: 'Diet'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _breakfastCtrl, decoration: const InputDecoration(labelText: 'Breakfast (example)')),
        const SizedBox(height: 12),
        TextFormField(controller: _lunchCtrl, decoration: const InputDecoration(labelText: 'Lunch (example)')),
        const SizedBox(height: 12),
        TextFormField(controller: _dinnerCtrl, decoration: const InputDecoration(labelText: 'Dinner (example)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _tobacco, items: ['No', 'Yes'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _tobacco = v ?? 'No'), decoration: const InputDecoration(labelText: 'Tobacco'))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(value: _alcohol, items: ['No', 'Yes'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _alcohol = v ?? 'No'), decoration: const InputDecoration(labelText: 'Alcohol'))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(value: _activity, items: ['Sedentary', 'Lightly active', 'Moderately active', 'Very active'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _activity = v ?? 'Sedentary'), decoration: const InputDecoration(labelText: 'Activity'))),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _familyCtrl, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Family history')),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 84),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.user != null && widget.user!['username'] != null) ? widget.user!['username'].toString() : 'healthagent1';
    final role = (widget.user != null && widget.user!['role'] != null) ? widget.user!['role'].toString() : 'Health Agent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        AppHeader(username: username, role: role, onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: _buildFormContents())),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: ElevatedButton(onPressed: _saving ? null : _savePatient, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Patient')),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: _clearForm, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)), child: const Text('Clear')),
        ]),
      ),
    );
  }
}
