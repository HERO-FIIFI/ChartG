// Legacy file — chart functionality is now in lib/screens/charts_screen.dart
// Kept for reference only.

import 'package:flutter/material.dart';

class ChartViewScreen extends StatelessWidget {
  final String currencyPair;

  const ChartViewScreen({super.key, this.currencyPair = 'EUR/USD'});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
