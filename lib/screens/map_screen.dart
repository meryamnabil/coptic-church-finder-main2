import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/church_provider.dart';
import '../providers/location_provider.dart';

// ─── Theme Colors ────────────────────────────────────────────────
const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color lightGold = Color(0xFFF5E6D3);
const Color surfaceColor = Color(0xFFFAFAFA);
const Color cardShadow = Color(0x1A000000);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  // ─── State ────────────────────────────────────────────────────
  static const LatLng _defaultPosition = LatLng(30.0444, 31.2357);
  dynamic _selectedChurch;
  String _searchQuery = '';
  bool _isSearchFocused = false;
  bool _isLoading = true;
  Set<Marker> _cachedMarkers = {};

  // ─── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeMap());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  // ─── Init ─────────────────────────────────────────────────────
  Future<void> _initializeMap() async {
    final churchProvider = context.read<ChurchProvider>();
    final locationProvider = context.read<LocationProvider>();

    await churchProvider.loadChurches();
    final locationAvailable = await locationProvider.getCurrentLocation();

    if (!mounted) return;

    final position = locationProvider.currentPosition;
    if (locationAvailable && position != null) {
      churchProvider.calculateNearestChurch(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _selectedChurch = churchProvider.nearestChurch;
        _isLoading = false;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      if (locationProvider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.errorMessage!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    _fabAnimController.forward();
  }

  // ─── Helpers ──────────────────────────────────────────────────
  List _filteredChurches(List churches) {
    if (_searchQuery.isEmpty) return churches;
    final q = _searchQuery.toLowerCase();
    return churches
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q),
        )
        .toList();
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  double? _distanceTo(dynamic church, locationProvider) {
    final pos = locationProvider.currentPosition;
    if (pos == null) return null;
    // Haversine approximation (fast)
    const R = 6371000.0;
    final dLat = _degToRad(church.latitude - pos.latitude);
    final dLon = _degToRad(church.longitude - pos.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(pos.latitude)) *
            math.cos(_degToRad(church.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  // ─── Navigation ───────────────────────────────────────────────
  void _goToMyLocation(LocationProvider locationProvider) {
    final pos = locationProvider.currentPosition;
    if (pos == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
    );
  }

  void _goToNearest(ChurchProvider churchProvider) {
    final c = churchProvider.nearestChurch;
    if (c == null) return;
    _focusChurch(c);
  }

  void _focusChurch(dynamic church) {
    setState(() => _selectedChurch = church);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(church.latitude, church.longitude), 16),
    );
    _sheetController.animateTo(
      0.42,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ─── Markers ──────────────────────────────────────────────────
  Set<Marker> _buildMarkers(
    ChurchProvider churchProvider,
    LocationProvider locationProvider,
  ) {
    final markers = <Marker>{};
    final nearest = churchProvider.nearestChurch;

    for (final church in churchProvider.churches) {
      final isNearest = church.id == nearest?.id;
      final isSelected = church.id == _selectedChurch?.id;
      markers.add(
        Marker(
          markerId: MarkerId(church.id),
          position: LatLng(church.latitude, church.longitude),
          infoWindow: InfoWindow(
            title: church.name,
            snippet: isNearest ? '⭐ أقرب كنيسة' : church.address,
          ),
          icon:
              isNearest
                  ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  )
                  : isSelected
                  ? BitmapDescriptor.defaultMarkerWithHue(50) // gold
                  : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
          zIndexInt:
              isNearest
                  ? 3
                  : isSelected
                  ? 2
                  : 1,
          onTap: () => _focusChurch(church),
        ),
      );
    }

    final pos = locationProvider.currentPosition;
    if (pos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 4,
        ),
      );
    }

    return markers;
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<ChurchProvider, LocationProvider>(
      builder: (context, churchProvider, locationProvider, _) {
        final pos = locationProvider.currentPosition;
        final currentPos =
            pos == null
                ? _defaultPosition
                : LatLng(pos.latitude, pos.longitude);
        final filtered = _filteredChurches(churchProvider.churches);

        return Scaffold(
          backgroundColor: surfaceColor,
          body: Stack(
            children: [
              // ── Map ─────────────────────────────────────────
              _buildMap(churchProvider, locationProvider, currentPos),

              // ── Search Bar ──────────────────────────────────
              _buildSearchBar(churchProvider, filtered),

              // ── FABs ────────────────────────────────────────
              _buildFABs(churchProvider, locationProvider),

              // ── Search Results Dropdown ──────────────────────
              if (_searchQuery.isNotEmpty && _isSearchFocused)
                _buildSearchDropdown(filtered),

              // ── Bottom Sheet ─────────────────────────────────
              _buildBottomSheet(filtered, locationProvider, churchProvider),

              // ── Loading Overlay ──────────────────────────────
              if (_isLoading) _buildSkeletonLoader(),
            ],
          ),
        );
      },
    );
  }

  // ─── Map Widget ───────────────────────────────────────────────
  Widget _buildMap(
    ChurchProvider churchProvider,
    LocationProvider locationProvider,
    LatLng currentPos,
  ) {
    return GoogleMap(
      myLocationEnabled: locationProvider.currentPosition != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      markers: _buildMarkers(churchProvider, locationProvider),
      initialCameraPosition: CameraPosition(target: currentPos, zoom: 13),
      onMapCreated: (c) {
        _mapController = c;
        if (locationProvider.currentPosition != null) {
          c.animateCamera(CameraUpdate.newLatLngZoom(currentPos, 15));
        }
      },
      padding: const EdgeInsets.only(bottom: 160),
      onTap: (_) {
        setState(() => _isSearchFocused = false);
        FocusScope.of(context).unfocus();
      },
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────
  Widget _buildSearchBar(ChurchProvider churchProvider, List filtered) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isSearchFocused ? 0.18 : 0.10),
              blurRadius: _isSearchFocused ? 24 : 12,
              spreadRadius: _isSearchFocused ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  _isSearchFocused
                      ? GestureDetector(
                        key: const ValueKey('back'),
                        onTap: () {
                          setState(() {
                            _isSearchFocused = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          FocusScope.of(context).unfocus();
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: primaryGold,
                          size: 22,
                        ),
                      )
                      : const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 22,
                        key: ValueKey('search'),
                      ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن كنيسة...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onTap: () => setState(() => _isSearchFocused = true),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() => _searchQuery = '');
                  _searchController.clear();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: primaryGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Dropdown ──────────────────────────────────────────
  Widget _buildSearchDropdown(List filtered) {
    final topPadding = MediaQuery.of(context).padding.top + 70;
    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        shadowColor: Colors.black26,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child:
                filtered.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'لا توجد نتائج',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder:
                          (_, __) => const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: lightGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.church,
                              color: primaryGold,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            c.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              _isSearchFocused = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            FocusScope.of(context).unfocus();
                            _focusChurch(c);
                          },
                        );
                      },
                    ),
          ),
        ),
      ),
    );
  }

  // ─── FABs ─────────────────────────────────────────────────────
  Widget _buildFABs(
    ChurchProvider churchProvider,
    LocationProvider locationProvider,
  ) {
    return Positioned(
      right: 16,
      bottom: 200,
      child: ScaleTransition(
        scale: _fabScaleAnim,
        child: Column(
          children: [
            _premiumFAB(
              icon: Icons.my_location,
              tooltip: 'موقعي',
              onTap: () => _goToMyLocation(locationProvider),
            ),
            const SizedBox(height: 10),
            _premiumFAB(
              icon: Icons.near_me,
              tooltip: 'أقرب كنيسة',
              onTap: () => _goToNearest(churchProvider),
              color: primaryGold,
              iconColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumFAB({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = primaryGold,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  // ─── Bottom Sheet ─────────────────────────────────────────────
  Widget _buildBottomSheet(
    List filtered,
    LocationProvider locationProvider,
    ChurchProvider churchProvider,
  ) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.15,
      minChildSize: 0.10,
      maxChildSize: 0.82,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: cardShadow,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildSheetHandle(),

              // Selected Church Card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                child:
                    _selectedChurch != null
                        ? _buildSelectedCard(_selectedChurch, locationProvider)
                        : const SizedBox.shrink(),
              ),

              if (_selectedChurch != null) ...[
                const SizedBox(height: 4),
                const Divider(indent: 20, endIndent: 20),
              ],

              // List Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'كنائس قريبة (${filtered.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkGold,
                      ),
                    ),
                    Text(
                      'مرتّبة بالأقرب',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Church List
              if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map((c) {
                  final isSelected = c.id == _selectedChurch?.id;
                  final dist = _distanceTo(c, locationProvider);
                  return _buildChurchCard(c, isSelected, dist);
                }),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─── Selected Church Card ─────────────────────────────────────
  Widget _buildSelectedCard(dynamic church, LocationProvider locationProvider) {
    final dist = _distanceTo(church, locationProvider);
    return Container(
      key: ValueKey(church.id),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightGold, width: 1.5),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Church Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child:
                church.imageUrl.isNotEmpty
                    ? Image.network(
                      church.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(160),
                    )
                    : _imagePlaceholder(160),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        church.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dist != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: darkGold,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDistance(dist),
                              style: const TextStyle(
                                fontSize: 12,
                                color: darkGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        church.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (church.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    church.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    _actionBtn(
                      Icons.directions,
                      'توجيه',
                      primaryGold,
                      Colors.white,
                      filled: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      Icons.favorite_border,
                      'مفضلة',
                      Colors.grey.shade200,
                      Colors.grey.shade700,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      Icons.call_outlined,
                      'اتصال',
                      Colors.grey.shade200,
                      Colors.grey.shade700,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      Icons.info_outline,
                      'تفاصيل',
                      Colors.grey.shade200,
                      Colors.grey.shade700,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color bg,
    Color fg, {
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Church List Card ─────────────────────────────────────────
  Widget _buildChurchCard(dynamic church, bool isSelected, double? dist) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? lightGold.withOpacity(.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isSelected
                ? Border.all(color: primaryGold, width: 1.5)
                : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color:
                isSelected
                    ? primaryGold.withOpacity(.12)
                    : Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _focusChurch(church),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    church.imageUrl.isNotEmpty
                        ? Image.network(
                          church.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _smallImagePlaceholder(),
                        )
                        : _smallImagePlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      church.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      church.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dist != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11,
                            color: primaryGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDistance(dist),
                            style: const TextStyle(
                              fontSize: 11,
                              color: primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.church_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد كنائس',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب البحث بكلمة مختلفة',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── Skeleton Loader ──────────────────────────────────────────
  Widget _buildSkeletonLoader() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 280,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _shimmer(height: 100, radius: 16),
            const SizedBox(height: 12),
            _shimmer(height: 16, width: 180),
            const SizedBox(height: 8),
            _shimmer(height: 12, width: 120),
          ],
        ),
      ),
    );
  }

  Widget _shimmer({double? width, double height = 16, double radius = 8}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─── Image Placeholders ───────────────────────────────────────
  Widget _imagePlaceholder(double h) {
    return Container(
      height: h,
      width: double.infinity,
      color: lightGold.withOpacity(.5),
      child: const Center(
        child: Icon(Icons.church, color: primaryGold, size: 48),
      ),
    );
  }

  Widget _smallImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: lightGold.withOpacity(.5),
      child: const Center(
        child: Icon(Icons.church, color: primaryGold, size: 26),
      ),
    );
  }
}
