import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:infumedz/chat.dart';
import 'dart:async';
import 'package:infumedz/views.dart';
import 'package:infumedz/main.dart';
import 'package:path/path.dart' as path;
import 'package:animate_do/animate_do.dart';
import 'loginsignup.dart';

class AdminPanelHome extends StatelessWidget {
  const AdminPanelHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: const Color(0xFF0E5FD8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AdminCard(
              title: "Manage Courses",
              subtitle: "Add courses & video lectures",
              icon: Icons.play_circle_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCourseFlow()),
                );
              },
            ),
            const SizedBox(height: 16),
            _AdminCard(
              title: "Manage Books",
              subtitle: "Add books & PDF chapters",
              icon: Icons.menu_book,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookFlow()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0E5FD8),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class AdminCourseFlow extends StatefulWidget {
  const AdminCourseFlow({super.key});

  @override
  State<AdminCourseFlow> createState() => _AdminCourseFlowState();
}

class _AdminCourseFlowState extends State<AdminCourseFlow> {
  String mode = "course"; // course | video

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Management"),
        backgroundColor: const Color(0xFF0E5FD8),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [mode == "course", mode == "video"],
            onPressed: (i) {
              setState(() {
                mode = i == 0 ? "course" : "video";
              });
            },
            borderRadius: BorderRadius.circular(12),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Add Course"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Add Videos"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: mode == "course"
                ? const AddCourseForm()
                : const AddCourseVideoForm(),
          ),
        ],
      ),
    );
  }
}

class AddCourseForm extends StatefulWidget {
  const AddCourseForm({super.key});

  @override
  State<AddCourseForm> createState() => _AddCourseFormState();
}

class _AddCourseFormState extends State<AddCourseForm> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();
  final thumbnail = TextEditingController();
  File? thumbnailImage;
  bool uploadingThumbnail = false;
  String? uploadedThumbnailUrl;

  int? categoryId; // ✅ CORRECT

  List<Map<String, dynamic>> categories = [];
  bool loadingCategories = true;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickThumbnail() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        thumbnailImage = File(picked.path);
      });
    }
  }

  Future<void> uploadThumbnailAndCreateCourse() async {
    try {
      setState(() => uploadingThumbnail = true);

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConfig.uploadThumbnail),
      );

      request.files.add(
        await http.MultipartFile.fromPath("thumbnail", thumbnailImage!.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.transform(utf8.decoder).join();
      final body = responseBody.isNotEmpty ? jsonDecode(responseBody) : {};

      if (response.statusCode != 201) {
        setState(() => uploadingThumbnail = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thumbnail upload failed")),
        );
        return;
      }

      /// 🔹 NOW CREATE COURSE
      final res = await http.post(
        Uri.parse(ApiConfig.createCourse),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title.text.trim(),
          "description": desc.text.trim(),
          "price": double.parse(price.text),
          "category": categoryId,
          "thumbnail_url": body["thumbnail_url"],
        }),
      );

      setState(() => uploadingThumbnail = false);

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Course Created")));

        title.clear();
        desc.clear();
        price.clear();
        setState(() {
          categoryId = null;
          thumbnailImage = null;
          uploadedThumbnailUrl = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: ${res.body}")));
      }
    } on SocketException catch (e) {
      // 🚨 Upload actually completed
      debugPrint("Socket closed after upload: $e");

      // 🔹 IMPORTANT: Continue anyway
      // If backend already got the URL, proceed
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> createCourse() async {
    if (thumbnailImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a thumbnail")),
      );
      return;
    }

    if (categoryId == null ||
        title.text.isEmpty ||
        desc.text.isEmpty ||
        price.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    await uploadThumbnailAndCreateCourse();
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories));
    if (res.statusCode == 200) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        loadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Create New Course",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: "Course Title"),
        ),
        TextField(
          controller: desc,
          decoration: const InputDecoration(labelText: "Description"),
        ),
        TextField(
          controller: price,
          decoration: const InputDecoration(labelText: "Price"),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Course Thumbnail",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: pickThumbnail,
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: thumbnailImage == null
                        ? const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              thumbnailImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),

                  /// ✏️ EDIT ICON (ONLY WHEN IMAGE EXISTS)
                  if (thumbnailImage != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : CategoryDropdown(
                categories: categories,
                onSelected: (id) {
                  categoryId = id; // ✅ int goes into int?
                },
              ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: uploadingThumbnail ? null : createCourse,
          child: Text(uploadingThumbnail ? "Uploading..." : "Create Course"),
        ),
      ],
    );
  }
}

class CategoryDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ValueChanged<int> onSelected;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  int? selected; // ✅ MUST be int?

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selected,
      decoration: const InputDecoration(
        labelText: "Category",
        border: OutlineInputBorder(),
      ),
      items: widget.categories.map((c) {
        return DropdownMenuItem<int>(
          value: c["id"], // ✅ int
          child: Text(c["name"]), // ✅ String
        );
      }).toList(),
      onChanged: (int? v) {
        setState(() => selected = v);
        if (v != null) widget.onSelected(v);
      },
    );
  }
}

class AddCourseVideoForm extends StatefulWidget {
  const AddCourseVideoForm({super.key});

  @override
  State<AddCourseVideoForm> createState() => _AddCourseVideoFormState();
}

class _AddCourseVideoFormState extends State<AddCourseVideoForm> {
  List<Map<String, dynamic>> courses = [];
  String? courseId;

  final title = TextEditingController();
  final order = TextEditingController();
  double uploadProgress = 0.0;
  bool uploading = false;

  File? video;
  bool loading = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    final res = await http.get(Uri.parse(ApiConfig.courses));
    if (res.statusCode == 200) {
      setState(() {
        courses = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => video = File(picked.path));
    }
  }

  Future<void> uploadVideo() async {
    if (courseId == null || video == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select course & video")));
      return;
    }

    setState(() {
      uploading = true;
      uploadProgress = 0.0;
    });

    // 1️⃣ Ask Django for presigned URL

    final presignRes = await http.post(
      Uri.parse(ApiConfig.presignedVideoUpload),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "filename": path.basename(video!.path),
        "content_type": "video/mp4",
      }),
    );

    final presigned = jsonDecode(presignRes.body);
    final uploadUrl = presigned["upload_url"];
    final fileUrl = presigned["file_url"];

    setState(() => uploadProgress = 0.2);

    // 2️⃣ Upload directly to S3
    final bytes = await video!.readAsBytes();

    final s3Res = await http.put(
      Uri.parse(uploadUrl),
      headers: {"Content-Type": "video/mp4"},
      body: bytes,
    );

    if (s3Res.statusCode != 200) {
      setState(() {
        uploading = false;
        uploadProgress = 0.0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("S3 upload failed")));
      return;
    }

    setState(() => uploadProgress = 0.7);

    // 3️⃣ Save URL in Django (NO CHANGE)
    final res = await http.post(
      Uri.parse(ApiConfig.addCourseVideo),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "course": courseId,
        "title": title.text,
        "video_url": fileUrl,
        "order": int.tryParse(order.text) ?? 1,
      }),
    );

    setState(() {
      uploading = false;
      uploadProgress = 1.0;
      video = null;
      title.clear();
      order.clear();
    });

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video added successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.body)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Add Video to Course",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: courseId,
          decoration: InputDecoration(
            labelText: "Select Course $courseId",
            border: OutlineInputBorder(),
          ),
          items: courses.map<DropdownMenuItem<String>>((c) {
            return DropdownMenuItem<String>(
              value: c["id"].toString(), // ✅ FORCE STRING
              child: Text(c["title"].toString()),
            );
          }).toList(),
          onChanged: (String? v) {
            setState(() => courseId = v);
          },
        ),

        SizedBox(height: 12),

        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: "Video Title"),
        ),

        TextField(
          controller: order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Order (1,2,3...)"),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: pickVideo,
          icon: const Icon(Icons.video_library),
          label: Text(video == null ? "Pick Video" : "Video Selected"),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: uploading ? null : uploadVideo,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: uploading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Uploading...",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: uploadProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${(uploadProgress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : const Text(
                  "Add Video",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

class AdminBookFlow extends StatefulWidget {
  const AdminBookFlow({super.key});

  @override
  State<AdminBookFlow> createState() => _AdminBookFlowState();
}

class _AdminBookFlowState extends State<AdminBookFlow> {
  String mode = "book";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Management"),
        backgroundColor: const Color(0xFF0E5FD8),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [mode == "book", mode == "pdf"],
            onPressed: (i) {
              setState(() => mode = i == 0 ? "book" : "pdf");
            },
            children: const [
              Padding(padding: EdgeInsets.all(12), child: Text("Add Book")),
              Padding(padding: EdgeInsets.all(12), child: Text("Add PDFs")),
            ],
          ),
          Expanded(
            child: mode == "book"
                ? const AddBookForm()
                : const AddBookPdfForm(),
          ),
        ],
      ),
    );
  }
}

class AddBookForm extends StatefulWidget {
  const AddBookForm({super.key});

  @override
  State<AddBookForm> createState() => _AddBookFormState();
}

class _AddBookFormState extends State<AddBookForm> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();
  final thumbnail = TextEditingController();

  int? categoryId;
  List<Map<String, dynamic>> categories = [];
  bool loading = true;
  File? thumbnailImage;
  bool uploadingThumbnail = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> pickThumbnail() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        thumbnailImage = File(picked.path);
      });
    }
  }

  Future<void> createBook() async {
    if (categoryId == null ||
        title.text.isEmpty ||
        desc.text.isEmpty ||
        price.text.isEmpty ||
        thumbnailImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    try {
      /// 1️⃣ UPLOAD THUMBNAIL
      setState(() => uploadingThumbnail = true);

      final uploadReq = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConfig.uploadThumbnail),
      );

      uploadReq.files.add(
        await http.MultipartFile.fromPath("thumbnail", thumbnailImage!.path),
      );

      final uploadRes = await uploadReq.send();
      final uploadBody = jsonDecode(await uploadRes.stream.bytesToString());

      if (uploadRes.statusCode != 201) {
        throw Exception("Thumbnail upload failed");
      }

      final thumbnailUrl = uploadBody["thumbnail_url"];

      /// 2️⃣ CREATE BOOK
      final res = await http.post(
        Uri.parse(ApiConfig.createBook),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title.text.trim(),
          "description": desc.text.trim(),
          "price": double.parse(price.text),
          "category": categoryId,
          "thumbnail_url": thumbnailUrl, // ✅ S3 URL
        }),
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Book Created")));

        title.clear();
        desc.clear();
        price.clear();
        setState(() {
          categoryId = null;
          thumbnailImage = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.body)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $e")));
    } finally {
      setState(() => uploadingThumbnail = false);
    }
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse(ApiConfig.categories));
    if (res.statusCode == 200) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Create Book",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),
        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: "Book Title"),
        ),
        TextField(
          controller: desc,
          decoration: const InputDecoration(labelText: "Description"),
        ),
        TextField(
          controller: price,
          decoration: const InputDecoration(labelText: "Price"),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Book Thumbnail",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: pickThumbnail,
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: thumbnailImage == null
                        ? const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              thumbnailImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),

                  /// ✏️ EDIT ICON
                  if (thumbnailImage != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        loading
            ? const Center(child: CircularProgressIndicator())
            : CategoryDropdown(
                categories: categories,
                onSelected: (id) => categoryId = id,
              ),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: uploadingThumbnail ? null : createBook,
          child: uploadingThumbnail
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Create Book"),
        ),
      ],
    );
  }
}

class AddBookPdfForm extends StatefulWidget {
  const AddBookPdfForm({super.key});

  @override
  State<AddBookPdfForm> createState() => _AddBookPdfFormState();
}

class _AddBookPdfFormState extends State<AddBookPdfForm> {
  List<Map<String, dynamic>> books = [];
  String? bookId;

  final title = TextEditingController();
  final order = TextEditingController();

  File? pdf;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    final res = await http.get(Uri.parse(ApiConfig.books));
    if (res.statusCode == 200) {
      setState(() {
        books = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => pdf = File(result.files.single.path!));
    }
  }

  Future<void> uploadPdf() async {
    if (bookId == null || pdf == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select book & PDF")));
      return;
    }

    setState(() {
      loading = true;
    });
    final rawName = path.basename(pdf!.path);
    final safeName = Uri.encodeComponent(rawName);

    /// 1️⃣ Ask backend for presigned PDF upload URL
    final presignRes = await http.post(
      Uri.parse(ApiConfig.presignedPdfUpload),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "filename": safeName,
        "content_type": "application/pdf",
      }),
    );

    if (presignRes.statusCode != 200) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(" $presignRes  ........")));
      return;
    }

    final presigned = jsonDecode(presignRes.body);
    final uploadUrl = presigned["upload_url"];
    final fileUrl = presigned["file_url"];

    /// 2️⃣ Upload PDF to S3
    final bytes = await pdf!.readAsBytes();

    final s3Res = await http.put(
      Uri.parse(uploadUrl),
      headers: {"Content-Type": "application/pdf"},
      body: bytes,
    );

    if (s3Res.statusCode != 200) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PDF upload failed")));
      return;
    }

    /// 3️⃣ Save PDF URL under Book
    final res = await http.post(
      Uri.parse(ApiConfig.addBookPdf),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "book": bookId,
        "title": title.text,
        "pdf_url": fileUrl,
        "order": int.tryParse(order.text) ?? 1,
      }),
    );

    setState(() {
      loading = false;
      pdf = null;
      title.clear();
      order.clear();
    });

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ PDF added successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed $fileUrl: ${res.body}")));
      print(fileUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Add PDF Chapter",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: bookId,
          decoration: const InputDecoration(labelText: "Select Book"),
          items: books.map((b) {
            return DropdownMenuItem<String>(
              value: b["id"].toString(),
              child: Text(b["title"]),
            );
          }).toList(),
          onChanged: (v) => setState(() => bookId = v),
        ),

        const SizedBox(height: 12),
        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: "Chapter Title"),
        ),
        TextField(
          controller: order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Order"),
        ),

        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: pickPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(pdf == null ? "Pick PDF" : "PDF Selected"),
        ),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loading ? null : uploadPdf,
          child: Text(loading ? "Uploading..." : "Add PDF"),
        ),
      ],
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text("Are you sure you want to logout from InfuMedz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await UserSession.logout();

              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => MainShell()),
                (_) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// APP NAME
          Center(
            child: const Text(
              "InfuMedz",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),

          /// QUICK LINKS
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: const [_FooterLink("Log-out  ➜]")],
            ),
          ),
          const SizedBox(height: 10),

          const Divider(),

          const SizedBox(height: 14),

          /// SUPPORT
          const Text(
            "Support",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            "support@infumedz.com",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          const Text(
            "+91 9XXXXXXXXX",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),

          /// LOGOUT BUTTON
          const SizedBox(height: 14),

          /// COPYRIGHT
          Center(
            child: Text(
              "© 2026 InfuMedz. All rights reserved.",
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text("Are you sure you want to logout from InfuMedz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await UserSession.logout();

              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (_) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showLogoutDialog(context);
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4F46E5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool fabOpen = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),

        /// 🔹 APP BAR
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 78,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E5FD8), Color(0xFF3B82F6)],
              ),
            ),
          ),

          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Monitor & control your platform",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          actions: [
            /// 🔴 LIVE STATUS
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "LIVE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// 🔔 NOTIFICATIONS
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0E5FD8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => AdminDashboardScreen(),
                          ),
                        );
                        // TODO: open admin notifications
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🔴 NOTIFICATION DOT
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        /// 🔹 BODY
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ===== ADMIN HEADER =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    // 👤 AVATAR + STATUS
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.indigo.shade50,
                          child: ClipOval(
                            child: Image(
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              image: AssetImage("assets/admin.jpg"),
                              errorBuilder: (_, _, _) {
                                return const Icon(
                                  Icons.security,
                                  size: 26,
                                  color: Color(0xFF0E5FD8),
                                );
                              },
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // 🧠 INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Akif Ahamad Baig",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Administrator",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔘 ACTION
                    Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ===== KPI ROW =====
              Row(
                children: const [
                  _DashboardMetric(
                    title: "Total Users",
                    value: "2,430",
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 12),
                  _DashboardMetric(
                    title: "Total Courses",
                    value: "42",
                    icon: Icons.play_circle,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: const [
                  _DashboardMetric(
                    title: "Orders",
                    value: "128",
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 12),
                  _DashboardMetric(
                    title: "Requests",
                    value: "36",
                    icon: Icons.article,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// ===== ANALYTICS TITLE =====
              const Text(
                "Analytics Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              /// ===== CHART CARD =====
              Container(
                height: 260,
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "User Growth (Last 7 Days)",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 120,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.15),
                                strokeWidth: 1,
                              );
                            },
                          ),

                          borderData: FlBorderData(show: false),

                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),

                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun",
                                  ];
                                  if (value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        days[value.toInt()],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),

                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  return LineTooltipItem(
                                    "${spot.y.toInt()} users",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),

                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              curveSmoothness: 0.25,
                              barWidth: 4,
                              color: const Color(0xFF0E5FD8),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF0E5FD8).withOpacity(0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 3.5,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF0E5FD8),
                                  );
                                },
                              ),
                              spots: const [
                                FlSpot(0, 40),
                                FlSpot(1, 55),
                                FlSpot(2, 48),
                                FlSpot(3, 70),
                                FlSpot(4, 90),
                                FlSpot(5, 105),
                                FlSpot(6, 115),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ===== RECENT ACTIVITY =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFF0E5FD8)),
                      SizedBox(width: 8),
                      Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "The Latest Activities held ",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  children: const [
                    _SmartActivityTile(
                      icon: Icons.person_add_alt_1,
                      title: "New user registered",
                      subtitle: "MBBS student joined the platform",
                      time: "2 mins ago",
                      color: Colors.green,
                    ),
                    Divider(height: 26),

                    _SmartActivityTile(
                      icon: Icons.shopping_cart_checkout,
                      title: "Course purchased",
                      subtitle: "MD Medicine – Clinical Q&A",
                      time: "10 mins ago",
                      color: Colors.blue,
                    ),
                    Divider(height: 26),

                    _SmartActivityTile(
                      icon: Icons.description,
                      title: "Thesis request submitted",
                      subtitle: "Awaiting admin review",
                      time: "1 hour ago",
                      color: Colors.orange,
                    ),
                    Divider(height: 26),

                    _SmartActivityTile(
                      icon: Icons.insights,
                      title: "User activity recorded",
                      subtitle: "Learning progress updated",
                      time: "1 hour ago",
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _AppFooter(),

              const SizedBox(height: 100),
            ],
          ),
        ),

        /// 🔹 FLOATING ACTION MENU
      ),
    );
  }
}

class _SmartActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _SmartActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ICON
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: 12),

        // TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // TIME CHIP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 15),

                    Center(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String time;

  const _ActivityTile(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(time, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  final aboutController = TextEditingController();
  final imageUrlController = TextEditingController();
  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> serverCategories = []; // 🔐 never touched

  List<Map<String, dynamic>> categories = []; // server truth
  List<Map<String, dynamic>> tempCategories = []; // dialog working copy

  List<String> popularCourseIds = [];
  List<String> popularBookIds = [];

  List<String> carouselUrls = [];
  bool loading = true;
  bool uploadingImage = false;

  final apiUrl = "https://api.chandus7.in/api/infumedz/app-banner/";

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchAdminData();
    fetchCategories();
  }

  /* ================= FETCH ================= */

  Future<void> fetchData() async {
    try {
      final res = await http.get(Uri.parse(apiUrl));
      final data = jsonDecode(res.body);

      setState(() {
        aboutController.text = data["about_text"]?.toString() ?? "";

        final rawUrls = data["carousel_urls"];
        if (rawUrls is List) {
          carouselUrls = rawUrls.whereType<String>().toList(); // 🔐 safe cast
        } else {
          carouselUrls = [];
        }

        loading = false;
      });
    } catch (e) {
      loading = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
    }
  }

  void _openCategoryDialog(BuildContext context) {
    tempCategories = List<Map<String, dynamic>>.from(categories);

    final TextEditingController newCategoryCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Manage Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// CATEGORY LIST
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: tempCategories.length,
                        itemBuilder: (_, i) {
                          final cat = tempCategories[i];
                          return ListTile(
                            title: Text(cat["name"]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  tempCategories.removeAt(i);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    /// ADD CATEGORY
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCategoryCtrl,
                            decoration: const InputDecoration(
                              hintText: "New category name",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (newCategoryCtrl.text.trim().isEmpty) return;
                            setDialogState(() {
                              tempCategories.add({
                                "id": 5, // new
                                "name": newCategoryCtrl.text.trim(),
                              });
                              newCategoryCtrl.clear();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              categories = List<Map<String, dynamic>>.from(
                                tempCategories,
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        "ⓘ Don’t forget to save changes",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Future<void> syncCategories() async {
    // 🔥 DELETE
    for (final old in serverCategories) {
      final exists = categories.any((c) => c["id"] == old["id"]);

      if (!exists && old["id"] != null) {
        debugPrint("Deleting category ${old["id"]}");

        await http.delete(
          Uri.parse("https://api.chandus7.in/api/infumedz/categories/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"id": old["id"]}),
        );
      }
    }
    final existingNames = categories
        .map((c) => c["name"].toString().toLowerCase())
        .toSet();

    for (final cat in categories) {
      final name = cat["name"].toString().trim();

      if (!existingNames.contains(name.toLowerCase())) {
        debugPrint("Adding category $name");

        final res = await http.post(
          Uri.parse("https://api.chandus7.in/api/infumedz/categories/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"name": name}),
        );

        debugPrint("Status: ${name}");
        debugPrint("Body: ${res.body}");
      }
    }

    debugPrint(
      "CURRENT: ---------------------------------------------------------------",
    );

    debugPrint("SERVER: $serverCategories");
    debugPrint("CURRENT: $categories");

    // 🔄 Refresh after sync
    await fetchCategories();
  }

  Future<void> fetchCategories() async {
    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/categories/"),
    );

    final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));

    setState(() {
      serverCategories = List.from(data); // 🔐 server truth
      categories = List.from(data); // editable UI
    });
  }

  Future<void> fetchAdminData() async {
    final bannerRes = await http.get(Uri.parse(apiUrl));
    final coursesRes = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/get/courses/"),
    );
    final booksRes = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/books/"),
    );

    final banner = jsonDecode(bannerRes.body);
    final courses = List<Map<String, dynamic>>.from(
      jsonDecode(coursesRes.body),
    );
    final books = List<Map<String, dynamic>>.from(jsonDecode(booksRes.body));

    final courseIds = courses.map((c) => c["id"]).toSet();
    final bookIds = books.map((b) => b["id"]).toSet();

    setState(() {
      allCourses = courses;
      allBooks = books;

      // ✅ CLEAN DELETED REFERENCES
      popularCourseIds = List<String>.from(
        banner["popular_courses"] ?? [],
      ).where(courseIds.contains).toList();

      popularBookIds = List<String>.from(
        banner["popular_books"] ?? [],
      ).where(bookIds.contains).toList();

      aboutController.text = banner["about_text"] ?? "";
      carouselUrls = List<String>.from(banner["carousel_urls"] ?? []);
      loading = false;
    });
  }

  /* ================= IMAGE UPLOAD ================= */

  Future<void> pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    await uploadBannerImage(File(picked.path));
  }

  Future<void> uploadBannerImage(File imageFile) async {
    try {
      setState(() => uploadingImage = true);

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConfig.uploadThumbnail),
      );

      /// 🔑 FIELD NAME MUST BE `thumbnail`
      request.files.add(
        await http.MultipartFile.fromPath("thumbnail", imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.transform(utf8.decoder).join();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Upload failed: $responseBody");
      }

      final data = jsonDecode(responseBody);
      final thumbnailUrl = data["thumbnail_url"];

      if (thumbnailUrl == null) {
        throw Exception("thumbnail_url missing in response");
      }

      /// ✅ Update UI ONLY
      setState(() {
        carouselUrls.add(thumbnailUrl);
        uploadingImage = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image uploaded")));
    } catch (e) {
      setState(() => uploadingImage = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  void _openPopularDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITLE
                      const Text(
                        "Update Popular Content",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// COURSES
                      const Text(
                        "Popular Courses",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),

                      courseDropdownDialog(0, setDialogState),
                      courseDropdownDialog(1, setDialogState),
                      courseDropdownDialog(2, setDialogState),

                      const SizedBox(height: 16),
                      const Divider(),

                      /// BOOKS
                      const Text(
                        "Popular Books",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),

                      bookDropdownDialog(0, setDialogState),
                      bookDropdownDialog(1, setDialogState),
                      bookDropdownDialog(2, setDialogState),

                      const SizedBox(height: 20),

                      /// ACTIONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Apply"),
                          ),
                        ],
                      ),
                      Center(
                        child: Text(
                          " ⓘ Don’t forget to save changes",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget courseDropdownDialog(
    int index,
    void Function(void Function()) setDialogState,
  ) {
    final value =
        (index < popularCourseIds.length &&
            allCourses.any((c) => c["id"] == popularCourseIds[index]))
        ? popularCourseIds[index]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text("Select Popular Course ${index + 1}"),
        items: allCourses.map((course) {
          return DropdownMenuItem<String>(
            value: course["id"],
            child: Text(course["title"]),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;
          setDialogState(() {
            if (popularCourseIds.length <= index) {
              popularCourseIds.add(val);
            } else {
              popularCourseIds[index] = val;
            }
          });
        },
      ),
    );
  }

  Widget courseDropdown(int index) {
    final value = index < popularCourseIds.length
        ? popularCourseIds[index]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E4FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        hint: Text(
          "Select Popular Course ${index + 1}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: allCourses.map((course) {
          return DropdownMenuItem<String>(
            value: course["id"],
            child: Row(
              children: [
                const Icon(Icons.school, size: 18, color: Color(0xFF0E5FD8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course["title"],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (popularCourseIds.length <= index) {
              popularCourseIds.add(value);
            } else {
              popularCourseIds[index] = value;
            }
          });
        },
      ),
    );
  }

  Widget bookDropdownDialog(
    int index,
    void Function(void Function()) setDialogState,
  ) {
    final value = index < popularBookIds.length ? popularBookIds[index] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text("Select Popular Book ${index + 1}"),
        items: allBooks.map((book) {
          return DropdownMenuItem<String>(
            value: book["id"],
            child: Text(book["title"]),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;
          setDialogState(() {
            if (popularBookIds.length <= index) {
              popularBookIds.add(val);
            } else {
              popularBookIds[index] = val;
            }
          });
        },
      ),
    );
  }

  Widget bookDropdown(int index) {
    final value = index < popularBookIds.length ? popularBookIds[index] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E4FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        hint: Text(
          "Select Popular Book ${index + 1}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: allBooks.map((book) {
          return DropdownMenuItem<String>(
            value: book["id"],
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: Color(0xFF0E5FD8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    book["title"],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (popularBookIds.length <= index) {
              popularBookIds.add(value);
            } else {
              popularBookIds[index] = value;
            }
          });
        },
      ),
    );
  }

  void _openAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // stays open until action
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                const Text(
                  "Edit About / Hint Text",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 10),

                /// INFO
                const Text(
                  "This text appears as the scrolling hint on the home screen.",
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 12),

                /// TEXT FIELD
                TextField(
                  controller: aboutController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Enter about text...",
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// ACTION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // ✅ FIXED
                      },
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // only close dialog, saving happens later
                        Navigator.of(dialogContext).pop(); // ✅ FIXED
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Apply"),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    "ⓘ Don’t forget to save changes",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ================= SAVE ================= */

  Future<void> saveData() async {
    await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "about_text": aboutController.text.trim(),
        "carousel_urls": carouselUrls,
        "popular_courses": popularCourseIds,
        "popular_books": popularBookIds,
      }),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Saved successfully")));
  }

  /* ================= UI HELPERS ================= */

  void deleteImage(int index) {
    setState(() => carouselUrls.removeAt(index));
  }

  Widget configCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER ROW
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5FD8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF0E5FD8), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),

          if (child != null) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("App Banner Manager")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ABOUT / HINT TEXT
          configCard(
            icon: Icons.info_outline,
            title: "1. About / Hint Text",
            subtitle: "Edit the scrolling hint text shown on home screen",
            onTap: () => _openAboutDialog(context),
          ),

          /// CAROUSEL IMAGES
          configCard(
            icon: Icons.image_outlined,
            title: "2. Carousel Images",
            subtitle: "${carouselUrls.length} banner images configured",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// PREVIEW
                SizedBox(
                  height: 150,
                  child: carouselUrls.isEmpty
                      ? const Center(child: Text("No images added"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: carouselUrls.length,
                          itemBuilder: (_, i) {
                            final url = carouselUrls[i];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 240,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => deleteImage(i),
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                /// ADD IMAGE BUTTON (SUBTLE)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: uploadingImage ? null : pickAndUploadImage,
                    icon: uploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      uploadingImage ? "Uploading..." : "Add Banner Image",
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          /// POPULAR CONTENT
          configCard(
            icon: Icons.star_outline,
            title: "3. Popular Courses & Books",
            subtitle: "Select 3 popular courses and books for home screen",
            onTap: () => _openPopularDialog(context),
          ),

          const SizedBox(height: 2),
          configCard(
            icon: Icons.category_outlined,
            title: "4. Categories",
            subtitle: "${categories.length} categories configured",
            onTap: () => _openCategoryDialog(context),
          ),
          const SizedBox(height: 10),

          /// SAVE
          ElevatedButton(
            onPressed: () async {
              await saveData();
              await syncCategories();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.blue[300],

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AdminDeleteDialog extends StatefulWidget {
  const AdminDeleteDialog({super.key});

  @override
  State<AdminDeleteDialog> createState() => _AdminDeleteDialogState();
}

class _AdminDeleteDialogState extends State<AdminDeleteDialog> {
  String deleteType = "course";

  String? selectedCourseId;
  String? selectedVideoId;

  String? selectedBookId;
  String? selectedPdfId;

  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> books = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final cRes = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/courses/"),
    );
    final bRes = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/books/"),
    );

    setState(() {
      courses = List<Map<String, dynamic>>.from(jsonDecode(cRes.body));
      books = List<Map<String, dynamic>>.from(jsonDecode(bRes.body));
      loading = false;
    });
  }

  Future<void> deleteByType() async {
    String? url;

    switch (deleteType) {
      case "course":
        url = "https://api.chandus7.in/api/infumedz/course/$selectedCourseId/";
        break;

      case "course_video":
        url =
            "https://api.chandus7.in/api/infumedz/course/video/$selectedVideoId/delete/";
        break;

      case "book":
        url = "https://api.chandus7.in/api/infumedz/book/$selectedBookId/";
        break;

      case "book_pdf":
        url =
            "https://api.chandus7.in/api/infumedz/book/pdf/$selectedPdfId/delete/";
        break;
    }

    if (url == null) return;

    final res = await http.delete(Uri.parse(url));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Deleted successfully")));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Content"),
      content: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔘 TYPE SWITCH
                Column(
                  children: [
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 42),
                      isSelected: [
                        deleteType == "course",
                        deleteType == "course_video",
                      ],
                      onPressed: (i) {
                        setState(() {
                          deleteType = i == 0 ? "course" : "course_video";
                          selectedCourseId = null;
                          selectedVideoId = null;
                          selectedBookId = null;
                          selectedPdfId = null;
                        });
                      },
                      children: const [
                        SizedBox(
                          width: 100, // ✅ SAME WIDTH
                          child: Center(child: Text("Course")),
                        ),
                        SizedBox(
                          width: 100, // ✅ SAME WIDTH
                          child: Center(child: Text("Course Video")),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 42),
                      isSelected: [
                        deleteType == "book",
                        deleteType == "book_pdf",
                      ],
                      onPressed: (i) {
                        setState(() {
                          deleteType = i == 0 ? "book" : "book_pdf";
                          selectedCourseId = null;
                          selectedVideoId = null;
                          selectedBookId = null;
                          selectedPdfId = null;
                        });
                      },
                      children: const [
                        SizedBox(
                          width: 100, // ✅ SAME WIDTH
                          child: Center(child: Text("Book")),
                        ),
                        SizedBox(
                          width: 100, // ✅ SAME WIDTH
                          child: Center(child: Text("Book PDF")),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// COURSE SELECT
                if (deleteType == "course" || deleteType == "course_video")
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Course"),
                    value: selectedCourseId,
                    items: courses.map((c) {
                      return DropdownMenuItem(
                        value: c["id"].toString(),
                        child: Text(c["title"]),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCourseId = v;
                        selectedVideoId = null;
                      });
                    },
                  ),
                SizedBox(height: 10),

                /// VIDEO SELECT
                if (deleteType == "course_video" && selectedCourseId != null)
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Video"),
                    value: selectedVideoId,
                    items: courses
                        .firstWhere(
                          (c) => c["id"] == selectedCourseId,
                        )["videos"]
                        .map<DropdownMenuItem<String>>((v) {
                          return DropdownMenuItem(
                            value: v["id"].toString(),
                            child: Text(v["title"]),
                          );
                        })
                        .toList(),
                    onChanged: (v) => setState(() => selectedVideoId = v),
                  ),

                /// BOOK SELECT
                if (deleteType == "book" || deleteType == "book_pdf")
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Book"),
                    value: selectedBookId,
                    items: books.map((b) {
                      return DropdownMenuItem(
                        value: b["id"].toString(),
                        child: Text(b["title"]),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedBookId = v;
                        selectedPdfId = null;
                      });
                    },
                  ),
                SizedBox(height: 10),

                /// PDF SELECT
                if (deleteType == "book_pdf" && selectedBookId != null)
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select PDF"),
                    value: selectedPdfId,
                    items: books
                        .firstWhere((b) => b["id"] == selectedBookId)["pdfs"]
                        .map<DropdownMenuItem<String>>((p) {
                          return DropdownMenuItem(
                            value: p["id"].toString(),
                            child: Text(p["title"]),
                          );
                        })
                        .toList(),
                    onChanged: (v) => setState(() => selectedPdfId = v),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirm Delete"),
                content: const Text(
                  "This action will remove content permanently.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes, Delete"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await deleteByType();
            }
          },
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
