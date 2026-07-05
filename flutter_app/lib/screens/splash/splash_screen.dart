import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/animated_widgets.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2500), _navigateNext);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    if (auth.currentUser != null) {
      final user = auth.currentUser!;
      context.read<FirestoreService>().ensureDefaultAdmin(user.uid, user.email ?? '');
      NotificationService().saveToken(user.uid);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              FadeInSlide(
                delay: 200,
                duration: Duration(milliseconds: 800),
                offset: Offset(0, 30),
                child: ScaleIn(
                  delay: 0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.08),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInSlide(
                delay: 500,
                duration: const Duration(milliseconds: 600),
                child: Text(
                  AppConstants.appName,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                delay: 700,
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'تطبيق العقارات الأول في سوريا',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeInSlide(
                delay: 1000,
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
