import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

Widget _guarantee() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_user, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "100% Confidentiality • Ethical Academic Practices • Plagiarism-Safe • Human-Verified Content",
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _outcomes() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Real Outcomes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F3C68),
            ),
          ),
          SizedBox(height: 10),
          Text("• Theses accepted in top Indian universities"),
          Text("• Publications in indexed journals"),
          Text("• Successful conference presentations"),
          Text("• Faculty promotion documentation support"),
        ],
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF0E5FD8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStep extends StatelessWidget {
  final String text;
  const _MiniStep(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF0E5FD8),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class ThesisAssistanceScreen extends StatelessWidget {
  const ThesisAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("InfuMedz Services "),
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

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "How We Work",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F3C68),
                    ),
                  ),
                  SizedBox(height: 14),
                  _MiniStep("1. Requirement Review"),
                  _MiniStep("2. Expert Allocation"),
                  _MiniStep("3. Draft Development"),
                  _MiniStep("4. Quality & Ethics Check"),
                  _MiniStep("5. Final Delivery & Support"),
                ],
              ),
            ),

            /// 🔹 PROCESS FLOW
            const SizedBox(height: 1),
            _outcomes(),
            const SizedBox(height: 10),
            _guarantee(),
            const SizedBox(height: 1),

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
                          phoneNumber: "+919381740718",
                        ),
                        _ContactChip(
                          icon: Icons.chat,
                          phoneNumber: "9381740718",
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
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10),
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
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

/// 🔹 CONTACT CHIP

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String phoneNumber; // "+919167459135" allowed here

  const _ContactChip({required this.icon, required this.phoneNumber});

  String get _cleanNumber =>
      phoneNumber.replaceAll("+", "").replaceAll(" ", "");

  Future<void> _makeCall() async {
    final uri = Uri(scheme: 'tel', path: _cleanNumber);
    if (!await launchUrl(uri)) {
      debugPrint("Could not launch call");
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri(scheme: 'https', host: 'wa.me', path: _cleanNumber);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not open WhatsApp");
    }
  }

  void _handleTap() {
    if (icon == Icons.call) {
      _makeCall();
    } else {
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
          color: icon == Icons.call ? Colors.blue : Colors.green,
        ),
        label: Text(icon == Icons.call ? "Call" : "Chat"),
      ),
    );
  }
}

enum ContactAction { call, whatsapp }
