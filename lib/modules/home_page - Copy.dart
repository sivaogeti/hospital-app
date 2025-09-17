// lib/modules/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'patients_page.dart';
import 'app_header.dart';
import 'record_vitals_page.dart';
import 'sugar_test_page.dart';
import 'stock_page.dart';
import 'health_profiles_page.dart';
import 'reports_page.dart';


class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _displayName = '';
  String? _profilePath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayName = (widget.user['username'] ?? 'Health Agent').toString();
  }

  // small avatar with camera action
  Widget _avatarWidget() {
    final double outer = 30;
    final double inner = 26;

    Widget innerWidget;
    if (_loading) {
      innerWidget = const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_profilePath != null && File(_profilePath!).existsSync()) {
      innerWidget = CircleAvatar(radius: inner, backgroundImage: FileImage(File(_profilePath!)));
    } else {
      innerWidget = CircleAvatar(radius: inner, backgroundImage: const AssetImage('assets/images/profile.jpg'));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(radius: outer, backgroundColor: Colors.white, child: innerWidget),
        Positioned(
          right: -6,
          bottom: -6,
          child: Material(
            elevation: 2,
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                // TODO: show photo options
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topHeader() {
    return Container(
      color: const Color(0xFF0F57A3),
      padding: const EdgeInsets.only(top: 20, left: 14, right: 14, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome to', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if ((widget.user['role'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(widget.user['role'], style: const TextStyle(color: Colors.white70))),
            ]),
          ),
          Column(children: [ _avatarWidget(), const SizedBox(height: 6), GestureDetector(onTap: (){}, child: const Text('Edit name', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
        ],
      ),
    );
  }

  Widget _navRow() {
  final items = [
    {'label': 'Home', 'icon': Icons.home_outlined},
    {'label': 'Messages', 'icon': Icons.chat_bubble_outline},
    {'label': 'SOPs', 'icon': Icons.description_outlined},
    {'label': 'Pharmacy', 'icon': Icons.local_pharmacy_outlined},
    {'label': 'Settings', 'icon': Icons.settings_outlined},
  ];

  return Container(
    color: const Color(0xFF0F57A3),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: LayoutBuilder(builder: (ctx, constraints) {
      final double width = constraints.maxWidth;
      // compact mode for very narrow screens: show icon-only chips
      final bool compact = width < 360;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((it) {
          final label = it['label'] as String;
          final icon = it['icon'] as IconData;

          if (compact) {
            // small circular icon chip
            return GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open $label'))),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.deepPurpleAccent),
              ),
            );
          } else {
            return ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open $label'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.deepPurpleAccent), const SizedBox(width: 8), Text(label)]),
            );
          }
        }).toList(),
      );
    }),
  );
}

  Widget _dashboardCard(String title, String value, IconData icon, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          // space items vertically and avoid using Spacer()
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // top: icon + title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // middle: value (if any)
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ),

            // bottom action
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: onTap, child: const Text('Open')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    // pop until login (assumes LoginPage is below in stack)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // blue background for the top header band
      backgroundColor: const Color(0xFF0F57A3),
      // place a small menu in top-right using Stack so it sits over header
      body: SafeArea(
        child: Column(
          children: [
            // header row with logout button overlay
            Stack(
              children: [
                Column(
                  children: [
                    _topHeader(),
                    _navRow(),
                  ],
                ),
                // logout menu icon positioned top-right
                Positioned(
                  right: 8,
                  top: 4,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (v) {
                      if (v == 'logout') _logout();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                  ),
                ),
              ],
            ),

            // main content area
            Expanded(
              child: Container(
                color: const Color(0xFFF6F8FB),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    final width = constraints.maxWidth;
                    // Force 2 columns for typical phone widths (so cards are side-by-side)
                    final cross = (width > 900) ? 3 : (width > 420 ? 2 : 2);

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: 6,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 140, // fixed card height
                      ),
                      itemBuilder: (context, index) {
                        // index-based returns (clear & safe)
                        if (index == 0) {
                          return _dashboardCard('Patients', '4', Icons.people_alt, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PatientsPage(user: widget.user)));
                          });
                        }
                        if (index == 1) return _dashboardCard('Record Vitals', '2924', Icons.monitor_heart, () {});
                        if (index == 2) return _dashboardCard('Sugar Blood Test', '2924', Icons.science, () {});
                        if (index == 3) return _dashboardCard('Inventory / Stock', '0', Icons.inventory_2_outlined, () {});
                        if (index == 4) return _dashboardCard('Health Profiles', '', Icons.bar_chart, () {});
                        return _dashboardCard('Reports', '', Icons.article_outlined, () {});
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
