import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/church_model.dart';

class ChurchDistance {
  final Church church;
  final double distanceInMeters;

  ChurchDistance({required this.church, required this.distanceInMeters});
}

class ChurchProvider with ChangeNotifier {
  List<Church> _churches = [];
  Future<void>? _loadFuture;
  Church? nearestChurch;
  String? errorMessage;

  bool isSaving = false;

  final Set<String> _favoriteIds = {};
  static const String _favoritesKey = 'favorite_church_ids';

  List<Church> get churches => _churches;

  List<Church> get favoriteChurches =>
      _churches.where((c) => _favoriteIds.contains(c.id)).toList();

  bool isFavorite(String churchId) => _favoriteIds.contains(churchId);

  Future<void> loadChurches() {
    return _loadFuture ??= _loadChurches();
  }

  Future<void> _loadChurches() async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Church'));
      final response = await query.query();

      if (response.success && response.results != null) {
        _churches =
            response.results!
                .map((object) => Church.fromParse(object as ParseObject))
                .toList();
        errorMessage = null;
      } else {
        errorMessage = response.error?.message ?? 'تعذر تحميل بيانات الكنائس';
        _churches = [];
      }
    } catch (e) {
      errorMessage = 'تعذر الاتصال بالسيرفر';
      _churches = [];
    }

    await _loadFavorites();

    notifyListeners();
  }

  Future<bool> addChurch({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String description,
    File? imageFile,
  }) async {
    isSaving = true;
    notifyListeners();

    try {
      String imageUrl = '';

      if (imageFile != null) {
        final parseFile = ParseFile(imageFile);
        final uploadResponse = await parseFile.save();
        if (uploadResponse.success) {
          imageUrl = parseFile.url ?? '';
        } else {
          errorMessage = uploadResponse.error?.message ?? 'تعذر رفع الصورة';
          isSaving = false;
          notifyListeners();
          return false;
        }
      }

      final churchObject =
          ParseObject('Church')
            ..set('name', name)
            ..set('address', address)
            ..set('latitude', latitude)
            ..set('longitude', longitude)
            ..set('description', description)
            ..set('imageUrl', imageUrl);

      final response = await churchObject.save();

      if (response.success) {
        final savedChurch = Church.fromParse(churchObject);
        _churches.add(savedChurch);
        errorMessage = null;
        isSaving = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = response.error?.message ?? 'تعذر حفظ الكنيسة';
        isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'تعذر الاتصال بالسيرفر';
      isSaving = false;
      notifyListeners();
      return false;
    }
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

  List<ChurchDistance> getNearestChurches(
    double userLat,
    double userLng, {
    int count = 3,
  }) {
    final withDistance =
        _churches.map((church) {
          final distance = Geolocator.distanceBetween(
            userLat,
            userLng,
            church.latitude,
            church.longitude,
          );
          return ChurchDistance(church: church, distanceInMeters: distance);
        }).toList();

    withDistance.sort(
      (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
    );

    return withDistance.take(count).toList();
  }
}
