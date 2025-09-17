// lib/modules/health_profiles_page.dart
import 'package:flutter/material.dart';
import '../modules/db.dart';
import 'package:collection/collection.dart';

class HealthProfilesPage extends StatefulWidget {
  final String username;
  const HealthProfilesPage({super.key, required this.username});
  @override
  State<HealthProfilesPage> createState() => _HealthProfilesPageState();
}

class _HealthProfilesPageState extends State<HealthProfilesPage> {
  List<Map<String,dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DBHelper.database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.age, p.gender, COALESCE(p.mobile,p.phone) as mobile, p.aadhar, p.activity_level, p.village,
        (SELECT v.bp_sys FROM vitals v WHERE v.fk_patient_id=p.id ORDER BY v.recorded_at DESC LIMIT 1) as bp_sys,
        (SELECT v.bp_dia FROM vitals v WHERE v.fk_patient_id=p.id ORDER BY v.recorded_at DESC LIMIT 1) as bp_dia,
        (SELECT v.pulse FROM vitals v WHERE v.fk_patient_id=p.id ORDER BY v.recorded_at DESC LIMIT 1) as pulse,
        (SELECT t.result_mg_dl FROM blood_sugar_tests t WHERE t.fk_patient_id=p.id ORDER BY t.taken_at DESC LIMIT 1) as sugar
      FROM patients p ORDER BY p.name COLLATE NOCASE
    ''');
    setState(() { _rows = rows.map((r)=>Map<String,dynamic>.from(r)).toList(); _loading=false; });
  }

  String _riskBadge(dynamic bpSys, dynamic bpDia, dynamic pulse, dynamic sugar) {
    double? bs = bpSys == null ? null : double.tryParse(bpSys.toString());
    double? bd = bpDia == null ? null : double.tryParse(bpDia.toString());
    double? pu = pulse == null ? null : double.tryParse(pulse.toString());
    double? sg = sugar == null ? null : double.tryParse(sugar.toString());
    if ((bs!=null && bs>160) || (bd!=null && bd>100) || (pu!=null && pu>120) || (sg!=null && sg>140)) return '🔴 Red';
    if ((bs!=null && bs>=140 && bs<=160) || (bd!=null && bd>=90 && bd<=100) || (pu!=null && pu>=100 && pu<=120) || (sg!=null && sg>=110 && sg<=140)) return '🟠 Amber';
    return '🟢 Green';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F57A3),
      appBar: AppBar(title: const Text('Health Profiles'), backgroundColor: const Color(0xFF0F57A3)),
      body: Column(children: [
        Container(height: 100, color: const Color(0xFF0F57A3), padding: const EdgeInsets.all(12), child: Align(alignment: Alignment.bottomLeft, child: Text(widget.username, style: const TextStyle(color: Colors.white, fontSize: 18)))),
        Expanded(child: Container(
          color: const Color(0xFFF6F8FB),
          padding: const EdgeInsets.all(12),
          child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
            itemCount: _rows.length,
            separatorBuilder: (_,__)=>const Divider(),
            itemBuilder: (ctx,i){
              final r = _rows[i];
              return ListTile(
                title: Text(r['name'] ?? ''),
                subtitle: Text('Age:${r['age'] ?? ''} • ${r['gender'] ?? ''} • ${r['village'] ?? ''}'),
                trailing: Text(_riskBadge(r['bp_sys'], r['bp_dia'], r['pulse'], r['sugar'])),
                onTap: (){
                  // you can navigate to detailed profile
                },
              );
            }
          ),
        )),
      ]),
    );
  }
}
