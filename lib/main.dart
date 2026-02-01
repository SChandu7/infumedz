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

    FavouritesPage(),
    ProfilePage(),
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
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
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

  const YoutubeStyleCourseCard({
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

class MedicalStoreScreen extends StatefulWidget {
  final String initialCategory; // 👈 NEW

  const MedicalStoreScreen({
    super.key,
    this.initialCategory = "MBBS", // 👈 default
  });

  @override
  State<MedicalStoreScreen> createState() => _MedicalStoreScreenState();
}

class _MedicalStoreScreenState extends State<MedicalStoreScreen> {
  String selectedType = "Courses";
  late String selectedCategory;
  final List<Map<String, dynamic>> wishlistItems = [];

  final categories = ["MBBS", "MD/MS", "DM/DrNB"];

  final courses = [
    // 🔹 DM / Super-specialty
    {
      "title": "DM Cardiology – Complete Course",
      "meta": "120 Videos • 40 PDFs • 6 Months",
      "learners": "18.2K learners",
      "price": "₹14,999",
      "image": "assets/thumbnail1.avif",
      "tag": "Bestseller",
    },
    {
      "title": "DM Neurology – Clinical Practice Mastery",
      "meta": "110 Videos • EEG • Case PDFs",
      "learners": "9.4K learners",
      "price": "₹16,499",
      "image": "assets/thumbnail2.jpg",
      "tag": "Advanced",
    },
    {
      "title": "DM Endocrinology – Case Based Learning",
      "meta": "85 Videos • Real-life cases",
      "learners": "7.1K learners",
      "price": "₹13,999",
      "image": "assets/thumbnail3.webp",
    },

    // 🔹 MD / MS
    {
      "title": "MD Medicine – Clinical Q&A Series",
      "meta": "150 Videos • Case discussions",
      "learners": "37.9K learners",
      "price": "₹14,999",
      "image": "assets/thumbnail1.avif",
      "tag": "Top Rated",
    },
    {
      "title": "MD Pediatrics – Growth & Development",
      "meta": "95 Videos • Neonatal cases",
      "learners": "21.3K learners",
      "price": "₹11,499",
      "image": "assets/thumbnail2.jpg",
    },
    {
      "title": "MS General Surgery – OR to Ward",
      "meta": "100 Videos • Surgical techniques",
      "learners": "19.8K learners",
      "price": "₹12,999",
      "image": "assets/thumbnail3.webp",
    },
    {
      "title": "MD Radiology – Imaging Simplified",
      "meta": "CT • MRI • X-Ray • 200+ Cases",
      "learners": "26.7K learners",
      "price": "₹15,999",
      "image": "assets/thumbnail1.avif",
      "tag": "High Demand",
    },

    // 🔹 MBBS
    {
      "title": "MBBS Anatomy – Clinical Approach",
      "meta": "90 Videos • 20 PDFs",
      "learners": "12.4K learners",
      "price": "₹6,499",
      "image": "assets/thumbnail2.jpg",
    },
    {
      "title": "MBBS Physiology – Concept to Clinic",
      "meta": "70 Videos • Diagrams • PDFs",
      "learners": "14.6K learners",
      "price": "₹5,999",
      "image": "assets/thumbnail3.webp",
    },
    {
      "title": "MBBS Pathology – Case Based Learning",
      "meta": "80 Videos • Histology Slides",
      "learners": "16.2K learners",
      "price": "₹6,999",
      "image": "assets/thumbnail1.avif",
    },

    // 🔹 Entrance / Competitive
    {
      "title": "NEET PG – Integrated Preparation",
      "meta": "300+ Videos • MCQs • PDFs",
      "learners": "48.5K learners",
      "price": "₹19,999",
      "image": "assets/thumbnail2.jpg",
      "tag": "Most Popular",
    },
    {
      "title": "INICET – High Yield Topics",
      "meta": "120 Videos • PYQs Explained",
      "learners": "28.9K learners",
      "price": "₹12,499",
      "image": "assets/thumbnail3.webp",
    },
  ];
  final books = [
    // 🔹 Core Medicine
    {
      "title": "General Medicine – Rapid Revision Notes",
      "meta": "PDF Book • 780 Pages",
      "learners": "22K readers",
      "price": "₹1,499",
      "image": "assets/thumbnail11.jpg",
      "tag": "Bestseller",
    },
    {
      "title": "Pathology – Case Based Learning",
      "meta": "Illustrated PDF • Histopathology",
      "learners": "9.8K readers",
      "price": "₹999",
      "image": "assets/thumbnail22.jpg",
    },
    {
      "title": "Paediatrics – Rapid Review Handbook",
      "meta": "240 Pages • PDF • Quick Revision",
      "learners": "23.1K readers",
      "price": "₹1,899",
      "image": "assets/thumbnail44.webp",
    },

    // 🔹 MBBS Subjects
    {
      "title": "Anatomy – Clinical Anatomy Atlas",
      "meta": "High-Yield Diagrams • PDF",
      "learners": "18.4K readers",
      "price": "₹1,299",
      "image": "assets/thumbnail33.jpg",
    },
    {
      "title": "Physiology – Concept Review Notes",
      "meta": "Flowcharts • Tables • PDF",
      "learners": "16.8K readers",
      "price": "₹1,199",
      "image": "assets/thumbnail11.jpg",
    },
    {
      "title": "Pharmacology – Drug Classification Handbook",
      "meta": "Charts • Mechanisms • PDF",
      "learners": "21.2K readers",
      "price": "₹1,099",
      "image": "assets/thumbnail22.jpg",
      "tag": "Exam Favorite",
    },
    {
      "title": "Microbiology – Rapid Revision Notes",
      "meta": "Flowcharts • Mnemonics • PDF",
      "learners": "14.5K readers",
      "price": "₹999",
      "image": "assets/thumbnail33.jpg",
    },

    // 🔹 Surgery / Ortho / OBG
    {
      "title": "General Surgery – Case Based Review",
      "meta": "Clinical Scenarios • PDF",
      "learners": "19.3K readers",
      "price": "₹1,599",
      "image": "assets/thumbnail44.webp",
    },
    {
      "title": "Orthopaedics – Exam Oriented Notes",
      "meta": "X-Ray Based • PDF",
      "learners": "11.9K readers",
      "price": "₹1,399",
      "image": "assets/thumbnail11.jpg",
    },
    {
      "title": "Obstetrics & Gynecology – High Yield Review",
      "meta": "Flowcharts • Algorithms • PDF",
      "learners": "17.6K readers",
      "price": "₹1,699",
      "image": "assets/thumbnail22.jpg",
    },

    // 🔹 Competitive Exams
    {
      "title": "NEET PG – High Yield Notes",
      "meta": "MCQ Focused • PDF",
      "learners": "42.8K readers",
      "price": "₹2,499",
      "image": "assets/thumbnail33.jpg",
      "tag": "Most Popular",
    },
    {
      "title": "INICET – Previous Year Questions Explained",
      "meta": "Topic-wise PYQs • PDF",
      "learners": "29.7K readers",
      "price": "₹1,999",
      "image": "assets/thumbnail44.webp",
    },
  ];

  double get cartTotal {
    double total = 0;
    for (var item in CartStore.items) {
      final price =
          double.tryParse(
            item["price"].replaceAll("₹", "").replaceAll(",", ""),
          ) ??
          0;
      total += price;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory; // 👈 IMPORTANT
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text(
                "Select Level",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: ["MBBS", "MD/MS", "DM/DrNB"].map((level) {
                  final active = selectedCategory == level;
                  return ChoiceChip(
                    label: Text(level),
                    selected: active,
                    selectedColor: const Color(0xFF0E5FD8),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => selectedCategory = level);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CartBottomSheet(
        initialItems: CartStore.items,
        onCartUpdated: (updated) {
          setState(() {
            CartStore.clear();
            for (final item in updated) {
              CartStore.add(item);
            }
          });
        },
      ),
    );
  }

  void _openWishlist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => WishlistBottomSheet(
        initialItems: wishlistItems,
        onAddToCart: (item) {
          CartStore.add(item);
        },
        onWishlistUpdated: (updated) {
          setState(() {
            wishlistItems
              ..clear()
              ..addAll(updated);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = selectedType == "Courses" ? courses : books;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Explore Learning",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F3C68),
          ),
        ),
        actions: [
          /// ❤️ Wishlist
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF0E5FD8)),
            onPressed: _openWishlist,
          ),

          /// 🛒 Cart
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF0E5FD8),
                ),
                onPressed: () => _openCart(context),
              ),

              if (CartStore.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      CartStore.items.length.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0E5FD8)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search courses, books, subjects…",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF0E5FD8)),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),
          ),

          /// COURSE / BOOK TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ["Courses", "Books"].map((type) {
                final active = selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0E5FD8) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          /// CATEGORY FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: Color(0xFF0E5FD8),
                ),
                const SizedBox(width: 6),
                Text(
                  "Showing $selectedType for ",
                  style: const TextStyle(fontSize: 17, color: Colors.black54),
                ),
                Text(
                  selectedCategory,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final item = data[i];
                return _CourseListCard(
                  data: item,
                  isWishlisted: wishlistItems.contains(item),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(data: item),
                      ),
                    );
                  },

                  onWishlist: () {
                    setState(() {
                      if (wishlistItems.contains(item)) {
                        wishlistItems.remove(item);
                      } else {
                        wishlistItems.add(item);
                      }
                    });
                  },

                  onAddToCart: () {
                    setState(() {
                      if (!CartStore.items.contains(item)) {
                        CartStore.add(item);
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to cart")),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddToCart;
  final bool isWishlisted;

  const _CourseListCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onWishlist,
    this.onAddToCart,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 THUMBNAIL (REDUCED HEIGHT)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: Image.asset(
                      data["image"],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  /// ▶ Play icon
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                  /// ❤️ Wishlist
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? Colors.red : Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  /// 🏷 Tag
                  if (data["tag"] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data["tag"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              /// 🔹 DETAILS
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Text(
                      data["title"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F3C68),
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// Cost + ⭐ RATING + 👥 LEARNERS (SINGLE ROW)
                    Row(
                      children: [
                        /// ⭐ LEFT — Rating
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "4.8",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// 👥 CENTER — Learners
                        Expanded(
                          child: Text(
                            data["learners"] ?? "",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        /// 💰 RIGHT — Price
                        Expanded(
                          child: Text(
                            data["price"],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E5FD8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// PRICE + CART
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartStore {
  static final List<Map<String, dynamic>> _items = [];

  static List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  /// returns true if added, false if already exists
  static bool add(Map<String, dynamic> item) {
    final exists = _items.any((e) => e["title"] == item["title"]);

    if (exists) return false;

    _items.add(item);
    return true;
  }

  static void remove(Map<String, dynamic> item) {
    _items.removeWhere((e) => e["title"] == item["title"]);
  }

  static void clear() {
    _items.clear();
  }

  static bool contains(Map<String, dynamic> item) {
    return _items.any((e) => e["title"] == item["title"]);
  }

  static double total() {
    double sum = 0;

    for (final item in _items) {
      final raw = item["price"];
      if (raw == null) continue;

      final cleaned = raw.toString().replaceAll("₹", "").replaceAll(",", "");

      sum += double.tryParse(cleaned) ?? 0;
    }

    return sum;
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const CourseDetailScreen({super.key, required this.data});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      /// 🔹 BOTTOM ACTION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ❤️ Wishlist
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0E5FD8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Color(0xFF0E5FD8),
              ),
            ),

            const SizedBox(width: 12),

            /// 🛒 Add to Cart
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  CartStore.add(widget.data);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5FD8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Add to Cart • ${widget.data["price"]}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          /// 🔹 HERO APP BAR
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white, // 👈 makes it white
              ),
              onPressed: () {
                setState(() => isPlaying = false);
                Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isPlaying)
                    Image.asset(widget.data["image"], fit: BoxFit.cover)
                  else
                    InlineVideoPlayer(
                      url:
                          "https://djangotestcase.s3.ap-south-1.amazonaws.com/medical/videos/54cfac91-079b-481d-8d8c-9916924954f0_1000205769.mp4",
                      title: '',
                    ),

                  if (!isPlaying)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),

                  if (!isPlaying)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          final title = widget.data["title"]
                              .toString()
                              .toLowerCase();

                          final isPdfType =
                              title.contains("pdf") ||
                              title.contains("Based") ||
                              title.contains("notes") ||
                              title.contains("Rapid") ||
                              title.contains("rapid revise") ||
                              title.contains("case based") ||
                              title.contains("case based") ||
                              title.contains("case based") ||
                              title.contains("handbook");

                          if (isPdfType) {
                            /// 📄 OPEN PDF PAGE (NO setState)
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
                          } else {
                            /// 🎥 PLAY VIDEO INLINE
                            setState(() {
                              isPlaying = true;
                            });
                          }
                        },
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// 🔹 CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  Text(
                    widget.data["title"],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F3C68),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// RATING + LEARNERS
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        "4.8",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "(12,400 ratings)",
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.data["learners"] ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// META INFO
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: const [
                      _MetaItem(icon: Icons.language, text: "English"),
                      _MetaItem(
                        icon: Icons.update,
                        text: "Last updated Jan 2026",
                      ),
                      _MetaItem(icon: Icons.school, text: "Medical Education"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CREATED BY
                  const Text(
                    "Created by",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "InfuMedz Academic Faculty",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0E5FD8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// DESCRIPTION
                  const Text(
                    "About this course",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This comprehensive medical course is designed to bridge the gap between theoretical foundations and real-world clinical practice. The curriculum is carefully structured by experienced medical professionals to help students, residents, and specialists gain confidence in diagnosis, decision-making, and patient care.\n\nYou will learn through high-quality video lectures, clinical case discussions, and concise medical notes curated specifically for exam preparation and real-life application.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// WHAT YOU’LL LEARN
                  const Text(
                    "What you'll learn",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  const _BulletPoint(
                    text:
                        "Develop strong conceptual clarity with clinical relevance",
                  ),
                  const _BulletPoint(
                    text: "Understand diagnostic and treatment strategies",
                  ),
                  const _BulletPoint(
                    text:
                        "Prepare effectively for university & competitive exams",
                  ),
                  const _BulletPoint(
                    text: "Access curated PDFs, videos, and revision materials",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const InlineVideoPlayer({super.key, required this.url, required this.title});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _openFullscreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(url: widget.url, title: widget.title),
      ),
    );

    // resume inline playback after fullscreen exit
    if (mounted) {
      setState(() {});
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          /// 🧩 CONTROLS
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// ▶️ / ⏸
                    IconButton(
                      iconSize: 42,
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),

                    const SizedBox(width: 24),

                    /// ⛶ FULLSCREEN
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _openFullscreen,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF0E5FD8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class CartBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final ValueChanged<List<Map<String, dynamic>>>? onCartUpdated;

  const CartBottomSheet({
    super.key,
    required this.initialItems,
    this.onCartUpdated,
  });

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  late List<Map<String, dynamic>> _cartItems;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.initialItems);
  }

  double get total {
    return _cartItems.fold(0.0, (sum, item) {
      final raw = item["price"];
      if (raw == null) return sum;

      final cleaned = raw.toString().replaceAll("₹", "").replaceAll(",", "");

      return sum + (double.tryParse(cleaned) ?? 0);
    });
  }

  void _removeItem(int index) {
    if (_processing) return;
    _processing = true;

    final removedItem = _cartItems[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _CartItemTile(item: removedItem),
      ),
      duration: const Duration(milliseconds: 280),
    );

    setState(() {
      _cartItems.removeAt(index);
    });

    widget.onCartUpdated?.call(List.from(_cartItems));

    Future.delayed(const Duration(milliseconds: 300), () {
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Your Cart",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// 🔹 CART LIST
            Expanded(
              child: _cartItems.isEmpty
                  ? const _EmptyCartView()
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: _cartItems.length,
                      padding: const EdgeInsets.all(14),
                      itemBuilder: (context, index, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: _CartItemTile(
                            item: _cartItems[index],
                            onDelete: () => _removeItem(index),
                          ),
                        );
                      },
                    ),
            ),

            /// 🔹 BILLING
            _BillingSection(total: total),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDelete;

  const _CartItemTile({required this.item, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item["image"],
              width: 60,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _BillingSection extends StatelessWidget {
  final double total;

  const _BillingSection({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  "₹${total.toStringAsFixed(0)}",
                  key: ValueKey(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: () {
              // backend checkout later
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5FD8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Proceed to Checkout",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class WishlistBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final Function(Map<String, dynamic>) onAddToCart;
  final ValueChanged<List<Map<String, dynamic>>>? onWishlistUpdated;

  const WishlistBottomSheet({
    super.key,
    required this.initialItems,
    required this.onAddToCart,
    this.onWishlistUpdated,
  });

  @override
  State<WishlistBottomSheet> createState() => _WishlistBottomSheetState();
}

class _WishlistBottomSheetState extends State<WishlistBottomSheet> {
  late List<Map<String, dynamic>> _wishlistItems;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  bool _processing = false; // prevents double taps

  @override
  void initState() {
    super.initState();
    _wishlistItems = List.from(widget.initialItems);
  }

  void _removeFromWishlist(int index) {
    final removedItem = _wishlistItems[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _WishlistItemTile(item: removedItem),
      ),
      duration: const Duration(milliseconds: 280),
    );

    setState(() {
      _wishlistItems.removeAt(index);
    });

    widget.onWishlistUpdated?.call(List.from(_wishlistItems));
  }

  void _moveToCart(int index) async {
    if (_processing) return;
    _processing = true;

    final item = _wishlistItems[index];

    widget.onAddToCart(item);
    _removeFromWishlist(index);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Moved to cart"),
        backgroundColor: Color(0xFF0E5FD8),
        duration: Duration(milliseconds: 900),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Wishlist",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// 🔹 LIST
            Expanded(
              child: _wishlistItems.isEmpty
                  ? const _EmptyWishlistView()
                  : AnimatedList(
                      key: _listKey,
                      padding: const EdgeInsets.all(14),
                      initialItemCount: _wishlistItems.length,
                      itemBuilder: (context, index, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: _WishlistItemTile(
                            item: _wishlistItems[index],
                            onAddToCart: () => _moveToCart(index),
                            onRemove: () => _removeFromWishlist(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;

  const _WishlistItemTile({
    required this.item,
    this.onAddToCart,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              item["image"],
              width: 64,
              height: 56,
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
                  item["title"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ],
            ),
          ),

          /// ACTIONS
          Column(
            children: [
              InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5FD8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 18,
                    color: Color(0xFF0E5FD8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onRemove,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWishlistView extends StatelessWidget {
  const _EmptyWishlistView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            "Your wishlist is empty",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
