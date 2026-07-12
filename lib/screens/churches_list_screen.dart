import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/church_provider.dart';
import '../providers/location_provider.dart';

// ─── Theme Colors ────────────────────────────────────────────────
const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color lightGold = Color(0xFFF5E6D3);

class ChurchesListScreen extends StatefulWidget {
  const ChurchesListScreen({super.key});

  @override
  State<ChurchesListScreen> createState() => _ChurchesListScreenState();
}

class _ChurchesListScreenState extends State<ChurchesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  double? _distanceTo(dynamic church, LocationProvider locationProvider) {
    final pos = locationProvider.currentPosition;
    if (pos == null) return null;

    const R = 6371000.0;
    final dLat = (church.latitude - pos.latitude) * math.pi / 180;
    final dLon = (church.longitude - pos.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(pos.latitude * math.pi / 180) *
            math.cos(church.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChurchProvider, LocationProvider>(
      builder: (context, churchProvider, locationProvider, _) {
        final churches = List.from(churchProvider.churches);

        if (locationProvider.currentPosition != null) {
          churches.sort((a, b) {
            final distA = _distanceTo(a, locationProvider) ?? double.infinity;
            final distB = _distanceTo(b, locationProvider) ?? double.infinity;
            return distA.compareTo(distB);
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: const Text(
              "Nearest Churches",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkGold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: lightGold.withOpacity(0.5), height: 1),
            ),
          ),
          body:
              churchProvider.churches.isEmpty
                  ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(primaryGold),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: churches.length,
                    itemBuilder: (context, index) {
                      final church = churches[index];
                      final dist = _distanceTo(church, locationProvider);

                      return _ChurchCard(
                        church: church,
                        distanceString: _formatDistance(dist),
                      );
                    },
                  ),
        );
      },
    );
  }
}

class _ChurchCard extends StatelessWidget {
  final dynamic church;
  final String distanceString;

  const _ChurchCard({required this.church, required this.distanceString});

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
        onTap: () {},
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
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
