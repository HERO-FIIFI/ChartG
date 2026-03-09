import 'package:flutter/material.dart';

import 'app_theme.dart';

const _allPairs = [
  // Major pairs
  'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF',
  'AUD/USD', 'USD/CAD', 'NZD/USD',
  // Cross pairs
  'EUR/GBP', 'EUR/JPY', 'EUR/CHF', 'EUR/AUD', 'EUR/CAD',
  'GBP/JPY', 'GBP/CHF', 'GBP/AUD', 'GBP/CAD',
  'AUD/JPY', 'AUD/CHF', 'AUD/CAD', 'AUD/NZD',
  'NZD/JPY', 'NZD/CHF', 'NZD/CAD',
  'CAD/JPY', 'CHF/JPY',
  // Commodities
  'XAU/USD', 'XAG/USD',
  // Crypto
  'BTC/USD', 'ETH/USD',
];

class AddFavoriteCurrencyScreen extends StatefulWidget {
  final List<String> currentFavorites;
  final void Function(List<String>) onSave;

  const AddFavoriteCurrencyScreen({
    super.key,
    required this.currentFavorites,
    required this.onSave,
  });

  @override
  State<AddFavoriteCurrencyScreen> createState() =>
      _AddFavoriteCurrencyScreenState();
}

class _AddFavoriteCurrencyScreenState
    extends State<AddFavoriteCurrencyScreen> {
  late Set<String> _selected;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.currentFavorites);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return _allPairs;
    return _allPairs
        .where((p) => p.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _save() {
    widget.onSave(_selected.toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Select Currency Pairs',
            style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _save,
            child: Text(
              'Save (${_selected.length})',
              style: const TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search pairs...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (ctx, i) {
                final pair = _filtered[i];
                final selected = _selected.contains(pair);
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold.withOpacity(0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected ? AppColors.gold : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      Icons.candlestick_chart_rounded,
                      color: selected
                          ? AppColors.gold
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    pair,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.gold, size: 22)
                      : const Icon(Icons.circle_outlined,
                          color: AppColors.border, size: 22),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(pair);
                      } else {
                        _selected.add(pair);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: _selected.isEmpty ? null : _save,
              child: Text('Save ${_selected.length} Pair${_selected.length == 1 ? '' : 's'}'),
            ),
          ),
        ],
      ),
    );
  }
}
