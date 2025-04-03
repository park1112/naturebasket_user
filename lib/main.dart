// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_login_template/screens/auth/verification_code_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/address_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

// 웹 전용 URL 전략을 위한 함수
void _configureApp() {
  // 여기서는 아무 작업도 하지 않음
  // 필요한 경우 플랫폼별 초기화 코드를 추가할 수 있습니다
}

void main() async {
  Get.testMode = true;
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 색상 설정
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 반응형 레이아웃을 위한 화면 방향 설정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 앱 초기화 시 필요한 컨트롤러 등록
    Get.put(AuthController());
    Get.put(UserController());
    Get.put(ProductController());
    Get.put(CartController());
    Get.put(OrderController());
    Get.put(AddressController());
  } catch (e) {
    // Firebase 초기화 실패 처리
    print('Firebase initialization failed: $e');
    // 사용자에게 오류 메시지를 보여주거나 앱 종료 등의 로직 추가 가능
  }
  // await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '네이처바스켓',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => SplashWrapper()),
        GetPage(
            name: '/VerificationCodeScreen',
            page: () => VerificationCodeScreen(phoneNumber: '')),
        GetPage(name: '/LoginScreen', page: () => const LoginScreen()),
        GetPage(name: '/HomeScreen', page: () => const HomeScreen()),
        // 필요한 다른 라우트들을 추가하세요.
      ],
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  final AuthController _authController = Get.find<AuthController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // 나머지 컨트롤러 등록
      Get.put(ProductController());
      Get.put(CartController());
      Get.put(OrderController());
      Get.put(UserController());

      // 첫 실행 여부 확인
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;

      // 로그인 상태 확인
      bool isLoggedIn = _authController.firebaseUser.value != null;

      setState(() {
        _initialized = true;
      });

      // 화면 이동
      if (isLoggedIn) {
        Get.offAll(() => const HomeScreen());
      } else if (isFirstRun) {
        Get.offAll(() => const SplashScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      print('App initialization error: $e');

      // 오류 발생 시 로그인 화면으로 이동
      setState(() {
        _initialized = true;
      });
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      body: Center(
        child: !_initialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 이미지 또는 아이콘
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.eco,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '네이처바스켓',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ],
              )
            : const Text('앱을 초기화하는 중입니다...'),
      ),
    );
  }
}
