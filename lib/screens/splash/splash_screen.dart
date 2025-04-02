import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  final AuthController _authController = Get.put(AuthController());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: AppConstants.introSlides.length,
                itemBuilder: (context, index) {
                  return _buildIntroSlide(
                    AppConstants.introSlides[index]['title'] ?? '',
                    AppConstants.introSlides[index]['description'] ?? '',
                    index,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: AppConstants.introSlides.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.primaryColor,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: '시작하기',
                    onPressed: () async {
                      // 첫 실행 완료 설정
                      await _authController.setFirstRunComplete();

                      // 로그인 화면으로 이동
                      Get.offAll(() => const LoginScreen());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSlide(String title, String description, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 여기에 이미지 또는 애니메이션 추가 가능
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForIndex(index),
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.login;
      case 1:
        return Icons.person;
      case 2:
        return Icons.verified_user;
      default:
        return Icons.info;
    }
  }
}
