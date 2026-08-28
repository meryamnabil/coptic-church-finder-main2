import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_model.dart';
import '../providers/church_provider.dart';
import '../providers/location_provider.dart';
import 'map_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color lightGold = Color(0xFFF5E6D3);
const Color backgroundBeige = Color(0xFFF5EFE6);

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChurchProvider, LocationProvider>(
      builder: (context, churchProvider, locationProvider, _) {
        final favorites = churchProvider.favoriteChurches;

        return Scaffold(
          backgroundColor: backgroundBeige,
          appBar: AppBar(
            title: const Text(
              'الكنائس المفضلة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
          body:
              favorites.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final church = favorites[index];
                      return _FavoriteCard(
                        church: church,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(selectedChurch: church),
                            ),
                          );
                        },
                        onRemove:
                            () => churchProvider.toggleFavorite(church.id),
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGold.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 64,
                color: primaryGold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد كنائس مفضلة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على أيقونة القلب على أي كنيسة لإضافتها إلى قائمتك المفضلة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Church church;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.church,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFile =
        church.imageUrl.isNotEmpty && !church.imageUrl.startsWith('assets/');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      width: double.infinity,
                      child:
                          church.imageUrl.isNotEmpty
                              ? (isFile
                                  ? Image.file(
                                    File(church.imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _placeholder(),
                                  )
                                  : Image.asset(
                                    church.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _placeholder(),
                                  ))
                              : _placeholder(),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            church.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: primaryGold,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  church.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                left: 8, // تعديل الموضع ليتناسب مع الواجهة العربية
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: lightGold.withOpacity(0.4),
      child: const Center(
        child: Icon(Icons.church, color: primaryGold, size: 40),
      ),
    );
  }
}
