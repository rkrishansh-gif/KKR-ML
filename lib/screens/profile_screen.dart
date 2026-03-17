// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _name    = 'Student';
  String _phone   = 'Not linked';
  String _initial = 'S';
  bool   _isAdmin = false;
  bool   _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user != null) {
      // Show auth data instantly — no loading spinner
      setState(() {
        _phone   = user.phoneNumber ?? 'Not linked';
        _name    = user.displayName ?? 'Student';
        _initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'S';
        _loading = false;
      });
    } else {
      setState(() {
        _name    = 'Guest User';
        _phone   = 'Not logged in';
        _initial = 'G';
        _loading = false;
      });
      return;
    }

    // Firestore in background
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      final data = doc.data();
      if (data != null) {
        final firestoreName = (data['name'] ?? '').toString().trim();
        setState(() {
          _name    = firestoreName.isNotEmpty ? firestoreName : (user.displayName ?? 'Student');
          _initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'S';
          _isAdmin = data['isAdmin'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(
          color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600,
        )),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  void _showEditName() {
    final ctrl = TextEditingController(text: _name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        // ✅ viewInsets from builder context — keyboard safe
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Edit Name', style: TextStyle(
              color: Colors.white, fontSize: 17,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            )),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white30, fontFamily: 'Poppins'),
                filled: true,
                fillColor: const Color(0xFF0F0F1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final uid = _auth.currentUser?.uid;
                  if (uid != null && ctrl.text.trim().isNotEmpty) {
                    await _firestore
                        .collection('users')
                        .doc(uid)
                        .update({'name': ctrl.text.trim()});
                    setState(() {
                      _name    = ctrl.text.trim();
                      _initial = _name[0].toUpperCase();
                    });
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Save', style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(
          color: Colors.white, fontFamily: 'Poppins',
          fontWeight: FontWeight.w600, fontSize: 17,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: _showEditName,
            tooltip: 'Edit name',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 24),

            _buildSection('ACCOUNT', [
              _tile(Icons.person_outline_rounded, 'Full Name', _name),
              _divider(),
              _tile(Icons.phone_outlined, 'Phone', _phone),
            ]),
            const SizedBox(height: 16),

            _buildSection('SETTINGS', [
              _navTile(Icons.notifications_outlined,  'Notifications',       () {}),
              _divider(),
              _navTile(Icons.lock_outline_rounded,    'Privacy & Security',  () {}),
              _divider(),
              _navTile(Icons.help_outline_rounded,    'Help & Support',      () {}),
              _divider(),
              _navTile(Icons.info_outline_rounded,    'About App',           () {}),
            ]),
            const SizedBox(height: 16),

            if (_isAdmin) ...[
              _adminTile(),
              const SizedBox(height: 16),
            ],

            _signOutTile(),
            const SizedBox(height: 28),

            const Text('v1.0.0 • KKR ML Classes', style: TextStyle(
              color: Colors.white24, fontSize: 11, fontFamily: 'Poppins',
            )),
          ],
        ),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Row(
      children: [
        Container(
          width: 66, height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.28),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: Text(_initial, style: const TextStyle(
              color: Colors.white, fontSize: 24,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            )),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ✅ Flexible so long name + admin badge don't overflow
                  Flexible(
                    child: Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: const Text('Admin', style: TextStyle(
                        color: Colors.amber, fontSize: 10,
                        fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                      )),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _phone,
                style: const TextStyle(
                  color: Colors.white38, fontSize: 13, fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        _statCard('0', 'Enrolled',  Icons.school_rounded,               const Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        _statCard('0', 'Lectures',  Icons.play_circle_outline_rounded,  const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _statCard('0', 'Notes',     Icons.description_outlined,         Colors.orange),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              color: color, fontSize: 18,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            )),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38, fontSize: 11, fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(
            color: Colors.white30, fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins', letterSpacing: 1.5,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 14),
          // ✅ Expanded — value text won't overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  color: Colors.white30, fontSize: 11, fontFamily: 'Poppins',
                )),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 14, fontFamily: 'Poppins',
            ))),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1, indent: 50,
    color: Colors.white.withOpacity(0.05),
  );

  Widget _adminTile() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 14),
            Expanded(child: Text('Admin Panel', style: TextStyle(
              color: Colors.amber, fontFamily: 'Poppins',
              fontWeight: FontWeight.w600, fontSize: 14,
            ))),
            Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _signOutTile() {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 14),
            Expanded(child: Text('Sign Out', style: TextStyle(
              color: Colors.red, fontFamily: 'Poppins',
              fontWeight: FontWeight.w600, fontSize: 14,
            ))),
          ],
        ),
      ),
    );
  }
}