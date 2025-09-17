// lib/modules/stock_page.dart
import 'package:flutter/material.dart';
import '../modules/db.dart';

class StockPage extends StatefulWidget {
  final String username;
  const StockPage({super.key, required this.username});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<Map<String,dynamic>> _items = [];
  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DBHelper.database;
    final rows = await db.rawQuery('SELECT id, item_name, category, qty, unit, last_updated FROM stock ORDER BY item_name');
    setState(() => _items = rows.map((r)=>Map<String,dynamic>.from(r)).toList());
  }

  Future<void> _upsert() async {
    final name = _itemCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    final db = await DBHelper.database;
    final row = await db.rawQuery('SELECT id, qty FROM stock WHERE item_name=?', [name]);
    if (row.isNotEmpty) {
      final id = row.first['id'];
	  final current = row.first['qty'] as int? ?? 0;
	  final newQty = current + qty;      
      await db.update('stock', {'qty': newQty, 'last_updated': DateTime.now().toIso8601String()}, where: 'id=?', whereArgs: [id]);
    } else {
      await db.insert('stock', {'item_name': name, 'category': '', 'qty': qty, 'unit': 'pcs', 'last_updated': DateTime.now().toIso8601String()});
    }
    _itemCtrl.clear(); _qtyCtrl.clear();
    await _load();
  }

  @override
  void dispose() {
    _itemCtrl.dispose(); _qtyCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F57A3),
      appBar: AppBar(title: const Text('Inventory / Stock'), backgroundColor: const Color(0xFF0F57A3)),
      body: Column(children: [
        Container(height: 100, color: const Color(0xFF0F57A3), child: Padding(padding: const EdgeInsets.all(12), child: Align(alignment: Alignment.bottomLeft, child: Text(widget.username, style: const TextStyle(color: Colors.white, fontSize: 16))))),
        Expanded(child: Container(
          color: const Color(0xFFF6F8FB),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _itemCtrl, decoration: const InputDecoration(labelText: 'Item name'))),
              const SizedBox(width: 8),
              SizedBox(width: 100, child: TextFormField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _upsert, child: const Text('Add')),
            ]),
            const SizedBox(height: 12),
            Expanded(child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_,__)=>const Divider(),
              itemBuilder: (ctx,i){
                final it = _items[i];
                return ListTile(
                  title: Text(it['item_name'] ?? ''),
                  subtitle: Text('Qty: ${it['qty'] ?? 0}  • ${it['unit'] ?? ''}'),
                  trailing: Text(it['last_updated'] ?? ''),
                );
              }
            )),
          ]),
        )),
      ]),
    );
  }
}
