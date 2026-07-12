import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/church_provider.dart';

// ─── Theme Colors ────────────────────────────────────────────────
const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color lightGold = Color(0xFFF5E6D3);

class ChurchesListScreen extends StatelessWidget {
  const ChurchesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "كل الكنائس",
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
      body: Consumer<ChurchProvider>(
        builder: (context, churchProvider, _) {
          final churches = churchProvider.churches;

          if (churches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(primaryGold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: churches.length,
            itemBuilder:
                (context, index) => _ChurchCard(church: churches[index]),
          );
        },
      ),
    );
  }
}

// ─── Extracted Clean Card Widget ─────────────────────────────────
class _ChurchCard extends StatelessWidget {
  final dynamic church;
  const _ChurchCard({required this.church});

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
        onTap: () {}, // انتقال لصفحة التفاصيل لاحقاً
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // الأيقونة
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

              // النصوص
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
                  ],
                ),
              ),

              // السهم
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
