import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  bool _initialized = false;
  bool _hasError = false;
  bool _controlsVisible = true;
  bool _isLocked = false;
  bool _isFullscreen = false;
  bool _showSeekOverlay = false;
  bool _showSpeedMenu = false;

  String _seekText = "";
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  double _brightness = 1.0;

  Timer? _hideTimer;
  Timer? _progressTimer;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController.pause();
    }
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await _videoController.initialize();
      _videoController.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: false,
      );

      if (mounted) setState(() => _initialized = true);
      _startAutoHide();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  // ── AUTO HIDE ──────────────────────────────
  void _startAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_showSpeedMenu) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onTap() {
    if (_isLocked) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startAutoHide();
  }

  // ── SEEK ───────────────────────────────────
  void _seekBy(int seconds) {
    final current = _videoController.value.position;
    final target = current + Duration(seconds: seconds);
    _videoController.seekTo(target);
    setState(() {
      _seekText = seconds > 0 ? "+${seconds}s" : "${seconds}s";
      _showSeekOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSeekOverlay = false);
    });
  }

  // ── FULLSCREEN ─────────────────────────────
  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _startAutoHide();
  }

  // ── SPEED ──────────────────────────────────
  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _showSpeedMenu = false;
    });
    _videoController.setPlaybackSpeed(speed);
    _startAutoHide();
  }

  // ── FORMAT TIME ────────────────────────────
  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildError();
    if (!_initialized) return _buildLoading();

    final val = _videoController.value;
    final position = val.position;
    final duration = val.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isFullscreen,
        child: Stack(
          children: [
            // ── VIDEO ──────────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onDoubleTapDown: (d) {
                  if (_isLocked) return;
                  final w = MediaQuery.of(context).size.width;
                  d.localPosition.dx < w / 2 ? _seekBy(-10) : _seekBy(10);
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: val.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              ),
            ),

            // ── SEEK OVERLAY ───────────────────
            if (_showSeekOverlay)
              Center(
                child: AnimatedOpacity(
                  opacity: _showSeekOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _seekText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // ── BUFFERING INDICATOR ────────────
            if (val.isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF9800),
                  strokeWidth: 2.5,
                ),
              ),

            // ── WATERMARK ──────────────────────
            Positioned(
              top: 100,
              right: 16,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.18,
                  child: Text(
                    "INFUMEDZ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            // ── CONTROLS OVERLAY ───────────────
            if (_controlsVisible && !_isLocked) ...[
              // TOP BAR
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

              // CENTER CONTROLS
              Center(child: _buildCenterControls()),

              // BOTTOM BAR
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(progress, position, duration),
              ),
            ],

            // ── LOCK BUTTON (ALWAYS VISIBLE) ───
            if (_controlsVisible || _isLocked)
              Positioned(
                left: 12,
                top: MediaQuery.of(context).size.height / 2 - 28,
                child: _buildLockButton(),
              ),

            // ── SPEED MENU ─────────────────────
            if (_showSpeedMenu) _buildSpeedMenu(),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Speed button
          GestureDetector(
            onTap: () {
              setState(() => _showSpeedMenu = !_showSpeedMenu);
              _hideTimer?.cancel();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "${_playbackSpeed}x",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }

  // ── CENTER CONTROLS ────────────────────────
  Widget _buildCenterControls() {
    final val = _videoController.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _controlBtn(Icons.replay_10, () => _seekBy(-10), size: 36),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: () {
            val.isPlaying ? _videoController.pause() : _videoController.play();
            _startAutoHide();
          },
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: Icon(
              val.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(width: 28),
        _controlBtn(Icons.forward_10, () => _seekBy(10), size: 36),
      ],
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap, {double size = 28}) {
    return GestureDetector(
      onTap: () {
        onTap();
        _startAutoHide();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  // ── BOTTOM BAR ─────────────────────────────
  Widget _buildBottomBar(
    double progress,
    Duration position,
    Duration duration,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _format(duration),
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFFFF9800),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFF9800),
              overlayColor: const Color(0x33FF9800),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final target = Duration(
                  milliseconds: (v * duration.inMilliseconds).toInt(),
                );
                _videoController.seekTo(target);
                _startAutoHide();
              },
            ),
          ),

          const SizedBox(height: 4),

          // Volume row
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white60, size: 18),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      _videoController.setVolume(v);
                      _startAutoHide();
                    },
                  ),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white60, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  // ── LOCK BUTTON ────────────────────────────
  Widget _buildLockButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLocked = !_isLocked;
          _controlsVisible = true;
        });
        if (!_isLocked) _startAutoHide();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isLocked ? Colors.orange.withOpacity(0.25) : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: _isLocked ? Colors.orange : Colors.white30),
        ),
        child: Icon(
          _isLocked ? Icons.lock : Icons.lock_open,
          color: _isLocked ? Colors.orange : Colors.white70,
          size: 22,
        ),
      ),
    );
  }

  // ── SPEED MENU ─────────────────────────────
  Widget _buildSpeedMenu() {
    return Positioned(
      top: 60,
      right: 60,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speedOptions.map((speed) {
              final selected = _playbackSpeed == speed;
              return GestureDetector(
                onTap: () => _setSpeed(speed),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF9800).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${speed}x",
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFF9800)
                              : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check,
                          color: Color(0xFFFF9800),
                          size: 14,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── LOADING / ERROR ────────────────────────
  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF9800)),
            SizedBox(height: 16),
            Text(
              "Loading video...",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              "Failed to load video",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
              ),
              onPressed: () {
                setState(() => _hasError = false);
                _initPlayer();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  String? _localPath;
  bool _isReady = false;
  bool _isDownloading = false;
  bool _hasError = false;
  double _downloadProgress = 0;

  PDFViewController? _pdfController;
  int _totalPages = 0;
  int _currentPage = 0;

  bool _nightMode = false;
  bool _showPageJump = false;
  bool _showToolbar = true;

  Set<int> _bookmarks = {};
  final TextEditingController _jumpController = TextEditingController();
  final String _prefsKey = "pdf_last_page_";
  final String _bookmarkKey = "pdf_bookmarks_";

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _preparePdf();
  }

  // ── SAVE / LOAD STATE ──────────────────────
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt(_prefsKey + widget.title) ?? 0;
    final savedBookmarks =
        prefs.getStringList(_bookmarkKey + widget.title) ?? [];

    setState(() {
      _currentPage = savedPage;
      _bookmarks = savedBookmarks.map(int.parse).toSet();
    });
  }

  Future<void> _saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey + widget.title, page);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarkKey + widget.title,
      _bookmarks.map((e) => e.toString()).toList(),
    );
  }

  // ── DOWNLOAD PDF ───────────────────────────
  Future<void> _preparePdf() async {
    setState(() => _isDownloading = true);
    try {
      final dir = await getTemporaryDirectory();
      final safeName = widget.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final file = File("${dir.path}/$safeName.pdf");

      if (!await file.exists()) {
        await Dio().download(
          widget.pdfUrl,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _downloadProgress = received / total);
            }
          },
        );
      }

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isDownloading = false;
        });
      }
    }
  }

  // ── BOOKMARK TOGGLE ────────────────────────
  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
        _showSnack("Bookmark removed");
      } else {
        _bookmarks.add(_currentPage);
        _showSnack("Page ${_currentPage + 1} bookmarked");
      }
    });
    _saveBookmarks();
  }

  // ── PAGE JUMP ──────────────────────────────
  void _jumpToPage() {
    final page = int.tryParse(_jumpController.text);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfController?.setPage(page - 1);
      setState(() => _showPageJump = false);
      _jumpController.clear();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1F3C68),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildError();
    if (_isDownloading) return _buildDownloading();

    return Scaffold(
      backgroundColor: _nightMode
          ? const Color(0xFF121212)
          : const Color(0xFFF4F4F4),
      appBar: _showToolbar ? _buildAppBar() : null,
      body: Stack(
        children: [
          // ── PDF VIEW ────────────────────────
          if (_localPath != null)
            PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              nightMode: _nightMode,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              },
              onViewCreated: (controller) {
                _pdfController = controller;
              },
              onPageChanged: (page, _) {
                if (page != null) {
                  setState(() => _currentPage = page);
                  _saveLastPage(page);
                }
              },
              onError: (e) => setState(() => _hasError = true),
            ),

          if (!_isReady && _localPath != null)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0E5FD8)),
            ),

          // ── FLOATING PAGE INDICATOR ─────────
          if (_isReady)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalPages > 0
                            ? (_currentPage + 1) / _totalPages
                            : 0,
                        backgroundColor: Colors.black12,
                        color: const Color(0xFF0E5FD8),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Page pill
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showPageJump = !_showPageJump),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          "${_currentPage + 1} / $_totalPages",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── PAGE JUMP DIALOG ────────────────
          if (_showPageJump)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3C68),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Go to page",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _jumpController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: "1 – $_totalPages",
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _jumpToPage(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _showPageJump = false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4f8fff),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _jumpToPage,
                              child: const Text(
                                "Go",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── BOOKMARKS DRAWER ───────────────────
      drawer: _buildBookmarksDrawer(),
    );
  }

  // ── APP BAR ────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final isBookmarked = _bookmarks.contains(_currentPage);
    return AppBar(
      backgroundColor: const Color(0xFF1F3C68),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "Page ${_currentPage + 1} of $_totalPages",
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
      actions: [
        // Bookmark toggle
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.amber : Colors.white,
          ),
          tooltip: "Bookmark page",
          onPressed: _toggleBookmark,
        ),

        // Night mode
        IconButton(
          icon: Icon(
            _nightMode ? Icons.wb_sunny : Icons.dark_mode,
            color: Colors.white,
          ),
          tooltip: "Toggle night mode",
          onPressed: () => setState(() => _nightMode = !_nightMode),
        ),

        // Bookmarks list
        Builder(
          builder: (ctx) => IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.bookmarks_outlined, color: Colors.white),
                if (_bookmarks.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${_bookmarks.length}",
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: "All bookmarks",
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),

        // Page jump
        IconButton(
          icon: const Icon(Icons.find_in_page_outlined, color: Colors.white),
          tooltip: "Jump to page",
          onPressed: () => setState(() => _showPageJump = !_showPageJump),
        ),

        // Prev / Next
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: _currentPage > 0
              ? () => _pdfController?.setPage(_currentPage - 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: _currentPage < _totalPages - 1
              ? () => _pdfController?.setPage(_currentPage + 1)
              : null,
        ),
      ],
    );
  }

  // ── BOOKMARKS DRAWER ───────────────────────
  Widget _buildBookmarksDrawer() {
    final sorted = _bookmarks.toList()..sort();
    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Bookmarks",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No bookmarks yet",
                  style: TextStyle(color: Colors.white38),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final page = sorted[i];
                    return ListTile(
                      leading: const Icon(
                        Icons.bookmark,
                        color: Colors.amber,
                        size: 20,
                      ),
                      title: Text(
                        "Page ${page + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white38,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() => _bookmarks.remove(page));
                          _saveBookmarks();
                        },
                      ),
                      onTap: () {
                        _pdfController?.setPage(page);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── DOWNLOADING ────────────────────────────
  Widget _buildDownloading() {
    return Scaffold(
      backgroundColor: const Color(0xFF1F3C68),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 56),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFF4f8fff),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${(_downloadProgress * 100).toStringAsFixed(0)}%",
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── ERROR ──────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text("Failed to load PDF", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5FD8),
              ),
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isDownloading = false;
                  _downloadProgress = 0;
                });
                _preparePdf();
              },
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
