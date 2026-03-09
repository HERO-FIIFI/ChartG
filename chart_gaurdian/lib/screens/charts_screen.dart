import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

import '../app_theme.dart';
import '../addfav.dart';
import '../alertsscreen.dart';

// ─── TradingView symbol map ───────────────────────────────────────────────────

const Map<String, String> _tvSymbols = {
  'EUR/USD': 'FX:EURUSD',
  'GBP/USD': 'FX:GBPUSD',
  'USD/JPY': 'FX:USDJPY',
  'USD/CHF': 'FX:USDCHF',
  'AUD/USD': 'FX:AUDUSD',
  'USD/CAD': 'FX:USDCAD',
  'NZD/USD': 'FX:NZDUSD',
  'EUR/GBP': 'FX:EURGBP',
  'EUR/JPY': 'FX:EURJPY',
  'GBP/JPY': 'FX:GBPJPY',
  'XAU/USD': 'TVC:GOLD',
  'XAG/USD': 'TVC:SILVER',
  'BTC/USD': 'BITSTAMP:BTCUSD',
};

String _tvSymbol(String pair) =>
    _tvSymbols[pair] ?? 'FX:${pair.replaceAll('/', '')}';

// ─── Charts Screen (pair list) ────────────────────────────────────────────────

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  List<String> _favPairs = [];

  @override
  void initState() {
    super.initState();
    _loadPairs();
  }

  Future<void> _loadPairs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favPairs') ?? [];
    setState(() => _favPairs = saved.isEmpty ? ['EUR/USD', 'GBP/USD'] : saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _favPairs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.candlestick_chart_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No favourite pairs added yet.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFavoriteCurrencyScreen(
                          currentFavorites: _favPairs,
                          onSave: (pairs) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setStringList('favPairs', pairs);
                            _loadPairs();
                          },
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Pairs'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _favPairs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final pair = _favPairs[i];
                return _PairListTile(
                  pair: pair,
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ChartDetailScreen(pair: pair),
                    ),
                  ).then((_) => _loadPairs()),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddFavoriteCurrencyScreen(
              currentFavorites: _favPairs,
              onSave: (pairs) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('favPairs', pairs);
                _loadPairs();
              },
            ),
          ),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PairListTile extends StatelessWidget {
  final String pair;
  final VoidCallback onTap;

  const _PairListTile({required this.pair, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.candlestick_chart_rounded,
                  color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _tvSymbol(pair),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Chart Detail Screen (TradingView WebView) ────────────────────────────────

class ChartDetailScreen extends StatefulWidget {
  final String pair;

  const ChartDetailScreen({super.key, required this.pair});

  @override
  State<ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends State<ChartDetailScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadHtmlString(_buildTradingViewHtml(widget.pair));
  }

  String _buildTradingViewHtml(String pair) {
    final symbol = _tvSymbol(pair);
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0a0e1a; overflow: hidden; }
    #tv_chart_container { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <div id="tv_chart_container"></div>
  <script src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      "autosize": true,
      "symbol": "$symbol",
      "interval": "D",
      "timezone": "Etc/UTC",
      "theme": "dark",
      "style": "1",
      "locale": "en",
      "toolbar_bg": "#111827",
      "enable_publishing": false,
      "allow_symbol_change": false,
      "hide_top_toolbar": false,
      "hide_legend": false,
      "save_image": false,
      "container_id": "tv_chart_container"
    });
  </script>
</body>
</html>
''';
  }

  Future<void> _saveAnalysisImage() async {
    try {
      final boundary = _repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
        return _saveAnalysisImage();
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'chart_${widget.pair.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis saved: $fileName'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save analysis.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _openSetAlert() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _SetAlertSheet(pair: widget.pair),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.pair,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined,
                color: AppColors.gold),
            onPressed: _openSetAlert,
            tooltip: 'Set Price Alert',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_rounded,
                color: AppColors.textSecondary),
            onPressed: _saveAnalysisImage,
            tooltip: 'Save Analysis',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: WebViewWidget(controller: _controller),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
        ],
      ),
    );
  }
}

// ─── Set Alert Bottom Sheet ───────────────────────────────────────────────────

class _SetAlertSheet extends StatefulWidget {
  final String pair;

  const _SetAlertSheet({required this.pair});

  @override
  State<_SetAlertSheet> createState() => _SetAlertSheetState();
}

class _SetAlertSheetState extends State<_SetAlertSheet> {
  final _priceCtrl = TextEditingController();
  String _alertType = 'Above';
  String _tone = 'Default';

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAlert() async {
    final priceText = _priceCtrl.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid price format.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final newAlert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currencyPair: widget.pair,
      price: price,
      type: _alertType,
    );

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('alerts') ?? [];
    existing.add(newAlert.toJson());
    await prefs.setStringList('alerts', existing);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Alert set: ${widget.pair} $_alertType $price'),
          backgroundColor: AppColors.green,
        ),
      );
    }
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
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: AppColors.gold),
              const SizedBox(width: 10),
              Text(
                'Set Price Alert — ${widget.pair}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                child: _TypeButton(
                  label: 'Above',
                  selected: _alertType == 'Above',
                  color: AppColors.green,
                  onTap: () => setState(() => _alertType = 'Above'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: 'Below',
                  selected: _alertType == 'Below',
                  color: AppColors.red,
                  onTap: () => setState(() => _alertType = 'Below'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tone,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Notification Tone',
              prefixIcon: Icon(Icons.music_note_rounded),
            ),
            items: ['Default', 'Chime', 'Bell', 'Alert', 'Urgent']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tone = v!),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveAlert,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save Alert'),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
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
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
