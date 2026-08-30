import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_model.dart';
import '../providers/church_provider.dart';
import '../providers/location_provider.dart';
import 'map_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color lightGold = Color(0xFFF5E6D3);

class ChurchesListScreen extends StatefulWidget {
  const ChurchesListScreen({super.key});

  @override
  State<ChurchesListScreen> createState() => _ChurchesListScreenState();
}

class _ChurchesListScreenState extends State<ChurchesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LocationProvider>().getCurrentLocation();
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double? _distanceTo(Church church, LocationProvider locationProvider) {
    final pos = locationProvider.currentPosition;
    if (pos == null) return null;

    const r = 6371000.0;
    final dLat = (church.latitude - pos.latitude) * math.pi / 180;
    final dLon = (church.longitude - pos.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(pos.latitude * math.pi / 180) *
            math.cos(church.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "الكنائس القريبة",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGold, darkGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer2<ChurchProvider, LocationProvider>(
        builder: (context, churchProvider, locationProvider, _) {
          if (churchProvider.churches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(primaryGold),
              ),
            );
          }

          // 1. فلترة الكنائس حسب اسم الكنيسة
          final filteredChurches =
              churchProvider.churches.where((church) {
                final name = church.name.toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

          // 2. حساب المسافات
          final churchesWithDistance =
              filteredChurches.map((church) {
                return _ChurchDistanceItem(
                  church: church,
                  distance: _distanceTo(church, locationProvider),
                );
              }).toList();

          // 3. الترتيب حسب أقرب كنيسة
          if (locationProvider.currentPosition != null) {
            churchesWithDistance.sort((a, b) {
              final distA = a.distance ?? double.infinity;
              final distB = b.distance ?? double.infinity;
              return distA.compareTo(distB);
            });
          }

          return Column(
            children: [
              // ─── Search Bar ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "ابحث باسم الكنيسة...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: primaryGold),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                            : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryGold,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // ─── List of Churches ──────────────────────────────────────
              Expanded(
                child:
                    churchesWithDistance.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "لا توجد نتائج تطابق بحثك",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: churchesWithDistance.length,
                          itemBuilder: (context, index) {
                            final item = churchesWithDistance[index];
                            final isFav = churchProvider.isFavorite(
                              item.church.id,
                            );

                            return _ChurchCard(
                              church: item.church,
                              distanceString: _formatDistance(item.distance),
                              isFavorite: isFav,
                              onFavoriteToggle:
                                  () => churchProvider.toggleFavorite(
                                    item.church.id,
                                  ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChurchDistanceItem {
  final Church church;
  final double? distance;

  _ChurchDistanceItem({required this.church, required this.distance});
}

class _ChurchCard extends StatelessWidget {
  final Church church;
  final String distanceString;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _ChurchCard({
    required this.church,
    required this.distanceString,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(selectedChurch: church),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: lightGold.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.church, color: primaryGold, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      church.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (distanceString.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: primaryGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distanceString,
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
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavorite ? primaryGold : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
