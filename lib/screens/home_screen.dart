// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'batch_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  int _bottomNavIndex = 0;

  String _userName = '';
  String _userInitial = '?';

  final List<String> _categories = [
    'All', 'Physics', 'Chemistry', 'Maths', 'Biology'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final name = (doc.data()?['name'] ?? '').toString().trim();
      if (mounted) {
        setState(() {
          _userName    = name;
          _userInitial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        });
      }
    } catch (_) {}
  }

  void _onBottomNavTap(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) => _loadUserName());
      return;
    }
    if (index == _bottomNavIndex) return;
    setState(() => _bottomNavIndex = index);

    if (index == 1 || index == 2) {
      final label = index == 1 ? 'My Batches' : 'Progress Tracker';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$label — coming soon!'),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      setState(() => _bottomNavIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildCategoryFilter(),
            Expanded(child: _buildBatchList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final screenW = MediaQuery.of(context).size.width;
    // Responsive font — smaller on narrow screens
    final titleSize = screenW < 360 ? 18.0 : 22.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text section — Flexible so it never pushes icons off screen
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty ? 'Hey, $_userName 👋' : 'Welcome 👋',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'KKR ML Academy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Notification button
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white, size: 20,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          GestureDetector(
            onTap: () => _onBottomNavTap(3),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF6C63FF),
              child: Text(
                _userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Filter ──────────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1E1E30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Batch List ───────────────────────────────────────────────────────────────

  Widget _buildBatchList() {
    Query query =
        FirebaseFirestore.instance.collection('batches');
    if (_selectedCategoryIndex != 0) {
      query = query.where(
        'subject',
        isEqualTo: _categories[_selectedCategoryIndex],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      key: ValueKey(_selectedCategoryIndex),
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        final batches = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final data = batches[index].data() as Map<String, dynamic>;
            return _BatchCard(
              batchId:       batches[index].id,
              title:         data['title']         ?? 'Batch',
              subject:       data['subject']        ?? 'General',
              price:         data['price']          ?? 'Free',
              totalLectures: data['totalLectures']  ?? 0,
              thumbnailUrl:  data['thumbnailUrl']   ?? '',
              teacher:       data['teacher']        ?? 'Instructor',
              isLive:        data['isLive']         ?? false,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final noFilter = _selectedCategoryIndex == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noFilter ? Icons.school_outlined : Icons.filter_list_rounded,
              size: 56,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              noFilter
                  ? 'No batches yet'
                  : 'No ${_categories[_selectedCategoryIndex]} batches',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38, fontFamily: 'Poppins', fontSize: 15,
              ),
            ),
            if (!noFilter) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = 0),
                child: const Text(
                  'Show all batches',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline_rounded),
            label: 'My Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Batch Card ───────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  final String batchId, title, subject, price, thumbnailUrl, teacher;
  final int totalLectures;
  final bool isLive;

  const _BatchCard({
    required this.batchId,
    required this.title,
    required this.subject,
    required this.price,
    required this.totalLectures,
    required this.thumbnailUrl,
    required this.teacher,
    required this.isLive,
  });

  Color get _color {
    switch (subject.toLowerCase()) {
      case 'physics':   return const Color(0xFF3B82F6);
      case 'chemistry': return const Color(0xFF10B981);
      case 'maths':     return const Color(0xFFF59E0B);
      case 'biology':   return const Color(0xFFEC4899);
      default:          return const Color(0xFF6C63FF);
    }
  }

  IconData get _icon {
    switch (subject.toLowerCase()) {
      case 'physics':   return Icons.electric_bolt_rounded;
      case 'chemistry': return Icons.science_rounded;
      case 'maths':     return Icons.functions_rounded;
      case 'biology':   return Icons.biotech_rounded;
      default:          return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BatchDetailScreen(batchId: batchId, batchTitle: title),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            _buildInfo(context),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail ──

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // Background gradient / image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color.withOpacity(0.8), _color.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: thumbnailUrl.isEmpty
                ? Center(child: Icon(_icon, size: 50, color: Colors.white24))
                : Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        Center(child: Icon(_icon, size: 50, color: Colors.white24)),
                  ),
          ),

          // LIVE badge
          if (isLive)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('LIVE', style: TextStyle(
                      color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                    )),
                  ],
                ),
              ),
            ),

          // Subject tag
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _color.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 11, color: _color),
                  const SizedBox(width: 4),
                  Text(subject, style: TextStyle(
                    color: _color, fontSize: 11,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info ──

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w600, fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Teacher + Lectures row
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  teacher,
                  style: const TextStyle(
                    color: Colors.white38, fontSize: 12, fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.play_lesson_outlined, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '$totalLectures Lectures',
                style: const TextStyle(
                  color: Colors.white38, fontSize: 12, fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price + Enroll row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  price == 'Free' ? '🎁 Free' : '₹$price',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600,
                    fontSize: 12, fontFamily: 'Poppins',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Enroll Now →',
                  style: TextStyle(
                    color: Colors.white70, fontSize: 12, fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}