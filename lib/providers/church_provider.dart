import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/church_model.dart';

class ChurchProvider with ChangeNotifier {
  List<Church> _churches = [];
  Future<void>? _loadFuture;
  Church? nearestChurch;

  final Set<String> _favoriteIds = {};
  static const String _favoritesKey = 'favorite_church_ids';
  static const String _addedChurchesKey = 'added_churches';

  List<Church> get churches => _churches;

  List<Church> get favoriteChurches =>
      _churches.where((c) => _favoriteIds.contains(c.id)).toList();

  bool isFavorite(String churchId) => _favoriteIds.contains(churchId);

  Future<void> loadChurches() {
    return _loadFuture ??= _loadChurches();
  }

  Future<void> _loadChurches() async {
    final jsonString = await rootBundle.loadString('assets/data/churches.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;

    _churches =
        jsonList
            .map((json) => Church.fromJson(json as Map<String, dynamic>))
            .toList();

    await _loadAddedChurches();
    await _loadFavorites();

    notifyListeners();
  }

  Future<void> _loadAddedChurches() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChurches = prefs.getStringList(_addedChurchesKey) ?? [];

    final addedChurches =
        savedChurches
            .map(
              (json) =>
                  Church.fromJson(jsonDecode(json) as Map<String, dynamic>),
            )
            .toList();

    _churches.addAll(addedChurches);
  }

  Future<void> addChurch(Church church) async {
    _churches.add(church);

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_addedChurchesKey) ?? [];

    existing.add(jsonEncode(church.toJson()));
    await prefs.setStringList(_addedChurchesKey, existing);

    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_favoritesKey) ?? [];
    _favoriteIds
      ..clear()
      ..addAll(savedIds);
  }

  Future<void> toggleFavorite(String churchId) async {
    if (_favoriteIds.contains(churchId)) {
      _favoriteIds.remove(churchId);
    } else {
      _favoriteIds.add(churchId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
  }

  void calculateNearestChurch(double userLat, double userLng) {
    Church? closestChurch;
    double? shortestDistance;

    for (final church in _churches) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        church.latitude,
        church.longitude,
      );

      if (shortestDistance == null || distance < shortestDistance) {
        shortestDistance = distance;
        closestChurch = church;
      }
    }

    nearestChurch = closestChurch;
    notifyListeners();
  }
}
