import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  BatchDetailScreen({required this.batchId});

  @override
  _BatchDetailScreenState createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<DocumentSnapshot> _batchFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _batchFuture = FirebaseFirestore.instance
        .collection('batches')
        .doc(widget.batchId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _batchFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!['title'] ?? 'Batch Details');
            }
            return Text('Batch Details');
          },
        ),
        backgroundColor: Color(0xFF6B46C1),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'LIVE', icon: Icon(Icons.live_tv)),
            Tab(text: 'LECTURES', icon: Icon(Icons.video_library)),
            Tab(text: 'NOTES', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLiveTab(), _buildLecturesTab(), _buildNotesTab()],
      ),
    );
  }

  Widget _buildLiveTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batchId)
          .collection('lectures')
          .where('isLive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No Live Class Right Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Check back later for live sessions'),
              ],
            ),
          );
        }

        var liveClass = snapshot.data!.docs.first;
        return Padding(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.live_tv, size: 60, color: Colors.red),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        liveClass['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Started at: ${liveClass['startTime'] ?? 'Just now'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/video-player',
                            arguments: {
                              'lectureId': liveClass.id,
                              'batchId': widget.batchId,
                              'title': liveClass['title'],
                              'videoUrl': liveClass['videoUrl'],
                              'pdfUrl': liveClass['pdfUrl'],
                              'isLive': true,
                            },
                          );
                        },
                        icon: Icon(Icons.play_arrow),
                        label: Text('JOIN LIVE CLASS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

  Widget _buildLecturesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batchId)
          .collection('lectures')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('No Lectures Available'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var lecture = snapshot.data!.docs[index];
            return _buildLectureCard(lecture);
          },
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batchId)
          .collection('lectures')
          .where('pdfUrl', isNotEqualTo: null)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('No Notes Available'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var lecture = snapshot.data!.docs[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: Text(
                  lecture['title'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Lecture Notes'),
                trailing: Icon(Icons.download),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/video-player',
                    arguments: {
                      'lectureId': lecture.id,
                      'batchId': widget.batchId,
                      'title': lecture['title'],
                      'videoUrl': lecture['videoUrl'],
                      'pdfUrl': lecture['pdfUrl'],
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLectureCard(QueryDocumentSnapshot lecture) {
    bool isLive = lecture['isLive'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/video-player',
            arguments: {
              'lectureId': lecture.id,
              'batchId': widget.batchId,
              'title': lecture['title'],
              'videoUrl': lecture['videoUrl'],
              'pdfUrl': lecture['pdfUrl'],
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isLive
                      ? Colors.red.withOpacity(0.1)
                      : Color(0xFF6B46C1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLive ? Icons.live_tv : Icons.play_circle_fill,
                  color: isLive ? Colors.red : Color(0xFF6B46C1),
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          lecture['duration'] ?? '45 min',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 12),
                        if (lecture['pdfUrl'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 14,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text('PDF', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isLive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
