import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import 'models.dart';

/// Loads market.json: live URL first, then the last good copy, then the bundled sample.
class MarketRepository {
  static const _cacheKey = 'market_json';

  Future<MarketData> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (dataUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(dataUrl)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final data = MarketData.fromJson(jsonDecode(res.body), DataSource.live);
          await prefs.setString(_cacheKey, res.body);
          return data;
        }
      } catch (_) {
        // Offline or bad response: fall through to the cache.
      }
    }
    final cached = prefs.getString(_cacheKey);
    if (cached != null) return MarketData.fromJson(jsonDecode(cached), DataSource.cached);
    final sample = await rootBundle.loadString('assets/sample_market.json');
    return MarketData.fromJson(jsonDecode(sample), DataSource.sample);
  }
}

final marketDataProvider = FutureProvider<MarketData>((ref) => MarketRepository().load());
