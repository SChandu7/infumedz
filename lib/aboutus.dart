import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          "About InfusionMedz",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _IntroSection(),
            SizedBox(height: 28),

            _MissionSection(),
            SizedBox(height: 32),

            _FoundersSection(),
            SizedBox(height: 32),

            _ContentTeamSection(),
            SizedBox(height: 32),

            _ContactSection(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/* ---------------- INTRO ---------------- */

class _IntroSection extends StatelessWidget {
  const _IntroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome to InfusionMedz",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F3C68),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "InfusionMedz is a trusted medical learning platform dedicated to empowering "
          "medical students and professionals through structured education, clinical "
          "insights, and digital learning resources.",
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

/* ---------------- MISSION ---------------- */

class _MissionSection extends StatelessWidget {
  const _MissionSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Our Mission",
      child: Text(
        "To enhance medical knowledge and healthcare accessibility by providing "
        "high-quality educational content, tele-consultation services, and health "
        "awareness programs. We aim to bridge the gap between medical professionals "
        "and learners across all levels.",
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

/* ---------------- FOUNDERS ---------------- */

class _FoundersSection extends StatelessWidget {
  const _FoundersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Founders & Leadership"),

        const SizedBox(height: 16),

        _TeamCard(
          name: "Dr. Akif Baig",
          role: "CEO, Founder & Content Head",
          education: "MBBS, DNB (Gen Med), DM (Cardiology)",
        ),

        _TeamCard(
          name: "Dr. M. A. Sameena Farheen",
          role: "Founder & Content Writer / Editor",
          education: "MBBS, MD (General Medicine)",
        ),

        _TeamCard(
          name: "Shaik Tameema Nawaz",
          role: "CTO, Founder & Customer Excellence Lead",
          education: "Technology & Operations",
        ),

        _TeamCard(
          name: "Dr. Harika Puligolla",
          role: "Co-Founder & Educator",
          education: "MBBS, DNB (Radiation Oncology)",
        ),

        _TeamCard(
          name: "Dr. P. Srikanth Reddy",
          role: "Educator & Marketing Head",
          education: "MBBS, MD (General Medicine)",
        ),
      ],
    );
  }
}

/* ---------------- CONTENT TEAM ---------------- */

class _ContentTeamSection extends StatelessWidget {
  const _ContentTeamSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Content Writing Team"),
        const SizedBox(height: 12),
        Text(
          "Our content team consists of experienced medical professionals "
          "dedicated to producing accurate, evidence-based educational material.",
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        _TeamCard(
          name: "Dr. Nikhila Reddy",
          role: "Content Writer & Educator",
          education: "MBBS",
        ),

        _TeamCard(
          name: "Dr. Chaithanya Reddy",
          role: "Content Writer & Educator",
          education: "MBBS",
        ),
      ],
    );
  }
}

/* ---------------- CONTACT ---------------- */

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Contact & Credentials",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Website", "www.infusionmedz.com"),
          _infoRow("Email", "infusionmedzzone@gmail.com"),
          _infoRow("Phone", "8125769855 / 9381740718 / 9700037229"),
          const SizedBox(height: 12),
          Text(
            "Registered Company: INFUMEDZ MEDICAL AND EDUCATION ZONE LLP\n"
            "Government of India | LLP Identification Number: ACL-4707",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/* ---------------- REUSABLE UI ---------------- */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F3C68),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F3C68),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  final String education;

  const _TeamCard({
    required this.name,
    required this.role,
    required this.education,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF0E5FD8),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  education,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
