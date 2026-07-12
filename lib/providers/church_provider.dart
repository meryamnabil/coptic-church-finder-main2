import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/church_model.dart';

class ChurchProvider with ChangeNotifier {
  List<Church> _churches = [];
  Future<void>? _loadFuture;
  Church? nearestChurch;

  List<Church> get churches => _churches;

  Future<void> loadChurches() {
    return _loadFuture ??= _loadChurches();
  }

  Future<void> _loadChurches() async {
    final jsonString = await rootBundle.loadString('assets/data/churches.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;

    _churches = jsonList
        .map((json) => Church.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
    notifyListeners();
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
