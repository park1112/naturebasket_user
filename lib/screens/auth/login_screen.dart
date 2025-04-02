import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../utils/custom_loading.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 화면 크기 조정
      body: SafeArea(
        child: Obx(() {
          return Stack(
            children: [
              _buildLoginContent(),
              if (_authController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CustomLoading(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoginContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기에 따라 다른 레이아웃 적용
        bool isSmallScreen = constraints.maxWidth < 600;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // 앱 로고
                    Container(
                      width: isSmallScreen ? 120 : 160,
                      height: isSmallScreen ? 120 : 160,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 20 : 30),
                      ),
                      child: Icon(
                        Icons.lock_open,
                        color: Colors.white,
                        size: isSmallScreen ? 60 : 80,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '다양한 방법으로 간편하게 로그인하세요',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    // 소셜 로그인 버튼들
                    SocialLoginButton(
                      type: SocialButtonType.google,
                      onPressed: _handleGoogleLogin,
                      isLoading: _authController.isLoading.value,
                    ),
                    // SocialLoginButton(
                    //   type: SocialButtonType.naver,
                    //   onPressed: _handleNaverLogin,
                    //   isLoading: _authController.isLoading.value,
                    // ),
                    SocialLoginButton(
                      type: SocialButtonType.facebook,
                      onPressed: _handleFacebookLogin,
                      isLoading: _authController.isLoading.value,
                    ),
                    SocialLoginButton(
                      type: SocialButtonType.phone,
                      onPressed: _handlePhoneLogin,
                      isLoading: _authController.isLoading.value,
                    ),
                    const SizedBox(height: 20),
                    // 앱 정보
                    Padding(
                      padding: EdgeInsets.only(bottom: isSmallScreen ? 20 : 40),
                      child: const Text(
                        '© 2025 snpsystem',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // void _handleNaverLogin() async {
  //   try {
  //     await _authController.signInWithNaver();
  //   } catch (e) {
  //     Get.snackbar('로그인 오류', '네이버 로그인 중 오류가 발생했습니다.');
  //   }
  // }

  void _handleFacebookLogin() async {
    try {
      await _authController.signInWithFacebook();
    } catch (e) {
      Get.snackbar('로그인 오류', '페이스북 로그인 중 오류가 발생했습니다.');
    }
  }

  void _handlePhoneLogin() {
    Get.to(() => const PhoneLoginScreen());
  }

  void _handleGoogleLogin() async {
    try {
      await _authController.signInWithGoogle();
    } catch (e) {
      Get.snackbar('로그인 오류', '구글 로그인 중 오류가 발생했습니다.');
    }
  }
}
