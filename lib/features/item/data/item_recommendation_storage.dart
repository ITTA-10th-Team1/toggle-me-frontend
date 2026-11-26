import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemRecommendationStorage {
  static const _storageKey = 'item_search_queries';

  Future<void> saveSearchQueries(int itemId, List<String> searchQueries) async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_storageKey);

    final Map<String, dynamic> data = storedData == null
        ? {}
        : Map<String, dynamic>.from(jsonDecode(storedData) as Map);

    data[itemId.toString()] = searchQueries;

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<List<String>> getSearchQueries(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_storageKey);

    if (storedData == null) return [];

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      jsonDecode(storedData) as Map,
    );

    final queries = data[itemId.toString()] as List<dynamic>? ?? [];

    return queries.map((query) => query.toString()).toList();
  }

  Future<void> deleteSearchQueries(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_storageKey);

    if (storedData == null) return;

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      jsonDecode(storedData) as Map,
    );

    data.remove(itemId.toString());

    await prefs.setString(_storageKey, jsonEncode(data));
  }
}
