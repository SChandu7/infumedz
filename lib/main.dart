import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:infumedz/views.dart';
import 'package:video_player/video_player.dart';
import 'admin.dart';
import 'cart.dart';
import 'explore.dart';
import 'thesis.dart';
import 'library.dart';

class ApiConfig {
  static const base = "http://13.203.219.206:8000";

  static const categories = "$base/api/infumedz/categories/";
  static const courses = "$base/api/infumedz/courses/";
  static const books = "$base/api/infumedz/books/";

  static const createCourse = "$base/api/infumedz/course/create/";
  static const addCourseVideo = "$base/api/infumedz/course/video/add/";
  static const createBook = "$base/api/infumedz/book/create/";
  static const addBookPdf = "$base/api/infumedz/book/pdf/add/";
  static const presignedVideoUpload = "$base/upload/video/presigned/";

  static const uploadThumbnail =
      "http://13.203.219.206:8000/api/infumedz/upload/course-thumbnail/";
}

void main() {
  runApp(const InfuMedzApp());
}

class InfuMedzApp extends StatelessWidget {
  const InfuMedzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InfusionMedz',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final screens = const [
    HomePage(),
    MedicalStoreScreen(),
    LibraryPage(),
    AdminHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: screens[index],

      // ✅ FAB ONLY FOR ADMIN TAB
      floatingActionButton: index == 3 ? AdminExpandableFab() : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
      ),
    );
  }
}

class AdminExpandableFab extends StatefulWidget {
  @override
  State<AdminExpandableFab> createState() => _AdminExpandableFabState();
}

class _AdminExpandableFabState extends State<AdminExpandableFab> {
  bool fabOpen = false;
  Widget _staggeredFabOption(int index, IconData icon, String label) {
    const int baseDelayMs = 100; // 🔥 FAST stagger
    final delay = Duration(milliseconds: baseDelayMs * index);

    return AnimatedOpacity(
      opacity: fabOpen ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: fabOpen ? Offset.zero : const Offset(0, 0.4),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: FutureBuilder(
          future: fabOpen ? Future.delayed(delay) : Future.value(),
          builder: (context, snapshot) {
            if (fabOpen && snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            return _fabOption(icon, label);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (fabOpen)
          GestureDetector(
            onTap: () => setState(() => fabOpen = false),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),

        Positioned(
          bottom: 80,
          right: 16,
          child: Column(
            children: [
              _staggeredFabOption(3, Icons.add, "Add Courses"),
              _staggeredFabOption(2, Icons.picture_as_pdf, "Add Books"),
              _staggeredFabOption(1, Icons.delete, "Delete Content"),
              _staggeredFabOption(
                0,
                Icons.published_with_changes,
                "Update Banner",
              ),
            ],
          ),
        ),

        FloatingActionButton(
          backgroundColor: const Color(0xFF0E5FD8),
          onPressed: () => setState(() => fabOpen = !fabOpen),
          child: AnimatedRotation(
            turns: fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _fabOption(IconData icon, String label) {
    const double buttonWidth = 150; // 🔥 FIXED WIDTH
    const double buttonHeight = 48; // 🔥 FIXED HEIGHT

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: Material(
          color: Colors.white,
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => fabOpen = false);

              if (label == "Add Courses") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCourseFlow()),
                );
              } else if (label == "Add Books") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookFlow()),
                );
              } else if (label == "Delete Content") {
                showDialog(
                  context: context,
                  builder: (_) => const AdminDeleteDialog(),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBannerScreen()),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF0E5FD8)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0E5FD8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: "Home",
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.manage_search,
            label: "Explore",
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.my_library_books_sharp,
            label: "Library",
            index: 2,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.admin_panel_settings_rounded,
            label: "Admin",
            index: 3,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 3, // ⬅ reduced
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0E5FD8).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ICON
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0, // ⬅ reduced scale
              duration: const Duration(milliseconds: 100),
              child: Icon(
                icon,
                size: 24, // ⬅ smaller icon
                color: isActive ? const Color(0xFF0E5FD8) : Colors.grey,
              ),
            ),

            // LABEL (no height jump)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11, // ⬅ smaller text
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E5FD8),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static final categories = ["MBBS", "MD/MS", "DM/DrNB"];
  static final coursess = ["Medicine", "Post-Graduate", "Super-Speciality"];
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  late AnimationController _marqueeController;
  late Animation<double> _marqueeAnimation;
  String aboutText = "";
  List<String> bannerImages = [];
  bool bannerLoading = true;

  bool loadingHome = true;

  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> allBooks = [];

  List<Map<String, dynamic>> popularCourses = [];
  List<Map<String, dynamic>> popularBooks = [];

  final List<Map<String, String>> notifications = [
    {
      "title": "MD Medicine – Clinical Q&A Series",
      "time": "Yesterday",
      "msg": "Course updated with 10 new videos.",
    },
    {
      "title": "Essentials of Cardiology – DM & DrNB Notes",
      "time": "2 hrs ago",
      "msg": "New Books list available. Check  now.",
    },

    {
      "title": "MBBS Anatomy – Video & Notes",
      "time": "2 days ago",
      "msg": "Newly Launched Course! Enroll today.",
    },
    {
      "title": "Radiology – Image Based Question & Answer Book",
      "time": "3 days ago",
      "msg": "Special discount on selected books.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initHomeData();

    _marqueeController = AnimationController(
      duration: const Duration(seconds: 22), // slower & smoother
      vsync: this,
    )..repeat(); // 🔁 MUST repeat

    _marqueeAnimation = CurvedAnimation(
      parent: _marqueeController,
      curve: Curves.linear,
    );

    Future.delayed(const Duration(seconds: 5), _autoScroll);
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    _controller.dispose();

    super.dispose();
  }

  Future<void> _initHomeData() async {
    try {
      final bannerRes = await http.get(
        Uri.parse("https://api.chandus7.in/api/infumedz/app-banner/"),
      );

      final coursesRes = await http.get(
        Uri.parse("https://api.chandus7.in/api/infumedz/courses/"),
      );

      final booksRes = await http.get(
        Uri.parse("https://api.chandus7.in/api/infumedz/books/"),
      );

      final banner = jsonDecode(bannerRes.body);
      final courses = List<Map<String, dynamic>>.from(
        jsonDecode(coursesRes.body),
      );

      final books = List<Map<String, dynamic>>.from(jsonDecode(booksRes.body));

      final List<String> popularCourseIds = List<String>.from(
        banner["popular_courses"] ?? [],
      );

      final List<String> popularBookIds = List<String>.from(
        banner["popular_books"] ?? [],
      );

      /// 🔹 FILTER COURSES BASED ON IDS
      final filteredCourses = courses
          .where((c) => popularCourseIds.contains(c["id"]))
          .toList();

      /// 🔹 FILTER BOOKS BASED ON IDS
      final filteredBooks = books
          .where((b) => popularBookIds.contains(b["id"]))
          .toList();

      setState(() {
        aboutText = banner["about_text"] ?? "";
        bannerImages = List<String>.from(banner["carousel_urls"] ?? []);

        allCourses = courses;
        allBooks = books;

        popularCourses = filteredCourses;
        popularBooks = filteredBooks;
        print(popularCourses);
        print("-------------------------------------------------------------0");

        loadingHome = false;
      });
    } catch (e) {
      loadingHome = false;
      debugPrint("Home load error: $e");
    }
  }

  void _showNotificationPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.35), // Background blur
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: MediaQuery.of(context).size.width * 0.95,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------- HEADER -------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "🔔 Notifications",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          notifications.clear();
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text(
                          "Clear All",
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  //    const SizedBox(height: 8),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              "No notifications yet",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final item = notifications[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0057C1,
                                        ).withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active,
                                        color: Color(0xFF0057C1),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["title"]!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item["msg"]!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.25,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item["time"]!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      // Slide down animation
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  Future<void> fetchBannerData() async {
    try {
      final res = await http.get(
        Uri.parse("https://api.chandus7.in/api/infumedz/app-banner/"),
      );

      final data = jsonDecode(res.body);

      setState(() {
        aboutText = data["about_text"]?.toString() ?? "";

        final rawUrls = data["carousel_urls"];
        if (rawUrls is List) {
          bannerImages = rawUrls.whereType<String>().toList();
        } else {
          bannerImages = [];
        }

        bannerLoading = false;
      });
    } catch (e) {
      bannerLoading = false;
      debugPrint("Banner fetch failed: $e");
    }
  }

  Widget _buildMarquee() {
    final text = aboutText.isNotEmpty
        ? aboutText
        : "Welcome to InfuMedz Medical Learning Platform";

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDF4FF), Color(0xFFE0F7FF)],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),

          // ABOUT TAG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF015AA5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "About",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // MARQUEE TEXT
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;

                  // ✅ Measure text width correctly
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    textDirection: TextDirection.ltr,
                  )..layout();

                  final textWidth = textPainter.width;

                  return AnimatedBuilder(
                    animation: _marqueeAnimation,
                    builder: (context, child) {
                      final dx =
                          screenWidth -
                          _marqueeAnimation.value * (screenWidth + textWidth);

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Text(
                      text,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF204B78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _autoScroll() {
    if (!mounted || bannerImages.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % bannerImages.length;

    _controller.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 2800),
      curve: Curves.easeInOutCubic,
    );

    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: LOGO + BRAND TEXT
              Row(
                children: [
                  // 🔷 LOGO CONTAINER
                  Container(
                    height: 50,
                    width: 50,

                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Image.asset(
                        "assets/logo.png", // 👈 your logo
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 🧠 BRAND TEXT
                ],
              ),

              Center(
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "InfuMedz",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Color(0xFF1F3C68),
                      ),
                    ),
                    // SizedBox(height: 2),
                    // Text(
                    //   "Medical Learning Platform",
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.black54,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                  ],
                ),
              ),

              // RIGHT: NOTIFICATION / PROFILE
              InkWell(
                onTap: _showNotificationPanel,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E6ED)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF0E5FD8), // medical blue
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search courses,books…",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5FD8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.tune,
                      size: 18,
                      color: Color(0xFF0E5FD8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildMarquee(),
          const SizedBox(height: 8),

          /// Hero Banner
          // ------------------ CAROUSEL ------------------
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: bannerImages.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
              },
              itemBuilder: (context, index) {
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  padding: EdgeInsets.symmetric(
                    horizontal: index == _currentIndex ? 4 : 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 🖼 IMAGE
                        bannerImages.isEmpty
                            ? const SizedBox()
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  bannerImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey.shade300),
                                ),
                              ),

                        // 🌫 DARK GRADIENT OVERLAY
                        // Container(
                        //   decoration: const BoxDecoration(
                        //     gradient: LinearGradient(
                        //       begin: Alignment.bottomCenter,
                        //       end: Alignment.topCenter,
                        //       colors: [Colors.black54, Colors.transparent],
                        //     ),
                        //   ),
                        // ),

                        // 🧠 TEXT
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 5),

          // 🔘 INDICATORS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              bannerImages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == i
                      ? const Color(0xFF4F46E5) // brand indigo
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// Level Filter

          /// Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: Title + subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                ],
              ),

              // RIGHT: View all
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MedicalStoreScreen()),
                  );
                },
                child: const Text(
                  "View all",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0E5FD8), // medical blue
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔹 FULL-WIDTH CATEGORY CARDS (HIGHLIGHTED)
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ThesisAssistanceScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEAF3FF), // soft medical blue
                        Color(0xFFFFFFFF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// ICON
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5FD8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 22,
                          color: Color(0xFF0E5FD8),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// TEXT (FIXED NAME)
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thesis Assistance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F3C68),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Explore Publication",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1F3C68),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ARROW
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.99,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, i) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (i == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MedicalStoreScreen(initialCategory: "MD/MS"),
                      ),
                    );
                  } else if (i == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalStoreScreen(
                          initialCategory: "DM/DrNB",
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MedicalStoreScreen(initialCategory: "MBBS"),
                      ),
                    );
                  }
                  // TODO: navigate / filter by category
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEAF3FF), // soft medical blue
                        Color(0xFFFFFFFF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFDDE8F5)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 ICON
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5FD8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 22,
                          color: Color(0xFF0E5FD8),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 🔹 TITLE
                      Text(
                        categories[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F3C68),
                        ),
                      ),

                      const SizedBox(height: 1),

                      // 🔹 SUB TEXT (optional – future ready)
                      Text(
                        coursess[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7C93),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          /// Courses
          /// ---------------- POPULAR COURSES ----------------
          const Text(
            "Popular Courses",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          ...popularCourses.map((course) {
            final thumbnail =
                (course["thumbnail_url"] != null &&
                    course["thumbnail_url"].toString().isNotEmpty)
                ? course["thumbnail_url"]
                : "https://via.placeholder.com/300x180.png?text=No+Image";

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(
                      data: course, // ✅ FULL COURSE MAP
                      option: "course",
                      isLocked: true, // 👈 identify type
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼 Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            thumbnail,
                            width: 140,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                          Container(
                            width: 140,
                            height: 80,
                            color: Colors.black.withOpacity(0.15),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 📄 Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course["title"] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F3C68),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${course["videos"]?.length ?? 0} videos • Full access",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${course["price"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E5FD8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          /// ---------------- POPULAR BOOKS ----------------
          const SizedBox(height: 14),
          const Text(
            "Popular Books",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          ...popularBooks.map((book) {
            final thumbnail =
                (book["thumbnail_url"] != null &&
                    book["thumbnail_url"].toString().isNotEmpty)
                ? book["thumbnail_url"]
                : "https://via.placeholder.com/300x180.png?text=No+Image";

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(
                      data: book, // ✅ FULL BOOK MAP
                      option: "book",
                      isLocked: true,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼 Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            thumbnail,
                            width: 140,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                          Container(
                            width: 140,
                            height: 80,
                            color: Colors.black.withOpacity(0.15),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 📄 Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book["title"] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F3C68),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${book["pdfs"]?.length ?? 0} PDFs • Digital Book",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${book["price"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E5FD8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text("Profile Coming Soon...."));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Profile"));
}
