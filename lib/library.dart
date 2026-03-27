import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infumedz/loginsignup.dart';
import 'package:infumedz/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'explore.dart';
import 'views.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchLibrary(); // ✅ FIX (THIS WAS MISSING)
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchLibrary() async {
    final userId = await UserSession.getUserId();

    if (userId == null) {
      return {"courses": [], "books": []};
    }

    final res = await http.get(
      Uri.parse("https://api.chandus7.in/api/infumedz/library/$userId/"),
    );

    if (res.statusCode != 200) {
      return {"courses": [], "books": []};
    }

    final body = jsonDecode(res.body);

    return {
      "courses": List<Map<String, dynamic>>.from(body["courses"] ?? []),
      "books": List<Map<String, dynamic>>.from(body["books"] ?? []),
    };
  }

  Widget _shimmerBox({double? width, double? height, double radius = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      onEnd: () {
        if (mounted) setState(() {});
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE8EDF5),
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats row skeleton ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            3,
            (_) => Column(
              children: [
                _shimmerBox(width: 40, height: 26),
                const SizedBox(height: 6),
                _shimmerBox(width: 60, height: 12),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Section title ──
        _shimmerBox(width: 120, height: 18),
        const SizedBox(height: 14),

        // ── Course cards ──
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // thumbnail
                _shimmerBox(width: 90, height: 70, radius: 10),
                const SizedBox(width: 12),
                // title lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 14, width: double.infinity),
                      const SizedBox(height: 8),
                      _shimmerBox(height: 14, width: 140),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // button
                _shimmerBox(width: 60, height: 34, radius: 8),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Books section title ──
        _shimmerBox(width: 100, height: 18),
        const SizedBox(height: 14),

        // ── Book cards ──
        ...List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _shimmerBox(width: 90, height: 70, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 14, width: double.infinity),
                      const SizedBox(height: 8),
                      _shimmerBox(height: 14, width: 120),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _shimmerBox(width: 60, height: 34, radius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          "My Library",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLibrarySkeleton();
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load library"));
          }

          final courses = snapshot.data?["courses"] ?? [];
          final books = snapshot.data?["books"] ?? [];

          if (courses.isEmpty && books.isEmpty) {
            return const _EmptyLibrary();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LibraryStats(courses: courses.length, books: books.length),

              if (courses.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "My Courses",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...courses.map((c) => _LibraryCourseCard(course: c)),
              ],

              if (books.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "My Books",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...books.map((b) => _LibraryPdfCard(pdf: b)),
              ],
            ],
          );
        },
      ),
    );
  }
}

/* ---------------- STATS ---------------- */

class _LibraryStats extends StatelessWidget {
  final int courses;
  final int books;

  const _LibraryStats({required this.courses, required this.books});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(title: "Courses", value: courses.toString()),
        _StatItem(title: "Books", value: books.toString()),
        const _StatItem(title: "Completed", value: "—"),
      ],
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

/* ---------------- COURSE CARD ---------------- */

class _LibraryCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _LibraryCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              course["thumbnail"] ?? "",
              width: 90,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 90,
                  height: 70,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              course["title"],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailLoaderScreen(
                    id: course["course_id"],
                    type: "course",
                  ),
                ),
              );
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }
}

/* ---------------- PDF CARD ---------------- */

class _LibraryPdfCard extends StatelessWidget {
  final Map<String, dynamic> pdf;
  const _LibraryPdfCard({required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          /// 📘 THUMBNAIL
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              pdf["thumbnail"] ?? "",
              width: 90,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 90,
                  height: 70,
                  color: Colors.red.withOpacity(0.1),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 32,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          /// 📄 TITLE
          Expanded(
            child: Text(
              pdf["title"] ?? "Untitled Book",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),

          /// 🔓 OPEN
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailLoaderScreen(
                    id: pdf["book_id"],
                    type: "book",
                  ),
                ),
              );
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }
}

/* ---------------- EMPTY ---------------- */

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text("No purchases yet"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicalStoreScreen()),
              );
            },
            child: const Text("Browse Courses"),
          ),
        ],
      ),
    );
  }
}

class CourseDetailLoaderScreen extends StatefulWidget {
  final String id;
  final String type; // "course" | "book"

  const CourseDetailLoaderScreen({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  State<CourseDetailLoaderScreen> createState() =>
      _CourseDetailLoaderScreenState();
}

class _CourseDetailLoaderScreenState extends State<CourseDetailLoaderScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchDetails();
  }

  Future<Map<String, dynamic>> fetchDetails() async {
    final url = widget.type == "course"
        ? "https://api.chandus7.in/api/infumedz/courses/${widget.id}/"
        : "https://api.chandus7.in/api/infumedz/books/${widget.id}/";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("Failed to load details");
    }

    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          print(snapshot.error);
          return const Scaffold(
            body: Center(
              child: Text(
                "This Course Will Be Deleted / Does'nt Exist \n Please Contact  Officials For any Queries ",
              ),
            ),
          );
        }

        return CourseDetailScreen(
          data: snapshot.data!,
          option: widget.type == "book" ? "Books" : "Courses",
          isLocked: false,
        );
      },
    );
  }
}
