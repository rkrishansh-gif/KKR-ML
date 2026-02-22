import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart'; // ← Add this import

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> lectureData;

  VideoPlayerScreen({required this.lectureData});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final _noScreenshot = NoScreenshot.instance;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _enableSecurity();
    _initPlayer();
  }

  _enableSecurity() async {
    await _noScreenshot.screenshotOff();
  }

  _initPlayer() {
    String? videoId;

    // Extract video ID from YouTube URL
    if (widget.lectureData['videoUrl'] != null) {
      videoId = YoutubePlayer.convertUrlToId(widget.lectureData['videoUrl']);
    }

    if (videoId == null) {
      videoId = 'dQw4w9WgXcQ'; // Fallback video
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: true,
        loop: false,
        isLive: widget.lectureData['isLive'] ?? false,
        controlsVisibleAtStart: true,
      ),
    );
  }

  Future<void> _downloadPDF() async {
    if (widget.lectureData['pdfUrl'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No PDF available for this lecture')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      String pdfUrl = widget.lectureData['pdfUrl'];
      String fileName = '${widget.lectureData['title']}.pdf';

      // Get download directory
      var dir = await getApplicationDocumentsDirectory();
      String savePath = '${dir.path}/$fileName';

      Dio dio = Dio();
      await dio.download(
        pdfUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Downloaded Successfully!'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () {
              OpenFile.open(savePath); // ← This will now work
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download Failed: $e')));
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lectureData['title'] ?? 'Video Player',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Color(0xFF6B46C1),
      ),
      body: Column(
        children: [
          // Video Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Color(0xFF6B46C1),
            onReady: () {},
            bottomActions: [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              FullScreenButton(),
            ],
          ),

          // Watermark - User Info
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black.withOpacity(0.8),
            child: Text(
              'User: $userPhone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lecture Title
                  Text(
                    widget.lectureData['title'] ?? 'Untitled Lecture',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Lecture Info
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        widget.lectureData['duration'] ?? '45 min',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      if (widget.lectureData['isLive'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Download Options
                  Text(
                    'Resources',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  // PDF Download Button
                  if (widget.lectureData['pdfUrl'] != null)
                    Card(
                      child: InkWell(
                        onTap: _isDownloading ? null : _downloadPDF,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lecture Notes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    if (_isDownloading)
                                      Column(
                                        children: [
                                          LinearProgressIndicator(
                                            value: _downloadProgress,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.red,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Download PDF',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isDownloading)
                                Icon(Icons.download, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Security Warning
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Screenshots and screen recording are blocked. Your mobile number is displayed as a watermark for security.',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
