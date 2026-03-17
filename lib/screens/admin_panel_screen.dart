// lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin Panel', style: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white,
          fontSize: 17,
        )),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text('Admin', style: TextStyle(
                  color: Colors.amber, fontSize: 11,
                  fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                )),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Batches'),
            Tab(icon: Icon(Icons.play_lesson_rounded, size: 18), text: 'Lectures & Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BatchesTab(onGoToLectures: () => _tabController.animateTo(1)),
          const _LecturesTab(),
        ],
      ),
    );
  }
}

// ─── BATCHES TAB ──────────────────────────────────────────────────────────────

class _BatchesTab extends StatelessWidget {
  final VoidCallback onGoToLectures;
  const _BatchesTab({required this.onGoToLectures});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Batch', style: TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w600,
        )),
        onPressed: () => _showBatchSheet(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('batches').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState('No batches yet', 'Tap + to add your first batch');
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _BatchCard(
                docId: docs[i].id,
                data: data,
                onAddLecture: onGoToLectures,
              );
            },
          );
        },
      ),
    );
  }

  void _showBatchSheet(BuildContext context,
      {String? docId, Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BatchFormSheet(docId: docId, existing: existing),
    );
  }
}

// ─── BATCH CARD ───────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onAddLecture;

  const _BatchCard(
      {required this.docId, required this.data, required this.onAddLecture});

  Color get _color {
    switch ((data['subject'] ?? '').toString().toLowerCase()) {
      case 'physics':   return const Color(0xFF3B82F6);
      case 'chemistry': return const Color(0xFF10B981);
      case 'maths':     return const Color(0xFFF59E0B);
      case 'biology':   return const Color(0xFFEC4899);
      default:          return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title   = data['title']   ?? 'Untitled';
    final subject = data['subject'] ?? '';
    final teacher = data['teacher'] ?? '';
    final price   = data['price']   ?? 'Free';
    final total   = data['totalLectures'] ?? 0;
    final isLive  = data['isLive']  ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subject initial box
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      subject.isNotEmpty ? subject[0].toUpperCase() : 'G',
                      style: TextStyle(
                        color: _color, fontSize: 20, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + subtitle — Expanded prevents overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white, fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600, fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subject • $teacher',
                        style: const TextStyle(
                          color: Colors.white38, fontFamily: 'Poppins', fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Live toggle — shrinkwrapped
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Live', style: TextStyle(
                      color: Colors.white30, fontSize: 10, fontFamily: 'Poppins',
                    )),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isLive,
                        activeColor: Colors.red,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => FirebaseFirestore.instance
                            .collection('batches')
                            .doc(docId)
                            .update({'isLive': val}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Footer ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _chip(Icons.layers_rounded, '$total Lectures', _color),
                const SizedBox(width: 8),
                _chip(Icons.sell_rounded, price, Colors.green),
                const Spacer(),
                _iconBtn(Icons.edit_outlined, Colors.white54, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: const Color(0xFF1E1E30),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _BatchFormSheet(docId: docId, existing: data),
                  );
                }),
                const SizedBox(width: 8),
                _iconBtn(Icons.delete_outline_rounded, Colors.red, () => _confirmDelete(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontFamily: 'Poppins',
          )),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Batch?', style: TextStyle(
          color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600,
        )),
        content: Text(
          'Delete "${data['title']}"?\nAll lectures will also be deleted.',
          style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('batches').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }
}

// ─── BATCH FORM SHEET ─────────────────────────────────────────────────────────

class _BatchFormSheet extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;
  const _BatchFormSheet({this.docId, this.existing});

  @override
  State<_BatchFormSheet> createState() => _BatchFormSheetState();
}

class _BatchFormSheetState extends State<_BatchFormSheet> {
  final _formKey  = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _thumbCtrl;
  String _subject = 'Physics';
  bool   _saving  = false;

  final _subjects = ['Physics', 'Chemistry', 'Maths', 'Biology', 'General'];

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.existing?['title']        ?? '');
    _teacherCtrl = TextEditingController(text: widget.existing?['teacher']      ?? '');
    _priceCtrl   = TextEditingController(text: widget.existing?['price']        ?? 'Free');
    _thumbCtrl   = TextEditingController(text: widget.existing?['thumbnailUrl'] ?? '');
    _subject     = widget.existing?['subject'] ?? 'Physics';
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _teacherCtrl.dispose();
    _priceCtrl.dispose(); _thumbCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      'title':         _titleCtrl.text.trim(),
      'subject':       _subject,
      'teacher':       _teacherCtrl.text.trim(),
      'price':         _priceCtrl.text.trim(),
      'thumbnailUrl':  _thumbCtrl.text.trim(),
      'isLive':        widget.existing?['isLive']        ?? false,
      'totalLectures': widget.existing?['totalLectures'] ?? 0,
    };
    try {
      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('batches').doc(widget.docId).update(payload);
      } else {
        await FirebaseFirestore.instance.collection('batches').add(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets.bottom handles keyboard push-up
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              Text(
                widget.docId != null ? 'Edit Batch' : 'New Batch',
                style: const TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              _field(_titleCtrl,   'Batch Title *',              Icons.title_rounded),
              const SizedBox(height: 12),
              _subjectDrop(),
              const SizedBox(height: 12),
              _field(_teacherCtrl, 'Teacher Name *',             Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _field(_priceCtrl,   'Price  (e.g. Free / 999)',   Icons.sell_rounded),
              const SizedBox(height: 12),
              _field(_thumbCtrl,   'Thumbnail URL (optional)',   Icons.image_outlined, required: false),
              const SizedBox(height: 24),
              _saveBtn(widget.docId != null ? 'Update Batch' : 'Create Batch'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectDrop() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _subject,
          dropdownColor: const Color(0xFF1E1E30),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C63FF)),
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
          items: _subjects
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => _subject = val!),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
      validator: validator ??
          (v) => required && (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Colors.white30, fontFamily: 'Poppins', fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _saveBtn(String label) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(label, style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15,
            )),
    ),
  );
}

// ─── LECTURES & NOTES TAB ─────────────────────────────────────────────────────

class _LecturesTab extends StatefulWidget {
  const _LecturesTab();

  @override
  State<_LecturesTab> createState() => _LecturesTabState();
}

class _LecturesTabState extends State<_LecturesTab> {
  String? _selectedBatchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: _selectedBatchId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C63FF),
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Lecture', style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              )),
              onPressed: () => _showLectureSheet(context),
            ),
      body: Column(
        children: [
          _batchSelector(),
          Expanded(
            child: _selectedBatchId != null
                ? _lectureList()
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: Colors.white24, size: 32),
                        SizedBox(height: 12),
                        Text('Select a batch above', style: TextStyle(
                          color: Colors.white38, fontFamily: 'Poppins',
                        )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _batchSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('batches').snapshots(),
        builder: (context, snapshot) {
          final batches = snapshot.data?.docs ?? [];
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBatchId,
              hint: const Text(
                'Select batch to manage lectures',
                style: TextStyle(
                  color: Colors.white38, fontFamily: 'Poppins', fontSize: 13,
                ),
              ),
              dropdownColor: const Color(0xFF1E1E30),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C63FF),
              ),
              style: const TextStyle(
                color: Colors.white, fontFamily: 'Poppins', fontSize: 14,
              ),
              items: batches.map((b) {
                final d = b.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(
                    d['title'] ?? 'Untitled',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBatchId = val),
            ),
          );
        },
      ),
    );
  }

  Widget _lectureList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(_selectedBatchId)
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
          return _emptyState('No lectures yet', 'Tap + to add the first lecture');
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _LectureCard(
              index: i + 1,
              docId: docs[i].id,
              batchId: _selectedBatchId!,
              data: data,
              onEdit: () => _showLectureSheet(context,
                  docId: docs[i].id, existing: data),
            );
          },
        );
      },
    );
  }

  void _showLectureSheet(BuildContext context,
      {String? docId, Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LectureFormSheet(
        batchId: _selectedBatchId!,
        docId: docId,
        existing: existing,
      ),
    );
  }
}

// ─── LECTURE CARD ─────────────────────────────────────────────────────────────

class _LectureCard extends StatelessWidget {
  final int index;
  final String docId, batchId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  const _LectureCard({
    required this.index,
    required this.docId,
    required this.batchId,
    required this.data,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = (data['videoUrl'] ?? '').toString().isNotEmpty;
    final hasPdf   = (data['pdfUrl']   ?? '').toString().isNotEmpty;
    final title    = data['title']    ?? 'Untitled';
    final duration = data['duration'] ?? '';
    final isLive   = data['isLive']   ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: index + title + live toggle ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('$index', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins', fontSize: 13,
                  )),
                ),
              ),
              const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
                      Text(duration, style: const TextStyle(
                        color: Colors.white38, fontSize: 11, fontFamily: 'Poppins',
                      )),
                    ],
                  ],
                ),
              ),
              // Live toggle
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isLive,
                  activeColor: Colors.red,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => FirebaseFirestore.instance
                      .collection('batches').doc(batchId)
                      .collection('lectures').doc(docId)
                      .update({'isLive': val}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: status chips + edit/delete ──
          Row(
            children: [
              _statusChip(Icons.play_circle_outline_rounded, 'Video',
                  hasVideo ? Colors.green : Colors.white24, hasVideo),
              const SizedBox(width: 8),
              _statusChip(Icons.description_outlined, 'Notes',
                  hasPdf ? Colors.orange : Colors.white24, hasPdf),
              const Spacer(),
              _actionBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: const Color(0xFF6C63FF),
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: Colors.red,
                onTap: () => FirebaseFirestore.instance
                    .collection('batches').doc(batchId)
                    .collection('lectures').doc(docId)
                    .delete(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontFamily: 'Poppins',
          )),
          const SizedBox(width: 3),
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 11, color: color,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: color, fontSize: 12,
              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── LECTURE FORM SHEET ───────────────────────────────────────────────────────

class _LectureFormSheet extends StatefulWidget {
  final String batchId;
  final String? docId;
  final Map<String, dynamic>? existing;

  const _LectureFormSheet(
      {required this.batchId, this.docId, this.existing});

  @override
  State<_LectureFormSheet> createState() => _LectureFormSheetState();
}

class _LectureFormSheetState extends State<_LectureFormSheet> {
  final _formKey     = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _videoCtrl;
  late TextEditingController _pdfCtrl;
  late TextEditingController _durationCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.existing?['title']    ?? '');
    _videoCtrl    = TextEditingController(text: widget.existing?['videoUrl'] ?? '');
    _pdfCtrl      = TextEditingController(text: widget.existing?['pdfUrl']   ?? '');
    _durationCtrl = TextEditingController(text: widget.existing?['duration'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _videoCtrl.dispose();
    _pdfCtrl.dispose();   _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'title':     _titleCtrl.text.trim(),
      'videoUrl':  _videoCtrl.text.trim(),
      'pdfUrl':    _pdfCtrl.text.trim(),
      'duration':  _durationCtrl.text.trim(),
      'isLive':    widget.existing?['isLive'] ?? false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final batchRef   = FirebaseFirestore.instance.collection('batches').doc(widget.batchId);
      final lectureRef = batchRef.collection('lectures');

      if (widget.docId != null) {
        await lectureRef.doc(widget.docId).update(payload);
      } else {
        await lectureRef.add(payload);
        await batchRef.update({'totalLectures': FieldValue.increment(1)});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              Text(
                widget.docId != null ? 'Edit Lecture' : 'Add New Lecture',
                style: const TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Video URL is required. PDF is optional.',
                style: TextStyle(
                  color: Colors.white38, fontSize: 12, fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),

              _field(_titleCtrl, 'Lecture Title *', Icons.title_rounded),
              const SizedBox(height: 12),

              _fieldWithHint(
                ctrl: _videoCtrl,
                hint: 'YouTube URL *',
                icon: Icons.play_circle_outline_rounded,
                subHint: 'https://youtu.be/XXXXX  •  Set Unlisted + Allow Embedding',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'YouTube URL is required';
                  if (!v.contains('youtube') && !v.contains('youtu.be')) {
                    return 'Enter a valid YouTube URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _fieldWithHint(
                ctrl: _pdfCtrl,
                hint: 'PDF / Notes URL (optional)',
                icon: Icons.picture_as_pdf_rounded,
                subHint: 'Firebase Storage link or any direct PDF URL',
                required: false,
              ),
              const SizedBox(height: 12),

              _field(_durationCtrl, 'Duration  (e.g. 45 min)',
                  Icons.timer_outlined, required: false),
              const SizedBox(height: 24),

              _saveBtn(widget.docId != null ? 'Update Lecture' : 'Add Lecture'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(
          color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
      validator: validator ??
          (v) => required && (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Colors.white30, fontFamily: 'Poppins', fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _fieldWithHint({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required String subHint,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(ctrl, hint, icon, required: required, validator: validator),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(subHint, style: const TextStyle(
            color: Colors.white24, fontSize: 11, fontFamily: 'Poppins',
          )),
        ),
      ],
    );
  }

  Widget _saveBtn(String label) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(label, style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15,
            )),
    ),
  );
}

// ─── SHARED HELPERS ───────────────────────────────────────────────────────────

Widget _sheetHandle() => Center(
  child: Container(
    width: 40, height: 4,
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

Widget _emptyState(String title, String subtitle) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.inbox_rounded, size: 56, color: Colors.white12),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(
        color: Colors.white38, fontFamily: 'Poppins', fontSize: 15,
      )),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(
        color: Colors.white24, fontFamily: 'Poppins', fontSize: 12,
      )),
    ],
  ),
);