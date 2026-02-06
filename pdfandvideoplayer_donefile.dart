import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:dio/dio.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MedicalLearningApp());
}

class MedicalLearningApp extends StatelessWidget {
  const MedicalLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medical Learning',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int index = 0;

  final screens = const [HomeScreen(), UserScreen(), AdminScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: "User"),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "Admin",
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Learning Platform")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Learn Medical Concepts",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "• Admin uploads videos & PDFs\n"
              "• Files stored securely on AWS\n"
              "• Users stream videos & view PDFs online\n"
              "• Subscription layer can be added next",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.security, color: Colors.indigo),
                title: Text("Secure Cloud Streaming"),
                subtitle: Text("Udemy / Coursera level architecture"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final String apiUrl = "http://13.203.219.206:8000/infumedz/user/contents/";
  late Future<List<dynamic>> contentFuture;

  @override
  void initState() {
    contentFuture = fetchContents();
    super.initState();
  }

  Future<List<dynamic>> fetchContents() async {
    final res = await http.get(Uri.parse(apiUrl));
    return json.decode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Learning")),
      body: FutureBuilder(
        future: contentFuture,
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final list = snap.data as List;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (c, i) {
              final item = list[i];
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(item["title"]),
                  subtitle: Text(item["description"]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item["video_url"] != null)
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle,
                            color: Colors.indigo,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                url: item["video_url"],
                                title: item["title"],
                              ),
                            ),
                          ),
                        ),
                      if (item["pdf_url"] != null)
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfScreen(
                                pdfUrl: item["pdf_url"],
                                title: item["title"],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  late Widget _videoView; // 🔒 cached forever
  DateTime? _lastControlsShownAt;

  bool controlsVisible = true;
  bool isLocked = false;
  bool isFullscreen = false;

  bool showSeekOverlay = false;
  String seekText = "";

  Timer? _hideTimer;

  final String userId = "USER_102938";

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoController.initialize();
    _videoController.play();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      showControls: false,
    );

    _videoView = Chewie(controller: _chewieController);

    _startAutoHide();
    if (mounted) setState(() {});
  }

  // ================= AUTO HIDE =================
  void _startAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      // ⏱ prevent instant hide (UX polish)
      if (_lastControlsShownAt != null) {
        final elapsed = DateTime.now().difference(_lastControlsShownAt!);
        if (elapsed.inMilliseconds < 300) return;
      }

      setState(() => controlsVisible = false);
    });
  }

  // ================= FULLSCREEN =================
  void _toggleFullscreen() {
    if (isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    setState(() {
      isFullscreen = !isFullscreen;
      controlsVisible = true;
    });

    _startAutoHide();
  }

  // ================= SEEK =================
  void _showSeek(String text) {
    setState(() {
      seekText = text;
      showSeekOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => showSeekOverlay = false);
    });
  }

  void _seekForward() {
    _videoController.seekTo(
      _videoController.value.position + const Duration(seconds: 10),
    );
    _showSeek("+10s");
  }

  void _seekBackward() {
    _videoController.seekTo(
      _videoController.value.position - const Duration(seconds: 10),
    );
    _showSeek("-10s");
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  Widget _buildVideo() {
    return InteractiveViewer(
      panEnabled: isFullscreen,
      scaleEnabled: isFullscreen,
      minScale: 1,
      maxScale: 3,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: _videoView, // 🔒 NEVER rebuilt
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildVideo()),

          // 👆 GESTURE LAYER (ALWAYS)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (isLocked) return;

                setState(() {
                  controlsVisible = !controlsVisible; // toggle show/hide
                });

                // restart auto-hide ONLY when showing controls
                if (controlsVisible) {
                  _lastControlsShownAt = DateTime.now(); // 👈 record time

                  _startAutoHide();
                }
              },
              onDoubleTapDown: (d) {
                if (isLocked) return;

                final w = MediaQuery.of(context).size.width;
                d.localPosition.dx < w / 2 ? _seekBackward() : _seekForward();
              },
            ),
          ),

          // 🔁 SEEK OVERLAY
          if (showSeekOverlay)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  seekText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (controlsVisible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Row(
                  children: [
                    // 🔙 BACK BUTTON
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // 👈 SAME AS APPBAR BACK
                      },
                    ),

                    const SizedBox(width: 8),

                    // 🎬 VIDEO TITLE
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 💧 WATERMARK
          Positioned(
            top: 110,
            right: 20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.20,
                child: Text(
                  userId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 🔒 LOCK BUTTON (ALWAYS WORKS)
          // 🔒 LOCK BUTTON (SMART VISIBILITY)
          if (isLocked || controlsVisible)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height - 250,
              child: AnimatedOpacity(
                opacity: isLocked ? 0.45 : 0.8,
                duration: const Duration(milliseconds: 250),
                child: IconButton(
                  iconSize: 34,
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      isLocked = !isLocked;
                      controlsVisible = true;
                    });

                    // allow user to see feedback
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      _startAutoHide,
                    );
                  },
                ),
              ),
            ),

          // 🎛 CONTROLS (NEVER REMOVED)
          _OverlayControls(
            controller: _videoController,
            visible: controlsVisible,
            locked: isLocked,
            fullscreen: isFullscreen,
            onToggleFullscreen: _toggleFullscreen,
          ),
        ],
      ),
    );
  }
}

class _OverlayControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool visible;
  final bool locked;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;

  const _OverlayControls({
    Key? key,
    required this.controller,
    required this.visible,
    required this.locked,
    required this.fullscreen,
    required this.onToggleFullscreen,
  }) : super(key: key);

  @override
  State<_OverlayControls> createState() => _OverlayControlsState();
}

class _OverlayControlsState extends State<_OverlayControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !widget.visible || widget.locked,
        child: AnimatedOpacity(
          opacity: widget.visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            color: Colors.black.withOpacity(0.15),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(widget.controller.value.position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _format(widget.controller.value.duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔴 PROGRESS BAR
                SizedBox(
                  height: 3, // overall touch area height
                  child: Transform.scale(
                    scaleY: 2.0, // ⬅️ controls actual thickness
                    child: VideoProgressIndicator(
                      widget.controller,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero, // removes unwanted spacing
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFFF9800), // VLC orange
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ⏯ CONTROLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      iconSize: 28,
                      onPressed: () => widget.controller.seekTo(
                        widget.controller.value.position -
                            const Duration(seconds: 10),
                      ),
                    ),

                    IconButton(
                      iconSize: 54,
                      icon: Icon(
                        widget.controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        widget.controller.value.isPlaying
                            ? widget.controller.pause()
                            : widget.controller.play();
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      iconSize: 28,
                      onPressed: () => widget.controller.seekTo(
                        widget.controller.value.position +
                            const Duration(seconds: 10),
                      ),
                    ),

                    IconButton(
                      icon: Icon(
                        widget.fullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      iconSize: 28,
                      onPressed: widget.onToggleFullscreen,
                    ),
                  ],
                ),

                // ⏱ TIME LABEL
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PdfScreen extends StatefulWidget {
  final String pdfUrl; // ✅ INTERNET URL
  final String title;

  const PdfScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  bool isReady = false;
  String? localPath;
  int totalPages = 0;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  // ================= DOWNLOAD FROM URL =================
  Future<void> _preparePdf() async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/${widget.title}.pdf");

    if (!await file.exists()) {
      await Dio().download(widget.pdfUrl, file.path);
    }

    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                "${currentPage + 1}/$totalPages",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: false,
                  pageSnap: false,
                  nightMode: false,
                  onRender: (pages) {
                    setState(() {
                      totalPages = pages ?? 0;
                      isReady = true;
                    });
                  },
                  onPageChanged: (page, _) {
                    setState(() => currentPage = page ?? 0);
                  },
                ),
                if (!isReady) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  File? video;
  File? pdf;

  final ImagePicker _picker = ImagePicker();

  final String uploadUrl = "http://13.203.219.206:8000/infumedz/upload/";

  // ================= VIDEO PICK (SAFE) =================
  Future<void> pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        video = File(picked.path);
      });
    }
  }

  // ================= PDF PICK (SAFE) =================
  Future<void> pickPdf() async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      fileExtensionsFilter: ['pdf'],
    );

    final String? filePath = await FlutterFileDialog.pickFile(params: params);

    if (filePath != null) {
      setState(() {
        pdf = File(filePath);
      });
    }
  }

  // ================= UPLOAD =================
  Future<void> upload() async {
    if (video == null && pdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select video or PDF first")),
      );
      return;
    }

    final req = http.MultipartRequest("POST", Uri.parse(uploadUrl));

    req.fields["title"] = "Human Anatomy Basics";
    req.fields["description"] = "Medical content upload";
    req.fields["content_type"] = "BOTH";

    if (video != null) {
      req.files.add(await http.MultipartFile.fromPath("video", video!.path));
    }

    if (pdf != null) {
      req.files.add(await http.MultipartFile.fromPath("pdf", pdf!.path));
    }

    final response = await req.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploaded Successfully")));

      setState(() {
        video = null;
        pdf = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed (${response.statusCode})")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Upload")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(video == null ? "Select Video" : "Video Selected"),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: pickPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(pdf == null ? "Select PDF" : "PDF Selected"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: upload,
              child: const Text("Upload to Backend"),
            ),
          ],
        ),
      ),
    );
  }
}
