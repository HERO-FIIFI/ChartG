import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../alertsscreen.dart';

/// Ported from the original Java appfxnews/ChartGuardian.java.
/// Runs a periodic timer to check if any price alerts have been triggered.
class PriceCheckerService {
  static final PriceCheckerService _instance = PriceCheckerService._internal();
  factory PriceCheckerService() => _instance;
  PriceCheckerService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  bool _initialized = false;

  // Cache of already-triggered alert IDs to avoid repeat notifications
  final Set<String> _triggered = {};

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);
    _initialized = true;
  }

  void start() {
    _timer?.cancel();
    // Check prices every 60 seconds while the app is open
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAll());
    // Also run immediately on start
    _checkAll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAll() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('alerts') ?? [];
    if (stored.isEmpty) return;

    final alerts = stored.map((j) {
      try {
        return Alert.fromJson(j);
      } catch (_) {
        return null;
      }
    }).whereType<Alert>().toList();

    // Fetch current exchange rates (USD base)
    final rates = await _fetchRates();
    if (rates.isEmpty) return;

    for (final alert in alerts) {
      if (_triggered.contains(alert.id)) continue;

      final currentPrice = _pairPrice(alert.currencyPair, rates);
      if (currentPrice == null) continue;

      final triggered = alert.type == 'Above'
          ? currentPrice >= alert.price
          : currentPrice <= alert.price;

      if (triggered) {
        _triggered.add(alert.id);
        await _notify(alert, currentPrice);
      }
    }
  }

  Future<Map<String, double>> _fetchRates() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawRates = data['rates'] as Map<String, dynamic>;
        return rawRates.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (_) {}
    return {};
  }

  /// Convert a currency pair like EUR/USD to a rate using USD-base rates.
  double? _pairPrice(String pair, Map<String, double> rates) {
    final parts = pair.split('/');
    if (parts.length != 2) return null;

    final base = parts[0].toUpperCase();
    final quote = parts[1].toUpperCase();

    if (base == 'USD') {
      return rates[quote];
    } else if (quote == 'USD') {
      final baseRate = rates[base];
      if (baseRate == null || baseRate == 0) return null;
      return 1.0 / baseRate;
    } else {
      final baseRate = rates[base];
      final quoteRate = rates[quote];
      if (baseRate == null || quoteRate == null || baseRate == 0) return null;
      return quoteRate / baseRate;
    }
  }

  Future<void> _notify(Alert alert, double currentPrice) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Notifications when a price alert is triggered',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      alert.id.hashCode,
      '🚨 Price Alert — ${alert.currencyPair}',
      '${alert.type} ${alert.price.toStringAsFixed(5)} reached! Current: ${currentPrice.toStringAsFixed(5)}',
      details,
    );
  }
}
