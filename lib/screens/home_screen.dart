import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_model.dart';
import '../providers/church_provider.dart';
import '../providers/location_provider.dart';
import 'add_church_screen.dart';
import 'churches_list_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color backgroundBeige = Color(0xFFF5EFE6);

String normalizeArabic(String input) {
  return input
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') 
      .replaceAll('ـ', '') 
      .toLowerCase()
      .trim();
}

bool churchMatchesQuery(Church church, String query) {
  final normalizedQuery = normalizeArabic(query);
  if (normalizedQuery.isEmpty) return true;

  final queryWords =
      normalizedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

  final target = normalizeArabic(
    '${church.name} ${church.address} ${church.description}',
  );

  return queryWords.every((word) => target.contains(word));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeContent(),
    MapScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE0D8CD), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: backgroundBeige,
          currentIndex: currentIndex,
          selectedItemColor: primaryGold,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "الخريطة"),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: "المفضلة"),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChurchProvider>().loadChurches();
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildDiscoverSection(context),
            const SizedBox(height: 24),
            _buildExploreSection(context),
            const SizedBox(height: 28),
            _sectionTitle("كنائس بالقرب منك"),
            const SizedBox(height: 12),
            _buildNearbySection(context),
            const SizedBox(height: 28),
            _sectionTitle("كنائس مميزة"),
            const SizedBox(height: 15),
            _buildFeaturedSection(context),
            const SizedBox(height: 24),
            _buildChurchOfTheDay(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header (زي ما هو، مع تحسين بسيط في الـ spacing)
  // ---------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGold, darkGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset("assets/images/Logo.png", width: 46),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "دليل الكنائس القبطية",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChurchSearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    "ابحث عن كنيسة...",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // قسم الترحيب / الاكتشاف
  // ---------------------------------------------------------------------
  Widget _buildDiscoverSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundBeige,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_searching, color: primaryGold),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ابحث عن كنيسة قريبة منك",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "اكتشف كنائس الأقباط الأرثوذكس حول موقعك",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.explore, color: Colors.white, size: 18),
            label: const Text(
              "استكشف القريب",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // قسم Explore (4 كروت)
  // ---------------------------------------------------------------------
  Widget _buildExploreSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ExploreCard(
            icon: Icons.location_on,
            label: "الأقرب",
            screen: const MapScreen(),
          ),
          _ExploreCard(
            icon: Icons.church,
            label: "الكنائس",
            screen: const ChurchesListScreen(),
          ),
          _ExploreCard(
            icon: Icons.star,
            label: "المفضلة",
            screen: const FavoritesScreen(),
          ),
          _ExploreCard(
            icon: Icons.add,
            label: "إضافة كنيسة",
            screen: const AddChurchScreen(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // قسم "كنائس بالقرب منك"
  // ---------------------------------------------------------------------
  Widget _buildNearbySection(BuildContext context) {
    return Consumer2<LocationProvider, ChurchProvider>(
      builder: (context, locationProvider, churchProvider, _) {
        if (churchProvider.churches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "لا توجد كنائس متاحة حالياً",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // حالة التحميل
        if (locationProvider.status == LocationStatus.loading ||
            locationProvider.status == LocationStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: primaryGold)),
          );
        }

        // نجح تحديد الموقع
        if (locationProvider.status == LocationStatus.success &&
            locationProvider.currentPosition != null) {
          final nearest = churchProvider.getNearestChurches(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
            count: 3,
          );

          return Column(
            children:
                nearest
                    .map(
                      (entry) => _NearbyChurchCard(
                        church: entry.church,
                        distanceInMeters: entry.distanceInMeters,
                      ),
                    )
                    .toList(),
          );
        }

        // فشل تحديد الموقع (رفض إذن / خدمة معطلة / إلخ) → fallback
        final fallbackChurches = churchProvider.churches.take(3).toList();
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: primaryGold),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "فعّل خدمة الموقع لاكتشاف الكنائس القريبة منك",
                      style: TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (locationProvider.status ==
                              LocationStatus.permissionDeniedForever ||
                          locationProvider.status ==
                              LocationStatus.serviceDisabled) {
                        locationProvider.openSettings();
                      } else {
                        locationProvider.getCurrentLocation();
                      }
                    },
                    child: const Text(
                      "تفعيل",
                      style: TextStyle(
                        color: primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...fallbackChurches.map(
              (c) => _NearbyChurchCard(church: c, distanceInMeters: null),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Consumer<ChurchProvider>(
        builder: (context, churchProvider, child) {
          final featuredChurches = churchProvider.churches.take(3).toList();

          if (featuredChurches.isEmpty) {
            return const Center(
              child: Text(
                "لا توجد كنائس متاحة حالياً",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featuredChurches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemBuilder:
                (context, index) =>
                    _featuredCard(featuredChurches[index], context),
          );
        },
      ),
    );
  }

  Widget _featuredCard(Church church, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MapScreen(selectedChurch: church)),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: _ChurchImageWidget(imageUrl: church.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          church.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkGold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back_ios,
                        size: 12,
                        color: primaryGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    church.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchOfTheDay(BuildContext context) {
    return Consumer<ChurchProvider>(
      builder: (context, churchProvider, _) {
        final churches = churchProvider.churches;
        if (churches.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final dayIndex = now.difference(DateTime(now.year, 1, 1)).inDays;
        final church = churches[dayIndex % churches.length];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryGold, darkGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: _ChurchImageWidget(imageUrl: church.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "كنيسة اليوم",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      church.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      church.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(selectedChurch: church),
                    ),
                  );
                },
                child: const Text(
                  "عرض",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkGold,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// كارت "الاستكشاف" الجديد (بدل الأزرار الدائرية)
// -----------------------------------------------------------------------------
class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget screen;

  const _ExploreCard({
    required this.icon,
    required this.label,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGold, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: darkGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// كارت الكنيسة القريبة
// -----------------------------------------------------------------------------
class _NearbyChurchCard extends StatelessWidget {
  final Church church;
  final double? distanceInMeters;

  const _NearbyChurchCard({required this.church, this.distanceInMeters});

  String get _distanceLabel {
    final d = distanceInMeters;
    if (d == null) return '';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} كم';
    return '${d.toStringAsFixed(0)} م';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MapScreen(selectedChurch: church)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: _ChurchImageWidget(imageUrl: church.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    church.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    church.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (distanceInMeters != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 13, color: primaryGold),
                        const SizedBox(width: 3),
                        Text(
                          _distanceLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
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
            const Icon(Icons.arrow_back_ios, size: 14, color: primaryGold),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Search Screen — دلوقتي بيدور بالكلمة في أي مكان مش بس تطابق متصل
// -----------------------------------------------------------------------------

class ChurchSearchScreen extends StatefulWidget {
  const ChurchSearchScreen({super.key});

  @override
  State<ChurchSearchScreen> createState() => _ChurchSearchScreenState();
}

class _ChurchSearchScreenState extends State<ChurchSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final churches = context.watch<ChurchProvider>().churches;
    final filteredChurches =
        churches
            .where((church) => churchMatchesQuery(church, _query))
            .toList();

    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        backgroundColor: primaryGold,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'ابحث عن كنائس...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
      ),
      body:
          filteredChurches.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 70, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'لم يتم العثور على كنائس',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "لم تجد كنيستك؟",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddChurchScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'أضف كنيستك',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChurches.length,
                itemBuilder: (context, index) {
                  final church = filteredChurches[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(selectedChurch: church),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: backgroundBeige,
                          child: ClipOval(
                            child: _ChurchImageWidget(
                              imageUrl: church.imageUrl,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        title: Text(
                          church.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkGold,
                          ),
                        ),
                        subtitle: Text(
                          church.address,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(
                          Icons.arrow_back_ios,
                          size: 14,
                          color: primaryGold,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper Widget for Image rendering (زي ما هي بدون تغيير)
// -----------------------------------------------------------------------------

class _ChurchImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const _ChurchImageWidget({
    required this.imageUrl,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.church, size: 30, color: primaryGold),
      );
    }

    final bool isFile = !imageUrl.startsWith('assets/');

    if (isFile) {
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.church, size: 30, color: primaryGold),
      );
    }

    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) =>
              const Icon(Icons.church, size: 30, color: primaryGold),
    );
  }
}