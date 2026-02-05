import 'package:flutter/material.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      /// 🌈 HEADER
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _UserHeader(),

              SizedBox(height: 28),
              _AboutInfuMedz(),

              SizedBox(height: 32),
              _LearningProgressInline(),

              SizedBox(height: 36),
              _ContinueLearningInline(),

              SizedBox(height: 42),
              _HowItWorksTimeline(),

              SizedBox(height: 40),
              _TrustStatement(),

              SizedBox(height: 50),
              _MinimalFooter(),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                "assets/user.jpg",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Welcome back",
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text(
                "Dr. Chandu",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "MBBS • Foundation Level",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutInfuMedz extends StatelessWidget {
  const _AboutInfuMedz();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "About InfuMedz",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3C68),
            ),
          ),
          SizedBox(height: 10),
          Text(
            "InfuMedz is a focused medical learning platform crafted for students "
            "and professionals who want clarity, confidence, and consistency in "
            "their academic journey — from fundamentals to clinical mastery.",
            style: TextStyle(fontSize: 15, height: 1.7, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _LearningProgressInline extends StatelessWidget {
  const _LearningProgressInline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Learning Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.42,
            minHeight: 7,
            backgroundColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          const Text(
            "42% completed — steady progress 👏",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningInline extends StatelessWidget {
  const _ContinueLearningInline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Continue Learning",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          Row(
            children: const [
              Icon(Icons.play_circle_fill, size: 42, color: Color(0xFF4F46E5)),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  "General Medicine — Clinical Q&A Series",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorksTimeline extends StatelessWidget {
  const _HowItWorksTimeline();

  @override
  Widget build(BuildContext context) {
    final steps = [
      "Browse medical courses & books",
      "Purchase securely & unlock access",
      "Watch videos or read PDFs anytime",
      "Track progress & revise effectively",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How InfuMedz Works",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),

          ...List.generate(
            steps.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i != steps.length - 1)
                        Container(
                          width: 2,
                          height: 26,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(fontSize: 14.5),
                    ),
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

class _TrustStatement extends StatelessWidget {
  const _TrustStatement();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      color: const Color(0xFFEFF4FF),
      child: Column(
        children: const [
          Icon(Icons.verified_user, size: 34, color: Color(0xFF4F46E5)),
          SizedBox(height: 10),
          Text(
            "Secure • Verified • Confidential",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            "Your payments, learning data, and academic work are handled "
            "with complete confidentiality and professional ethics.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _MinimalFooter extends StatelessWidget {
  const _MinimalFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "© 2026 InfuMedz • Learn with confidence",
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}
