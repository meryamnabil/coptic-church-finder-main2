import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  initial,
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  LocationStatus _status = LocationStatus.initial;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  LocationStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> getCurrentLocation() async {
    _status = LocationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return _fail(
          LocationStatus.serviceDisabled,
          'Location services are disabled. Please enable GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return _fail(
          LocationStatus.permissionDenied,
          'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return _fail(
          LocationStatus.permissionDeniedForever,
          'Location permission is permanently denied. Enable it in settings.',
        );
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _status = LocationStatus.ready;
      notifyListeners();
      return true;
    } catch (error) {
      return _fail(
        LocationStatus.error,
        'Unable to get the current location: $error',
      );
    }
  }

  bool _fail(LocationStatus status, String message) {
    _currentPosition = null;
    _status = status;
    _errorMessage = message;
    notifyListeners();
    return false;
  }
}
