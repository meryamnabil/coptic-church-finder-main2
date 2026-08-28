import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  initial,
  loading,
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationStatus _status = LocationStatus.initial;
  String _errorMessage = '';

  Position? get currentPosition => _currentPosition;
  LocationStatus get status => _status;
  String get errorMessage => _errorMessage;

  Future<void> getCurrentLocation() async {
    _status = LocationStatus.loading;
    notifyListeners();

    // 1. التحقق من تفعيل خدمة الموقع على الجهاز
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = LocationStatus.serviceDisabled;
      _errorMessage = 'خدمة الموقع معطلة على الجهاز. يرجى تفعيلها.';
      notifyListeners();
      return;
    }

    // 2. التحقق من حالة إذن الموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _status = LocationStatus.permissionDenied;
        _errorMessage = 'تم رفض إذن الوصول للموقع.';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _status = LocationStatus.permissionDeniedForever;
      _errorMessage =
          'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من إعدادات التطبيق.';
      notifyListeners();
      return;
    }

    // 3. الحصول على الموقع الحالي بعد التأكد من الأذونات
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _status = LocationStatus.success;
    } catch (e) {
      _status = LocationStatus.permissionDenied;
      _errorMessage = 'تعذر الحصول على الموقع الحالي.';
    }

    notifyListeners();
  }

  /// فتح إعدادات التطبيق أو الجهاز مباشرة
  Future<void> openSettings() async {
    if (_status == LocationStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else if (_status == LocationStatus.permissionDeniedForever) {
      await Geolocator.openAppSettings();
    }
  }
}
