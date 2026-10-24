import 'package:flutter/material.dart';

import 'empty_view.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyView(
        icon: icon,
        title: '$title tez orada',
        message: 'Bu bo\'lim keyingi bosqichda tayyor bo\'ladi.',
      ),
    );
  }
}