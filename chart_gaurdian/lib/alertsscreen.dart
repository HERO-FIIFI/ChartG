// ignore_for_file: file_names
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class Alert {
  String id;
  String currencyPair;
  double price;
  String type; // 'Above' | 'Below'

  Alert({
    required this.id,
    required this.currencyPair,
    required this.price,
    required this.type,
  });

  String toJson() =>
      '{"id":"$id","currencyPair":"$currencyPair","price":$price,"type":"$type"}';

  factory Alert.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    return Alert(
      id: data['id'],
      currencyPair: data['currencyPair'],
      price: (data['price'] as num).toDouble(),
      type: data['type'],
    );
  }
}

// ─── Alerts Screen ────────────────────────────────────────────────────────────

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs.getStringList('alerts') ?? [];
    setState(() {
      _alerts = stored.map((j) {
        try {
          return Alert.fromJson(j);
        } catch (_) {
          return null;
        }
      }).whereType<Alert>().toList();
    });
  }

  Future<void> _saveAlerts() async {
    await _prefs.setStringList(
        'alerts', _alerts.map((a) => a.toJson()).toList());
  }

  void _deleteAlert(int index) async {
    setState(() => _alerts.removeAt(index));
    await _saveAlerts();
  }

  void _openAddAlert() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddAlertSheet(
        onSave: (alert) async {
          setState(() => _alerts.add(alert));
          await _saveAlerts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_off_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No alerts set.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Get notified when a pair hits your target.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openAddAlert,
                    icon: const Icon(Icons.add_alert_rounded),
                    label: const Text('Add Alert'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final alert = _alerts[i];
                return Dismissible(
                  key: Key(alert.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.red),
                  ),
                  onDismissed: (_) => _deleteAlert(i),
                  child: _AlertCard(alert: alert),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAlert,
        child: const Icon(Icons.add_alert_rounded),
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.type == 'Above';
    final typeColor = isAbove ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAbove
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: typeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.currencyPair,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${alert.type} ',
                        style: TextStyle(
                          fontSize: 13,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: alert.price.toStringAsFixed(5),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Alert Sheet ──────────────────────────────────────────────────────────

const _alertPairs = [
  'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF',
  'AUD/USD', 'USD/CAD', 'NZD/USD', 'EUR/GBP',
  'EUR/JPY', 'GBP/JPY', 'XAU/USD',
];

class _AddAlertSheet extends StatefulWidget {
  final void Function(Alert) onSave;

  const _AddAlertSheet({required this.onSave});

  @override
  State<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends State<_AddAlertSheet> {
  final _priceCtrl = TextEditingController();
  String _pair = 'EUR/USD';
  String _type = 'Above';

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid price.'),
            backgroundColor: AppColors.red),
      );
      return;
    }

    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyPair: _pair,
      price: price,
      type: _type,
    );

    widget.onSave(alert);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Alert set: $_pair $_type $price'),
          backgroundColor: AppColors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Price Alert',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _pair,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Currency Pair'),
            items: _alertPairs
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _pair = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Target Price',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TypeBtn(
                  label: 'Above',
                  selected: _type == 'Above',
                  color: AppColors.green,
                  onTap: () => setState(() => _type = 'Above'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeBtn(
                  label: 'Below',
                  selected: _type == 'Below',
                  color: AppColors.red,
                  onTap: () => setState(() => _type = 'Below'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save Alert'),
          ),
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
