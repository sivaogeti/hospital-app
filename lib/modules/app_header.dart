// lib/modules/app_header.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable header used on multiple pages — shows blue band, welcome text,
/// avatar on the right, three-dot menu, centered logo card and the nav pills.
class AppHeader extends StatelessWidget {
  final String username;
  final String role;
  final VoidCallback? onLogout;
  final double logoHeight;

  const AppHeader({
    super.key,
    required this.username,
    required this.role,
    this.onLogout,
    this.logoHeight = 72,
  });

  Widget _avatar() {
    // show a static asset avatar (replace if you store a real photo path)
    return CircleAvatar(radius: 28, backgroundImage: const AssetImage('assets/images/profile.jpg'));
  }

  Widget _navRow(BuildContext context) {
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
              return ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open $label'))),
                icon: Icon(icon, color: Colors.deepPurpleAccent, size: 18),
                label: Text(label, style: const TextStyle(color: Colors.black87)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }).toList(),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // top band with welcome + avatar + menu
        Container(
          color: const Color(0xFF0F57A3),
          padding: const EdgeInsets.only(top: 18, left: 14, right: 12, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Welcome to', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (role.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(role, style: const TextStyle(color: Colors.white70))),
                ]),
              ),
              // avatar
              Padding(padding: const EdgeInsets.only(right: 8.0), child: _avatar()),
              // menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'logout' && onLogout != null) onLogout!();
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Logout'))],
              ),
            ],
          ),
        ),

        // centered logo card (same as main dashboard)
        Container(
          color: const Color(0xFF0F57A3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: Card(
              color: const Color(0xFFF6EFF8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: logoHeight,
                  child: Image.asset('assets/images/hospital_logo.jpg', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),

        // responsive nav pills
        _navRow(context),
      ],
    );
  }
}
