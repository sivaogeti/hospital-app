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
  List<Map<String, dynamic>> _items = [];
  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.listStockItems();
    setState(() => _items = rows);
  }

  Future<void> _upsert() async {
    final name = _itemCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    await DBHelper.upsertStockByName(itemName: name, deltaQty: qty);
    _itemCtrl.clear();
    _qtyCtrl.clear();
    await _load();
  }

  Future<void> _adjust(int id, int delta) async {
    await DBHelper.adjustStock(id: id, delta: delta);
    await _load();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F57A3),
      appBar: AppBar(
        title: const Text('Inventory / Stock'),
        backgroundColor: const Color(0xFF0F57A3),
      ),
      body: Column(
        children: [
          Container(
            height: 100,
            color: const Color(0xFF0F57A3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  widget.username,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF6F8FB),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _itemCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Item name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _upsert, child: const Text('Add')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Qty')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Last Updated')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _items.map((it) {
                            final qty = (it['qty'] as int?) ??
                                (it['qty'] is num ? (it['qty'] as num).toInt() : 0);
                            final rowId = (it['id'] as int?) ??
                                (it['id'] is num ? (it['id'] as num).toInt() : null);
                            final isLow = qty <= 5;
                            return DataRow(
                              color: isLow
                                  ? MaterialStateProperty.resolveWith(
                                      (_) => Colors.red.shade50,
                                    )
                                  : null,
                              cells: [
                                DataCell(Text(it['item_name']?.toString() ?? '')),
                                DataCell(Text(it['category']?.toString() ?? '')),
                                DataCell(
                                  Text(
                                    qty.toString(),
                                    style: isLow
                                        ? const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : null,
                                  ),
                                ),
                                DataCell(Text(it['unit']?.toString() ?? '')),
                                DataCell(
                                  Text(it['last_updated']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: rowId == null
                                            ? null
                                            : () => _adjust(rowId, -1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: rowId == null
                                            ? null
                                            : () => _adjust(rowId, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
