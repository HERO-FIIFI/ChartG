import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class JournalEntry {
  final String id;
  final DateTime date;
  final String pair;
  final String direction; // 'Buy' | 'Sell'
  final double entryPrice;
  final double exitPrice;
  final String emotion; // 'Confident', 'Nervous', 'Fearful', 'Neutral'
  final String notes;
  final bool isWin;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.pair,
    required this.direction,
    required this.entryPrice,
    required this.exitPrice,
    required this.emotion,
    required this.notes,
    required this.isWin,
  });

  double get pnl {
    final diff = exitPrice - entryPrice;
    return direction == 'Buy' ? diff : -diff;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'pair': pair,
        'direction': direction,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'emotion': emotion,
        'notes': notes,
        'isWin': isWin,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
        id: m['id'],
        date: DateTime.parse(m['date']),
        pair: m['pair'],
        direction: m['direction'],
        entryPrice: (m['entryPrice'] as num).toDouble(),
        exitPrice: (m['exitPrice'] as num).toDouble(),
        emotion: m['emotion'],
        notes: m['notes'],
        isWin: m['isWin'] ?? true,
      );

  String toJson() => jsonEncode(toMap());

  factory JournalEntry.fromJson(String json) =>
      JournalEntry.fromMap(jsonDecode(json));
}

// ─── Journal Screen ───────────────────────────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('journalEntries') ?? [];
    setState(() {
      _entries = stored
          .map((e) {
            try {
              return JournalEntry.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<JournalEntry>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'journalEntries', _entries.map((e) => e.toJson()).toList());
  }

  void _openAddEntry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEntrySheet(
        onSave: (entry) async {
          setState(() => _entries.insert(0, entry));
          await _saveEntries();
        },
      ),
    );
  }

  void _deleteEntry(String id) async {
    setState(() => _entries.removeWhere((e) => e.id == id));
    await _saveEntries();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted.')),
      );
    }
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  int get _totalTrades => _entries.length;
  int get _wins => _entries.where((e) => e.isWin).length;
  double get _winRate =>
      _totalTrades == 0 ? 0 : (_wins / _totalTrades) * 100;
  double get _totalPnl =>
      _entries.fold(0.0, (sum, e) => sum + e.pnl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (_entries.isNotEmpty) _buildStats(),
          Expanded(
            child: _entries.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _EntryCard(
                      entry: _entries[i],
                      onDelete: () => _deleteEntry(_entries[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntry,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Trade'),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(
              label: 'Total Trades',
              value: '$_totalTrades',
              color: AppColors.blue),
          _StatDivider(),
          _StatItem(
              label: 'Win Rate',
              value: '${_winRate.toStringAsFixed(0)}%',
              color: _winRate >= 50 ? AppColors.green : AppColors.red),
          _StatDivider(),
          _StatItem(
            label: 'Total P&L',
            value: _totalPnl >= 0
                ? '+${_totalPnl.toStringAsFixed(4)}'
                : _totalPnl.toStringAsFixed(4),
            color: _totalPnl >= 0 ? AppColors.green : AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.book_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'No journal entries yet.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log your trades to track performance.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openAddEntry,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Trade'),
          ),
        ],
      ),
    );
  }
}

// ─── Stats widgets ─────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32, color: AppColors.border);
  }
}

// ─── Entry Card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  Color get _emotionColor {
    switch (entry.emotion) {
      case 'Confident':
        return AppColors.green;
      case 'Nervous':
        return AppColors.impactMedium;
      case 'Fearful':
        return AppColors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pnl = entry.pnl;
    final pnlColor = pnl >= 0 ? AppColors.green : AppColors.red;
    final isWin = entry.isWin;

    return Dismissible(
      key: Key(entry.id),
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
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWin
                ? AppColors.green.withOpacity(0.3)
                : AppColors.red.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Direction badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.direction == 'Buy'
                        ? AppColors.green.withOpacity(0.2)
                        : AppColors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.direction.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: entry.direction == 'Buy'
                          ? AppColors.green
                          : AppColors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.pair,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  pnl >= 0
                      ? '+${pnl.toStringAsFixed(4)}'
                      : pnl.toStringAsFixed(4),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: pnlColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  label: 'Entry',
                  value: entry.entryPrice.toStringAsFixed(5),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'Exit',
                  value: entry.exitPrice.toStringAsFixed(5),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _emotionColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.emotion,
                    style: TextStyle(
                        fontSize: 11,
                        color: _emotionColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.notes,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(entry.date),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Add Entry Sheet ──────────────────────────────────────────────────────────

const _pairs = [
  'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF',
  'AUD/USD', 'USD/CAD', 'NZD/USD', 'EUR/GBP',
  'EUR/JPY', 'GBP/JPY', 'XAU/USD',
];

const _emotions = ['Confident', 'Neutral', 'Nervous', 'Fearful'];

class _AddEntrySheet extends StatefulWidget {
  final void Function(JournalEntry) onSave;

  const _AddEntrySheet({required this.onSave});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  String _pair = 'EUR/USD';
  String _direction = 'Buy';
  String _emotion = 'Neutral';
  bool _isWin = true;
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      pair: _pair,
      direction: _direction,
      entryPrice: double.parse(_entryCtrl.text),
      exitPrice: double.parse(_exitCtrl.text),
      emotion: _emotion,
      notes: _notesCtrl.text.trim(),
      isWin: _isWin,
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Log Trade',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              // Pair dropdown
              DropdownButtonFormField<String>(
                value: _pair,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Currency Pair'),
                items: _pairs
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pair = v!),
              ),
              const SizedBox(height: 16),
              // Direction
              Row(
                children: [
                  Expanded(
                    child: _DirectionButton(
                      label: 'Buy',
                      selected: _direction == 'Buy',
                      color: AppColors.green,
                      onTap: () => setState(() => _direction = 'Buy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DirectionButton(
                      label: 'Sell',
                      selected: _direction == 'Sell',
                      color: AppColors.red,
                      onTap: () => setState(() => _direction = 'Sell'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Prices
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _entryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Entry Price'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _exitCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Exit Price'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Emotion
              DropdownButtonFormField<String>(
                value: _emotion,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Emotion',
                  prefixIcon: Icon(Icons.psychology_rounded),
                ),
                items: _emotions
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _emotion = v!),
              ),
              const SizedBox(height: 16),
              // Outcome
              Row(
                children: [
                  const Text('Outcome: ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isWin = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isWin
                            ? AppColors.green.withOpacity(0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isWin
                              ? AppColors.green
                              : AppColors.border,
                        ),
                      ),
                      child: Text('Win',
                          style: TextStyle(
                              color: _isWin
                                  ? AppColors.green
                                  : AppColors.textSecondary,
                              fontWeight: _isWin
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isWin = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isWin
                            ? AppColors.red.withOpacity(0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isWin
                              ? AppColors.red
                              : AppColors.border,
                        ),
                      ),
                      child: Text('Loss',
                          style: TextStyle(
                              color: !_isWin
                                  ? AppColors.red
                                  : AppColors.textSecondary,
                              fontWeight: !_isWin
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes / Reflection',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionButton({
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
