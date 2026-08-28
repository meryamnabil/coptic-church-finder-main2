import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color backgroundBeige = Color(0xFFF5EFE6);

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const SelectLocationScreen({super.key, this.initialLocation});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ?? const LatLng(30.0444, 31.2357);

    if (widget.initialLocation == null) {
      _getCurrentUserLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: darkGold));
  }

  Future<void> _getCurrentUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackBar('يرجى تفعيل خدمات الموقع (GPS) في هاتفك.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          _showSnackBar('تم رفض الإذن بالوصول للموقع.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackBar('صلاحيات الموقع مرفوضة دائمًا من الإعدادات.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _selectedLocation = userLatLng;
        _isLoading = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('تعذر جلب موقعك. يمكنك تحريك الخريطة يدويًا.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        title: const Text(
          'حدد الموقع',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGold,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              _selectedLocation = position.target;
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.redAccent.shade700,
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: primaryGold),
              ),
            ),
          Positioned(
            right: 20,
            bottom: 90,
            child: FloatingActionButton(
              heroTag: 'myLocationBtn',
              backgroundColor: Colors.white,
              onPressed: _getCurrentUserLocation,
              child: const Icon(Icons.my_location, color: primaryGold),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              child: const Text(
                'تأكيد الموقع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
