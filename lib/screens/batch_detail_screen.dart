// lib/screens/batch_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;
  final String batchTitle;

  const BatchDetailScreen({
    super.key,
    required this.batchId,
    required this.batchTitle,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LiveTab(batchId: widget.batchId),
                  _LecturesTab(batchId: widget.batchId),
                  _NotesTab(batchId: widget.batchId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool innerBoxIsScrolled) {
    // Responsive expanded height
    final screenH = MediaQuery.of(context).size.height;
    final expandedH = (screenH * 0.22).clamp(160.0, 220.0);

    return SliverAppBar(
      expandedHeight: expandedH,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // centerTitle keeps title from overflowing on small screens
        centerTitle: false,
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
        title: Text(
          widget.batchTitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF0F0F1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 72,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        indicatorWeight: 3,
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins', fontSize: 12,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.live_tv_rounded, size: 17), text: 'Live'),
          Tab(icon: Icon(Icons.video_library_rounded, size: 17), text: 'Lectures'),
          Tab(icon: Icon(Icons.description_outlined, size: 17), text: 'Notes'),
        ],
      ),
    );
  }
}

// ─── LIVE TAB ─────────────────────────────────────────────────────────────────

class _LiveTab extends StatelessWidget {
  final String batchId;
  const _LiveTab({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('lectures')
          .where('isLive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _noLiveState();
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _LiveCard(
              title:    data['title']    ?? 'Live Class',
              videoUrl: data['videoUrl'] ?? '',
              pdfUrl:   data['pdfUrl']   ?? '',
            );
          },
        );
      },
    );
  }

  Widget _noLiveState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E30),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Icon(Icons.live_tv_rounded, size: 44, color: Colors.red),
          ),
          const SizedBox(height: 20),
          const Text(
            'No live class right now',
            style: TextStyle(
              color: Colors.white60, fontFamily: 'Poppins', fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When a live class starts, it will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white30, fontFamily: 'Poppins', fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final String title, videoUrl, pdfUrl;
  const _LiveCard({
    required this.title,
    required this.videoUrl,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            title: title, videoUrl: videoUrl, pdfUrl: pdfUrl,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.live_tv_rounded, color: Colors.red, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIVE badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '● LIVE',
                      style: TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600, fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}

// ─── LECTURES TAB ─────────────────────────────────────────────────────────────

class _LecturesTab extends StatelessWidget {
  final String batchId;
  const _LecturesTab({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('lectures')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            Icons.video_library_rounded,
            'No lectures yet',
            'Lectures will appear here once added',
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _LectureCard(
              index:    i + 1,
              title:    data['title']    ?? 'Lecture',
              duration: data['duration'] ?? '',
              videoUrl: data['videoUrl'] ?? '',
              pdfUrl:   data['pdfUrl']   ?? '',
            );
          },
        );
      },
    );
  }
}

class _LectureCard extends StatelessWidget {
  final int index;
  final String title, duration, videoUrl, pdfUrl;

  const _LectureCard({
    required this.index,
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            title: title, videoUrl: videoUrl, pdfUrl: pdfUrl,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Index box
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins', fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500, fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(
                            color: Colors.white38, fontSize: 12, fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Play button
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded, color: Color(0xFF6C63FF), size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NOTES TAB ────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final String batchId;
  const _NotesTab({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('lectures')
          .where('pdfUrl', isNotEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            Icons.description_outlined,
            'No notes yet',
            'PDF notes will appear here once added',
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _NoteCard(
              title:  data['title']  ?? 'Notes',
              pdfUrl: data['pdfUrl'] ?? '',
            );
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title, pdfUrl;
  const _NoteCard({required this.title, required this.pdfUrl});

  Future<void> _openPdf() async {
    if (pdfUrl.isEmpty) return;
    final uri = Uri.tryParse(pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // PDF icon box
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded, color: Colors.orange, size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500, fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'PDF Notes',
                  style: TextStyle(
                    color: Colors.white38, fontSize: 12, fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Download / Open button
          GestureDetector(
            onTap: _openPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.orange, fontSize: 12,
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED ───────────────────────────────────────────────────────────────────

Widget _emptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38, fontFamily: 'Poppins', fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white24, fontFamily: 'Poppins', fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}