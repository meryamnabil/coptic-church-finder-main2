import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/church_model.dart';
import '../providers/church_provider.dart';
import 'add_church_screen.dart';
import 'churches_list_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color backgroundBeige = Color(0xFFF5EFE6);

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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient & Search Trigger
            Container(
              padding: const EdgeInsets.all(20),
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
                      Image.asset("assets/images/Logo.png", width: 50),
                      const SizedBox(width: 10),
                      const Text(
                        "دليل الكنائس القبطية",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChurchSearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
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
            ),
            const SizedBox(height: 25),

            // Quick Actions Buttons
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickButton(
                    icon: Icons.location_on,
                    title: "الأقرب إليك",
                    screen: MapScreen(),
                  ),
                  _QuickButton(
                    icon: Icons.church,
                    title: "الكنائس",
                    screen: ChurchesListScreen(),
                  ),
                  _QuickButton(
                    icon: Icons.star,
                    title: "المفضلة",
                    screen: FavoritesScreen(),
                  ),
                  _QuickButton(
                    icon: Icons.add,
                    title: "إضافة كنيسة",
                    screen: AddChurchScreen(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Featured Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "كنائس مميزة",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Featured List Horizontal
            SizedBox(
              height: 180,
              child: Consumer<ChurchProvider>(
                builder: (context, churchProvider, child) {
                  final featuredChurches =
                      churchProvider.churches.take(3).toList();

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
            ),
            const SizedBox(height: 30),
          ],
        ),
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      church.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios,
                    size: 12,
                    color: primaryGold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? screen;

  const _QuickButton({required this.icon, required this.title, this.screen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: primaryGold, size: 26),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Search Screen
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
        churches.where((church) {
          final queryLower = _query.toLowerCase();
          return church.name.toLowerCase().contains(queryLower) ||
              church.address.toLowerCase().contains(queryLower);
        }).toList();

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
// Helper Widget for Image rendering
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
