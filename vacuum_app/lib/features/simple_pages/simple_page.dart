import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EmptyState(
        icon: Icons.construction,
        title: title,
        description:
            'This screen is scaffolded. Next: implement full parity UI + data.',
      ),
    );
  }
}
