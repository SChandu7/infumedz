import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:infumedz/main.dart';

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
