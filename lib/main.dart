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
      home: InfuMedzApp(),
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

    AdminPanelHome(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.play_circle),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Library',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Admin'),
        ],
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
  final List<String> marqueeTexts = [
    "“At InfusionMedz, we are dedicated to delivering a comprehensive medical learning experience that seamlessly bridges the gap between strong theoretical foundations and real-world clinical practice.“ ",
  ];
  final List<Map<String, String>> popularCourses = [
    {
      "title": "DM Cardiology – Complete Video Course",
      "views": "12.4K learners",
      "meta": "120 videos • 40 PDFs • 6 months access",
      "price": "₹3,499",
      "thumbnail": "assets/thumbnail1.avif",
    },
    {
      "title": "MBBS Anatomy – Video & Notes",
      "views": "8.1K learners",
      "meta": "80 videos • 25 PDFs • Lifetime access",
      "price": "₹9,499",
      "thumbnail": "assets/thumbnail2.jpg",
    },
    {
      "title": "MD Medicine – Clinical Q&A Series",
      "views": "37.9K learners",
      "meta": "150 videos • Case discussions",
      "price": "₹14,999",
      "thumbnail": "assets/thumbnail3.webp",
    },
  ];

  final List<Map<String, String>> popularCourses2 = [
    {
      "title": "Essentials of Cardiology – DM & DrNB Notes",
      "views": "11.2K readers",
      "meta": "410 Pages • PDF • Concept-focused",
      "price": "₹3,999",
      "thumbnail": "assets/thumbnail11.jpg",
    },

    {
      "title": "Radiology – Image Based Question & Answer Book",
      "views": "8.9K readers",
      "meta": "280 Pages • PDF • Image-centric",
      "price": "₹2,499",
      "thumbnail": "assets/thumbnail33.jpg",
    },
    {
      "title": "Paediatrics – Rapid Review Handbook",
      "views": "23.1K readers",
      "meta": "240 Pages • PDF • Quick revision",
      "price": "₹1,899",
      "thumbnail": "assets/thumbnail44.webp",
    },
  ];

  final List<String> images = [
    "assets/banner1.png",
    "assets/banner2.jpg",
    "assets/banner3.jpg",
  ];

  @override
  void initState() {
    super.initState();

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

  Widget _buildMarquee() {
    final text = marqueeTexts[0];

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
    if (!mounted) return;

    _currentIndex = (_currentIndex + 1) % images.length;

    _controller.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 2800), // smooth
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
                    height: 60,
                    width: 60,

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
              Container(
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
              itemCount: images.length,
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
                        Image.asset(images[index], fit: BoxFit.cover),

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
              images.length,
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
          const Text(
            "Popular Courses",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),

          ...List.generate(popularCourses.length, (i) {
            final course = popularCourses[i];

            return YoutubeStyleCourseCard(
              title: course["title"]!,
              views: course["views"]!,
              meta: course["meta"]!,
              price: course["price"]!,
              thumbnail: course["thumbnail"]!,
              onTap: () {},
            );
          }),
          const SizedBox(height: 12),

          /// Courses
          const Text(
            "Popular Boooks",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),

          ...List.generate(popularCourses2.length, (i) {
            final course = popularCourses2[i];

            return YoutubeStyleCourseCard2(
              title: course["title"]!,
              views: course["views"]!,
              meta: course["meta"]!,
              price: course["price"]!,
              thumbnail: course["thumbnail"]!,
            );
          }),
        ],
      ),
    );
  }
}

class YoutubeStyleCourseCard extends StatelessWidget {
  final String title;
  final String views;
  final String meta;
  final String price;
  final String thumbnail;
  final VoidCallback onTap;

  const YoutubeStyleCourseCard({
    super.key,
    required this.title,
    required this.views,
    required this.meta,
    required this.price,
    required this.thumbnail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: open course details
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Thumbnail (Left)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                      url:
                          "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/videos/54cfac91-079b-481d-8d8c-9916924954f0_1000205769.mp4",
                      title: title,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thumbnail Image
                    Image.asset(
                      thumbnail,
                      width: 140,
                      height: 80,
                      fit: BoxFit.cover,
                    ),

                    // Dark overlay (subtle)
                    Container(
                      width: 140,
                      height: 80,
                      color: Colors.black.withOpacity(0.15),
                    ),

                    // ▶️ Play Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 📄 Details (Right)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + MENU
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F3C68),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // META

                  // VIEWS / LEARNERS
                  Text(
                    views,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),

                  const SizedBox(height: 3),

                  // PRICE + BUY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E5FD8), // medical blue
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5FD8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Buy",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E5FD8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YoutubeStyleCourseCard2 extends StatelessWidget {
  final String title;
  final String views;
  final String meta;
  final String price;
  final String thumbnail;

  const YoutubeStyleCourseCard2({
    super.key,
    required this.title,
    required this.views,
    required this.meta,
    required this.price,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: open course details
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Thumbnail (Left)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfScreen(
                      pdfUrl:
                          "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/pdfs/54cfac91-079b-481d-8d8c-9916924954f0_CASTOR.pdf",
                      title: title,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thumbnail Image
                    Image.asset(
                      thumbnail,
                      width: 140,
                      height: 80,
                      fit: BoxFit.cover,
                    ),

                    // Dark overlay (subtle)
                    Container(
                      width: 140,
                      height: 80,
                      color: Colors.black.withOpacity(0.15),
                    ),

                    // ▶️ Play Button
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
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 📄 Details (Right)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + MENU
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F3C68),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // META

                  // VIEWS / LEARNERS
                  Text(
                    views,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),

                  const SizedBox(height: 3),

                  // PRICE + BUY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E5FD8), // medical blue
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5FD8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Buy",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E5FD8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          "My Library",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F3C68),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 📊 OVERVIEW
          _LibraryStats(),

          const SizedBox(height: 20),

          /// 🎓 COURSES
          const Text(
            "My Courses",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          ...libraryCourses.map((course) => _LibraryCourseCard(course: course)),

          const SizedBox(height: 28),

          /// 📄 PDFs
          const Text(
            "My Notes & PDFs",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          ...libraryPdfs.map((pdf) => _LibraryPdfCard(pdf: pdf)),
        ],
      ),
    );
  }
}

class _LibraryStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _StatItem(title: "Courses", value: "2"),
          _StatItem(title: "PDFs", value: "1"),
          _StatItem(title: "Completed", value: "1"),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E5FD8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

class _LibraryCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const _LibraryCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = course["progress"];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// THUMBNAIL
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              course["image"],
              width: 90,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course["title"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                /// PROGRESS BAR
                LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF0E5FD8),
                ),

                const SizedBox(height: 6),

                Text(
                  "$progress% completed ",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// RESUME
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    url:
                        "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/videos/54cfac91-079b-481d-8d8c-9916924954f0_1000205769.mp4",
                    title: "",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5FD8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Resume",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryPdfCard extends StatelessWidget {
  final Map<String, dynamic> pdf;

  const _LibraryPdfCard({required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdf["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pdf["meta"],
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfScreen(
                    pdfUrl:
                        "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/pdfs/54cfac91-079b-481d-8d8c-9916924954f0_CASTOR.pdf",
                    title: pdf["title"],
                  ),
                ),
              );
            },
            child: const Text(
              "Open",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

final libraryCourses = [
  {
    "title": "MBBS Anatomy – Clinical Approach",
    "image": "assets/thumbnail2.jpg",
    "progress": 30,
    "completed": 27,
    "total": 90,
  },
  {
    "title": "MD Medicine – Clinical Q&A Series",
    "image": "assets/thumbnail3.webp",
    "progress": 10,
    "completed": 15,
    "total": 150,
  },
];

final libraryPdfs = [
  {
    "title": "General Medicine – Rapid Revision Notes",
    "meta": "780 Pages • PDF",
  },
];

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Cart"));
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
