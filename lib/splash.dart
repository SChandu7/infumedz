import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infumedz/main.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fade;
  late Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainShell(), // 🔁 replace later
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurpleAccent,
              Colors.purple,
              Color.fromARGB(255, 169, 176, 240), // blue
              // purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              /// LOGO + ILLUSTRATION
              Column(
                children: [
                  Hero(
                    tag: "logo",
                    child:
                        Container(
                              height: 135,
                              width: 135,
                              decoration: BoxDecoration(
                                color: Colors.white,

                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.asset(
                                  "assets/logo2.png",
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // 🔁 FALLBACK ICON
                                    return const Icon(
                                      Icons.medical_services_rounded,
                                      size: 48,
                                      color: Color(0xFF5F6FFF),
                                    );
                                  },
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 600.ms)
                            .scale(
                              begin: const Offset(
                                0.85,
                                0.85,
                              ), // 👈 from behind (small)
                              end: const Offset(1, 1), // 👈 normal size
                              curve: Curves.easeOutBack,
                            ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                        "InfuMedz",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      )
                      .animate() // 👈 REQUIRED
                      .fadeIn(duration: 300.ms, delay: 800.ms)
                      .slideY(
                        begin: -0.18, // 👈 from LEFT
                        end: 0,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child:
                        Text(
                              "A smart medical learning platform for students, interns and professionals.\nLearn. Practice. Advance.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.6,
                                  ),
                            )
                            .animate() // 👈 REQUIRED
                            .fadeIn(duration: 300.ms, delay: 900.ms)
                            .slideY(
                              begin: -0.18, // 👈 from LEFT
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                  ),
                ],
              ),

              /// BOTTOM CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Text(
                          "Everything you need.\nNothing you don’t.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E1E),
                              ),
                        )
                        .animate() // 👈 REQUIRED
                        .fadeIn(duration: 800.ms, delay: 1000.ms)
                        .slideX(
                          begin: -0.18, // 👈 from LEFT
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 12),

                    Text(
                          "Video courses, Medical books, and Thesis Research paths – all in one place.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        )
                        .animate() // 👈 REQUIRED
                        .fadeIn(duration: 900.ms, delay: 1100.ms)
                        .slideX(
                          begin: -0.18, // 👈 from LEFT
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: size.width,
                      height: 52,
                      child:
                          ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F6FFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _goNext,
                                child: const Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              .animate() // 👈 REQUIRED
                              .fadeIn(duration: 300.ms, delay: 1600.ms)
                              .slideY(
                                begin: 0.18, // 👈 from LEFT
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                    ),
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
