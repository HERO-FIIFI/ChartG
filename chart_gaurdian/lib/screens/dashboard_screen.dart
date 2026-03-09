import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../addfav.dart';
import 'charts_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class NewsItem {
  final String date;
  final String time;
  final String currency;
  final String impact;
  final String title;
  final String forecast;
  final String previous;

  const NewsItem({
    required this.date,
    required this.time,
    required this.currency,
    required this.impact,
    required this.title,
    required this.forecast,
    required this.previous,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      impact: json['impact']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      forecast: json['forecast']?.toString() ?? '',
      previous: json['previous']?.toString() ?? '',
    );
  }
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<NewsItem> _allNews = [];
  List<String> _favPairs = [];
  bool _loadingNews = true;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _loadFavPairs();
    _fetchNews();
  }

  Future<void> _loadFavPairs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favPairs') ?? [];
    setState(() => _favPairs = saved.isEmpty ? ['EUR/USD', 'GBP/USD'] : saved);
  }

  Future<void> _fetchNews() async {
    setState(() {
      _loadingNews = true;
      _newsError = null;
    });
    try {
      final response = await http
          .get(Uri.parse(
              'https://nfs.faireconomy.media/ff_calendar_thisweek.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allNews = data.map((e) => NewsItem.fromJson(e)).toList();
          _loadingNews = false;
        });
      } else {
        setState(() {
          _newsError = 'Could not load news (${response.statusCode})';
          _loadingNews = false;
        });
      }
    } catch (e) {
      setState(() {
        _newsError = 'No internet connection. News unavailable.';
        _loadingNews = false;
      });
    }
  }

  List<NewsItem> _filteredNews() {
    if (_favPairs.isEmpty) return _allNews;
    final favCurrencies = _favPairs
        .expand((p) => p.split('/'))
        .toSet();
    return _allNews
        .where((n) => favCurrencies.contains(n.currency))
        .toList();
  }

  Future<void> _openAddFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFavoriteCurrencyScreen(
          currentFavorites: _favPairs,
          onSave: (pairs) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('favPairs', pairs);
            setState(() => _favPairs = pairs);
          },
        ),
      ),
    );
  }

  Color _impactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return AppColors.impactHigh;
      case 'medium':
        return AppColors.impactMedium;
      default:
        return AppColors.impactLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.card,
      onRefresh: _fetchNews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGreeting(),
          const SizedBox(height: 24),
          _buildNewsSection(),
          const SizedBox(height: 24),
          _buildFavPairsSection(),
          const SizedBox(height: 24),
          _buildMarketClock(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here\'s what\'s moving the markets',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNewsSection() {
    final filtered = _filteredNews();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Economic Calendar',
          trailing: IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: _fetchNews,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingNews)
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _NewsCardSkeleton(),
            ),
          )
        else if (_newsError != null)
          _ErrorTile(message: _newsError!, onRetry: _fetchNews)
        else if (filtered.isEmpty)
          _EmptyNewsTile(onAddPairs: _openAddFavorites)
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => _NewsCard(
                news: filtered[i],
                impactColor: _impactColor(filtered[i].impact),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavPairsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Favourite Pairs',
          trailing: TextButton.icon(
            onPressed: _openAddFavorites,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Edit', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        if (_favPairs.isEmpty)
          GestureDetector(
            onTap: _openAddFavorites,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.gold.withOpacity(0.4),
                    style: BorderStyle.solid),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text('Add favourite currency pairs',
                        style: TextStyle(color: AppColors.gold)),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favPairs.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                if (i == _favPairs.length) {
                  return _AddPairButton(onTap: _openAddFavorites);
                }
                return _PairCard(
                  pair: _favPairs[i],
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ChartDetailScreen(pair: _favPairs[i]),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMarketClock() {
    final now = DateTime.now().toUtc();
    final sessions = [
      _MarketSession(
          name: 'Sydney',
          open: 22,
          close: 7,
          utcNow: now.hour,
          flag: '🇦🇺'),
      _MarketSession(
          name: 'Tokyo', open: 0, close: 9, utcNow: now.hour, flag: '🇯🇵'),
      _MarketSession(
          name: 'London', open: 8, close: 17, utcNow: now.hour, flag: '🇬🇧'),
      _MarketSession(
          name: 'New York', open: 13, close: 22, utcNow: now.hour, flag: '🇺🇸'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Market Sessions (UTC)'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: sessions
                .map((s) => _SessionIndicator(session: s))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─── News Card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsItem news;
  final Color impactColor;

  const _NewsCard({required this.news, required this.impactColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  news.currency,
                  style: TextStyle(
                    color: impactColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: impactColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                news.impact,
                style: TextStyle(
                  color: impactColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              news.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${news.date}  ${news.time}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          if (news.forecast.isNotEmpty || news.previous.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (news.forecast.isNotEmpty)
                  Text(
                    'F: ${news.forecast}',
                    style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                const SizedBox(width: 8),
                if (news.previous.isNotEmpty)
                  Text(
                    'P: ${news.previous}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NewsCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ─── Pair Card ─────────────────────────────────────────────────────────────────

class _PairCard extends StatelessWidget {
  final String pair;
  final VoidCallback onTap;

  const _PairCard({required this.pair, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = pair.split('/');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.candlestick_chart_rounded,
                    color: AppColors.gold, size: 18),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textSecondary),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts.isNotEmpty ? parts[0] : pair,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (parts.length > 1)
                  Text(
                    '/ ${parts[1]}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPairButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPairButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.gold, size: 28),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.gold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyNewsTile extends StatelessWidget {
  final VoidCallback onAddPairs;

  const _EmptyNewsTile({required this.onAddPairs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAddPairs,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No news for selected currencies. Tap to add more pairs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── Market Session Indicator ─────────────────────────────────────────────────

class _MarketSession {
  final String name;
  final int open;
  final int close;
  final int utcNow;
  final String flag;

  const _MarketSession({
    required this.name,
    required this.open,
    required this.close,
    required this.utcNow,
    required this.flag,
  });

  bool get isOpen {
    if (open < close) {
      return utcNow >= open && utcNow < close;
    } else {
      // Overnight session (e.g. Sydney 22:00–07:00)
      return utcNow >= open || utcNow < close;
    }
  }
}

class _SessionIndicator extends StatelessWidget {
  final _MarketSession session;

  const _SessionIndicator({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(session.flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          session.name,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: session.isOpen
                ? AppColors.green.withOpacity(0.15)
                : AppColors.border,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            session.isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: session.isOpen ? AppColors.green : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
