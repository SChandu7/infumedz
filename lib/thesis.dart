import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';


class ThesisAssistanceScreen extends StatelessWidget {
  const ThesisAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("InfuMedz"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HERO SECTION
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E5FD8), Color(0xFF4F8BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Thesis & Publication Assistance",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "End-to-end academic support for medical professionals, residents, and students.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 SERVICES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Our Expertise",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _serviceCard(
                    icon: Icons.school,
                    title: "Thesis Assistance",
                    description:
                        "Complete guidance from topic selection, protocol writing, ethical approval, data analysis, to final manuscript submission.",
                  ),

                  _serviceCard(
                    icon: Icons.plagiarism,
                    title: "Plagiarism Services",
                    description:
                        "Plagiarism checking and reduction with proper paraphrasing, referencing, and compliance with university standards.",
                  ),

                  _serviceCard(
                    icon: Icons.psychology,
                    title: "AI Content Refinement",
                    description:
                        "AI-written content refined into human-like, original academic writing suitable for institutional acceptance.",
                  ),

                  _serviceCard(
                    icon: Icons.picture_as_pdf,
                    title: "Poster & Paper Presentations",
                    description:
                        "High-impact poster and paper designs for conferences, seminars, and academic meets.",
                  ),

                  _serviceCard(
                    icon: Icons.article,
                    title: "Publication Assistance",
                    description:
                        "Journal selection, formatting, submission handling, reviewer response, and revision support.",
                  ),

                  _serviceCard(
                    icon: Icons.slideshow,
                    title: "Journal & Seminar PPTs",
                    description:
                        "Professionally designed PowerPoint presentations with medical visuals and structured flow.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 PROCESS FLOW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "How We Work",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            _processStep("Requirement Discussion"),
            _processStep("Expert Assignment"),
            _processStep("Draft Preparation"),
            _processStep("Revisions & Quality Check"),
            _processStep("Final Delivery & Support"),

            const SizedBox(height: 32),

            /// 🔹 CONTACT FORM
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Get in Touch",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F3C68),
                      ),
                    ),
                    const SizedBox(height: 8),

                   

                    

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
_ContactChip(
  icon: Icons.call,
  phoneNumber: "+919167459135",
),
_ContactChip(
  icon: Icons.chat,
  phoneNumber: "+919167459135",
),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🔹 SERVICE CARD
  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E5FD8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0E5FD8)),
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
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 PROCESS STEP
  Widget _processStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF0E5FD8), size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 INPUT FIELD
  Widget _inputField(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

/// 🔹 CONTACT CHIP


class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String phoneNumber;
   // e.g. "+919876543210"

  const _ContactChip({
    required this.icon,
    required this.phoneNumber,
  });

  Future<void> _makeCall() async {
    final uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
     " https://wa.me/9167459138",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _handleTap() {
    if (icon == Icons.call) {
      _makeCall();
    } else if (icon == Icons.chat ) {
      _openWhatsApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        avatar: Icon(
          icon,
          color: icon == Icons.call
              ? Colors.blue
              : Colors.green,
        ),
        label: Text((icon == Icons.chat)? "Chat" :"Call"),
      ),
    );
  }
}



