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
                              builder: (_) =>
                                  VideoPlayerScreen(item["video_url"]),
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
  const VideoPlayerScreen(this.url, {super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: controller.value.isInitialized
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () => setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  }),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
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
