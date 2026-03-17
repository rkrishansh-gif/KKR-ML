// lib/screens/video_player_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String pdfUrl;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.pdfUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _ytController;
  final _noScreenshot = NoScreenshot.instance;

  Timer? _watermarkTimer;
  double _wmLeft      = 40;
  double _wmTop       = 30;
  final  _random      = Random();
  String _userPhone   = '';
  bool   _hasError    = false;
  bool   _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _blockScreenCapture();
    _loadUserPhone();
    _initPlayer();
  }

  void _blockScreenCapture() async {
    await _noScreenshot.screenshotOff();
  }

  void _loadUserPhone() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userPhone = user.phoneNumber ?? user.email ?? '';
      });
    }
  }

  void _initPlayer() {
    final id = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    _ytController = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        controlsVisibleAtStart: true,
        hideControls: false,
        forceHD: false,
        useHybridComposition: true,
      ),
    );
    _ytController!.addListener(_onPlayerUpdate);
  }

  void _onPlayerUpdate() {
    if (!mounted) return;

    if (_ytController!.value.isReady && _watermarkTimer == null) {
      _startWatermark();
    }

    final buffering =
        _ytController!.value.playerState == PlayerState.buffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  void _startWatermark() {
    _watermarkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _wmLeft = 16 + _random.nextDouble() * 160;
        _wmTop  = 16 + _random.nextDouble() * 70;
      });
    });
  }

  Future<void> _openPdf() async {
    if (widget.pdfUrl.isEmpty) return;
    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _ytController?.removeListener(_onPlayerUpdate);
    _ytController?.dispose();
    _watermarkTimer?.cancel();
    _noScreenshot.screenshotOn();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorScreen();
    if (_ytController == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
      onExitFullScreen: () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]),
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF6C63FF),
        progressColors: const ProgressBarColors(
          playedColor:   Color(0xFF6C63FF),
          handleColor:   Color(0xFF3B82F6),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
        bottomActions: [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
          const PlaybackSpeedButton(),
          FullScreenButton(),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded, color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                fontSize: 15, color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Player + Watermark + Buffer ────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  final videoH = constraints.maxWidth * 9 / 16;
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: Stack(
                      children: [
                        player,

                        // Buffering spinner
                        if (_isBuffering)
                          Positioned(
                            left: 0, top: 0,
                            width: constraints.maxWidth,
                            height: videoH,
                            child: const Center(
                              child: SizedBox(
                                width: 30, height: 30,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6C63FF), strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),

                        // Watermark
                        if (_userPhone.isNotEmpty)
                          Positioned(
                            left: 0, top: 0,
                            width: constraints.maxWidth,
                            height: videoH,
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(seconds: 3),
                                  curve: Curves.easeInOut,
                                  left: _wmLeft,
                                  top: _wmTop,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.22,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _userPhone,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // ── Info Section ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title — overflow safe
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white, fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700, fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          if (widget.pdfUrl.isNotEmpty) ...[
                            Expanded(
                              child: _actionBtn(
                                Icons.picture_as_pdf_rounded,
                                'Notes',
                                Colors.orange,
                                _openPdf,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: _actionBtn(
                              Icons.bookmark_outline_rounded,
                              'Bookmark',
                              const Color(0xFF6C63FF),
                              () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildSpeedSelector(),
                      const SizedBox(height: 16),

                      // Security badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security_rounded, color: Colors.red, size: 15),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This video is protected. Screen recording is blocked.',
                                style: TextStyle(
                                  color: Colors.red, fontSize: 11,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Speed Selector ───────────────────────────────────────────────────────────

  Widget _buildSpeedSelector() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Playback Speed', style: TextStyle(
          color: Colors.white54, fontFamily: 'Poppins', fontSize: 13,
        )),
        const SizedBox(height: 8),
        // Wrap handles overflow on very small screens
        Wrap(
          spacing: 8, runSpacing: 8,
          children: speeds.map((speed) {
            final isSelected =
                (_ytController?.value.playbackRate ?? 1.0) == speed;
            return GestureDetector(
              onTap: () {
                _ytController?.setPlaybackRate(speed);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF1E1E30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white12,
                  ),
                ),
                child: Text('${speed}x', style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontFamily: 'Poppins', fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Action Button ────────────────────────────────────────────────────────────

  Widget _actionBtn(
    IconData icon, String label, Color color, VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color, fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Screen ─────────────────────────────────────────────────────────────

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white, fontFamily: 'Poppins', fontSize: 15,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded, color: Colors.red, size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Invalid YouTube URL',
                style: TextStyle(
                  color: Colors.white, fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600, fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.videoUrl,
                style: const TextStyle(
                  color: Colors.white30, fontFamily: 'Poppins', fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                    ),
                  ),
                  child: const Text('Go Back', style: TextStyle(
                    color: Color(0xFF6C63FF), fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}