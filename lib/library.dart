import 'package:flutter/material.dart';

import 'package:infumedz/views.dart';
import 'admin.dart';
import 'cart.dart';
import 'explore.dart';
import 'thesis.dart';
import 'main.dart';

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
    "image": "assets/course1.jpg",
    "progress": 30,
    "completed": 27,
    "total": 90,
  },
  {
    "title": "MD Medicine – Clinical Q&A Series",
    "image": "assets/course2.jpg",
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
