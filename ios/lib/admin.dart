import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:infumedz/views.dart';
import 'package:infumedz/main.dart';
import 'package:path/path.dart' as path;
import 'package:animate_do/animate_do.dart';



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

    setState(() => loading = true);

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiConfig.base}/infumedz/upload/"),
    );

    req.fields["title"] = "Human Anatomy Basics";
    req.fields["description"] = "Medical content upload";
    req.fields["content_type"] = "BOTH";

    if (pdf != null) {
      req.files.add(await http.MultipartFile.fromPath("pdf", pdf!.path));
    }

    final response = await req.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploaded Successfully")));

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed (${response.statusCode})")),
      );
    }

    /// Upload to S3 (same upload API)
    // final req = http.MultipartRequest(
    //   "POST",
    //   Uri.parse("${ApiConfig.base}/infumedz/upload/"),
    // );

    // req.fields["title"] = title.text;
    // req.fields["content_type"] = "PDF";
    // req.files.add(await http.MultipartFile.fromPath("pdf", pdf!.path));

    // final res = await req.send();
    final body = jsonDecode(await response.stream.bytesToString());
    final pdfUrl = body["pdf_url"];

    /// Save under book
    final res = await http.post(
      Uri.parse(ApiConfig.addBookPdf),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "book": bookId,
        "title": title.text,
        "pdf_url": pdfUrl,
        "order": int.parse(order.text),
      }),
    );
    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploaded Successfully")));

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed (${res.statusCode})")),
      );
    }

    setState(() {
      loading = false;
      pdf = null;
      title.clear();
      order.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ PDF added to book")));
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

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool fabOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      /// 🔹 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0E5FD8),
        title: const Text(
          "Admin Panel",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
         
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.notifications_none, color: Color(0xFF0E5FD8)),
          ),
          const SizedBox(width: 12),
        ],
      ),

      /// 🔹 BODY
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// ===== ADMIN HEADER =====
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(Icons.person, size: 30, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Akif Ahamad",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "Welcome back, Administrator",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      const SizedBox(height: 30),

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

      const SizedBox(height: 30),

      /// ===== ANALYTICS TITLE =====
      const Text(
        "Analytics Overview",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),

      const SizedBox(height: 16),

      /// ===== CHART CARD =====
      Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Growth",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(1, 2),
                        FlSpot(2, 1.5),
                        FlSpot(3, 3),
                        FlSpot(4, 3.8),
                      ],
                      isCurved: true,
                      barWidth: 4,
                      dotData: FlDotData(show: false),
                      color: Colors.indigo,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),

      const SizedBox(height: 30),

      /// ===== RECENT ACTIVITY =====
      const Text(
        "Recent Activity",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),

      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: const [
            _ActivityTile("New User Registered", "2 mins ago"),
            Divider(),
            _ActivityTile("Course Purchased", "10 mins ago"),
            Divider(),
            _ActivityTile("Thesis Request Submitted", "1 hour ago"),
          ],
        ),
      ),

      const SizedBox(height: 100),
    ],
  ),
),


      /// 🔹 FLOATING ACTION MENU
      floatingActionButton: _buildExpandableFab(),
    );
  }

  /// 🔹 FLOATING ACTION BUTTON WITH ANIMATION
  Widget _buildExpandableFab() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (fabOpen)
          GestureDetector(
            onTap: () => setState(() => fabOpen = false),
            child: Container(
             // color: Colors.black.withOpacity(0.2),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        Positioned(
          bottom: 80,
          right: 16,
          child: Column(
            children: [
              if (fabOpen)
                _fabOption(Icons.add, "Add Courses"),
              
              if (fabOpen)
                _fabOption(Icons.picture_as_pdf, "Add Books"),
                if (fabOpen)
                _fabOption(Icons.published_with_changes, "Data Replace"),
           
            ],
          ),
        ),

        FloatingActionButton(
          backgroundColor: const Color(0xFF0E5FD8),
          onPressed: () => setState(() => fabOpen = !fabOpen),
          child: AnimatedRotation(
            turns: fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 50),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  /// 🔹 FAB OPTION
  Widget _fabOption(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
        heroTag: label,
        backgroundColor: Colors.white,
        onPressed: () {
          if(icon == Icons.add){
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCourseFlow()),
              );
           
    
          }else if(icon == Icons.picture_as_pdf){
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBookFlow()),
              );
    
          }else{
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBannerScreen()),
              );
    
          }
        },
        icon: Icon(icon, color: const Color(0xFF0E5FD8)),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0E5FD8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF0E5FD8)),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
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
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
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

  List<String> carouselUrls = [];
  bool loading = true;
  bool uploadingImage = false;

  final apiUrl = "https://api.chandus7.in/api/infumedz/app-banner/";

  @override
  void initState() {
    super.initState();
    fetchData();
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
          carouselUrls =
              rawUrls.whereType<String>().toList(); // 🔐 safe cast
        } else {
          carouselUrls = [];
        }

        loading = false;
      });
    } catch (e) {
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }

  /* ================= IMAGE UPLOAD ================= */

  Future<void> pickAndUploadImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

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
      await http.MultipartFile.fromPath(
        "thumbnail",
        imageFile.path,
      ),
    );

    final response = await request.send();
    final responseBody =
        await response.stream.transform(utf8.decoder).join();

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image uploaded")),
    );
  } catch (e) {
    setState(() => uploadingImage = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
    );
  }
}


  /* ================= SAVE ================= */

  Future<void> saveData() async {
    try {
      await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "about_text": aboutController.text.trim(),
          "carousel_urls": carouselUrls,
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    }
  }

  /* ================= UI HELPERS ================= */

  void deleteImage(int index) {
    setState(() => carouselUrls.removeAt(index));
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("App Banner Manager")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ABOUT TEXT
          const Text(
            "About / Hint Text",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: aboutController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter about text...",
            ),
          ),

          const SizedBox(height: 24),

          /// UPLOAD IMAGE
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: uploadingImage ? null : pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: Text(uploadingImage ? "Uploading..." : "Upload Image"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// CAROUSEL PREVIEW
          const Text(
            "Carousel Images",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 180,
            child: carouselUrls.isEmpty
                ? const Center(child: Text("No images"))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: carouselUrls.length,
                    itemBuilder: (_, i) {
                      final url = carouselUrls[i];

                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade200,
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => deleteImage(i),
                              child: const CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 14,
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

          const SizedBox(height: 30),

          /// SAVE BUTTON
          ElevatedButton(
            onPressed: saveData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
            ),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}
