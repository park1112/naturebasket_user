// lib/controllers/auth_controller.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:flutter_naver_login/flutter_naver_login.dart'; // 네이버 로그인 필요 시 주석 해제
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/cart_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';

class AuthController extends GetxController {
  // 서비스 인스턴스 (생성자 주입 대신 내부에서 생성)
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CartService _cartService = CartService();

  // Firebase User와 사용자 모델 Rx 변수 (late 없이 즉시 초기화)
  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);

  // 로그인 상태 확인
  RxBool isLoggedIn = false.obs;

  // 로딩 상태, 인증 관련 변수들
  RxBool isLoading = false.obs;
  RxString verificationId = ''.obs;
  RxInt? resendToken;

  // 로그인 타입 관리 (Secure Storage 사용)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final RxString _loginTypeStr = ''.obs;

  // 로그인 타입 getter
  LoginType get loginType {
    final typeStr = _loginTypeStr.value;
    if (typeStr == LoginType.email.toString()) {
      return LoginType.email;
    } else if (typeStr == LoginType.google.toString()) {
      return LoginType.google;
    } else if (typeStr == LoginType.facebook.toString()) {
      return LoginType.facebook;
    } else if (typeStr == LoginType.naver.toString()) {
      return LoginType.naver;
    } else if (typeStr == LoginType.phone.toString()) {
      return LoginType.phone;
    } else {
      return LoginType.unknown;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Firebase 인증 상태 스트림 바인딩
    firebaseUser.bindStream(_authService.authStateChanges);
    // 인증 상태에 따른 초기 화면 이동 처리
    ever(firebaseUser, _setInitialScreen);

    // 로그인 상태 업데이트
    ever(firebaseUser, (user) {
      isLoggedIn.value = user != null;
    });

    // 앱 시작 시 이미 로그인된 경우 로그인 타입 불러오기
    if (_authService.currentUser != null) {
      _loadLoginType();
    }
  }

  // 초기 화면 설정: 사용자 존재 여부와 첫 실행 여부에 따라 이동
  _setInitialScreen(User? user) async {
    try {
      if (user == null) {
        // 사용자가 없는 경우 로그인 또는 스플래시 화면으로 이동
        await _clearLoginType(); // 로그인 타입 초기화
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;
        if (isFirstRun) {
          Get.offAll(() => const SplashScreen());
        } else {
          Get.offAll(() => const LoginScreen());
        }
      } else {
        // 사용자가 존재하는 경우 사용자 데이터 로드 및 카트 동기화
        await _loadUserData(user.uid);
        await _cartService.syncCart(user.uid);
        _loadLoginType(); // 로그인 타입 불러오기
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      print('Error in setInitialScreen: $e');
      Get.offAll(() => const LoginScreen());
    }
  }

  // Firestore에서 사용자 데이터 로드 후 SharedPreferences에 저장
  Future<void> _loadUserData(String uid) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      UserModel? userData = await _userService.getUser(uid);
      if (userData != null) {
        userModel.value = userData;
        await _userService.saveUserToLocal(userData);
      }
    } catch (e) {
      print('Error loading user data: $e');
      _loadUserFromPrefs();
    }
  }

  // SharedPreferences에서 사용자 데이터 불러오기 (오프라인 접근용)
  Future<void> _loadUserFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString(AppConstants.keyUserData);
      if (userData != null) {
        userModel.value = UserModel.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  // 로그인 타입 불러오기 (Secure Storage)
  Future<void> _loadLoginType() async {
    try {
      final storedType = await _secureStorage.read(key: 'loginType');
      if (storedType != null) {
        _loginTypeStr.value = storedType;
      } else {
        _loginTypeStr.value = '';
      }
    } catch (e) {
      print("Error loading login type: $e");
      _loginTypeStr.value = '';
    }
  }

  // 로그인 타입 저장
  Future<void> saveLoginType(LoginType type) async {
    try {
      final typeString = type.toString();
      await _secureStorage.write(key: 'loginType', value: typeString);
      _loginTypeStr.value = typeString;
    } catch (e) {
      print("Error saving login type: $e");
    }
  }

  // 로그인 타입 삭제
  Future<void> _clearLoginType() async {
    try {
      await _secureStorage.delete(key: 'loginType');
      _loginTypeStr.value = '';
    } catch (e) {
      print("Error clearing login type: $e");
    }
  }

  // --- 전화번호 인증 관련 메서드들 ---
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      isLoading.value = true;
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (String vId, int? token) {
          verificationId.value = vId;
          resendToken = RxInt(token ?? 0);
          isLoading.value = false;
          Get.snackbar('인증 코드 발송', '입력하신 전화번호로 인증 코드가 발송되었습니다.');
        },
        onVerificationCompleted: (String message) {
          isLoading.value = false;
          Get.snackbar('인증 완료', message);
        },
        onError: (String errorMessage) {
          isLoading.value = false;
          Get.snackbar('인증 오류', errorMessage);
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('오류', '전화번호 인증 요청 중 오류가 발생했습니다.');
    }
  }

  // 전화번호 인증 코드 확인 후 로그인 처리
  Future<void> signInWithPhoneNumber(String smsCode) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // 전화번호 로그인 시 사용자 모델 생성
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          name: '전화번호 사용자',
          email: null,
          phoneNumber: userCredential.user!.phoneNumber,
          photoURL: null,
          loginType: LoginType.phone,
          lastLogin: DateTime.now(),
          loginHistory: [
            {'timestamp': DateTime.now(), 'loginType': 'phone'}
          ],
          point: 0,
        );
        // Firestore에 저장하거나 로컬에 저장 (서비스 메서드에 따라 수정)
        await _userService.saveUserToLocal(newUser);
        await saveLoginType(LoginType.phone); // 로그인 타입 저장
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      Get.snackbar('로그인 실패', '인증번호가 잘못되었거나 오류가 발생했습니다.');
      print("Phone sign-in error: $e");
    }
  }

  // 전화번호 인증 코드 확인
  Future<void> verifyPhoneCode(String smsCode) async {
    try {
      isLoading.value = true;
      await signInWithPhoneNumber(smsCode);
    } catch (e) {
      Get.snackbar('인증 오류', '인증 코드가 올바르지 않습니다.');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // --- 소셜 및 이메일 로그인/회원가입 메서드 ---
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
      await saveLoginType(LoginType.google);
    } catch (e) {
      Get.snackbar('로그인 오류', '구글 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      isLoading.value = true;
      await _authService.signInWithFacebook();
      await saveLoginType(LoginType.facebook);
    } catch (e) {
      Get.snackbar('로그인 오류', '페이스북 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await saveLoginType(LoginType.email);
      Get.snackbar('로그인 성공', '이메일로 로그인되었습니다.');
    } catch (e) {
      Get.snackbar('로그인 오류', '이메일 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      isLoading.value = true;
      // Firebase 인증으로 계정 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        // 사용자 프로필 업데이트 (displayName 설정)
        await userCredential.user!.updateDisplayName(name);
        // Firestore에 사용자 정보 저장 (초기 데이터 업데이트)
        await _userService.updateUserProfile(
          uid: userCredential.user!.uid,
          name: name,
          phoneNumber: null,
        );
        await saveLoginType(LoginType.email);
      }
      Get.snackbar('회원가입 성공', '회원가입이 완료되었습니다.');
    } catch (e) {
      Get.snackbar('회원가입 오류', '회원가입 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 로그아웃: 인증 토큰, 로그인 타입, 로컬 사용자 데이터 삭제 후 로그인 화면으로 이동
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
      userModel.value = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await _clearLoginType();
      Get.snackbar('로그아웃', '로그아웃되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 계정 삭제: Firestore 및 인증, 로컬 데이터, 소셜 로그인 토큰 삭제 처리
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final String? userId = firebaseUser.value?.uid;
      if (userId == null) {
        Get.snackbar('오류', '로그인 정보를 찾을 수 없습니다.');
        return;
      }
      await _authService.deleteUser(userId);
      userModel.value = null;
      firebaseUser.value = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        print('Firebase signOut error (무시): $signOutError');
      }
      await _clearAllAuthTokens();
      Get.snackbar('계정 삭제', '계정이 삭제되었습니다.');
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar('오류', '계정 삭제 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 모든 인증 토큰 및 자동 로그인 정보 삭제 (소셜 로그인 토큰 포함)
  Future<void> _clearAllAuthTokens() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await prefs.remove(AppConstants.keyIsFirstRun);
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FacebookAuth.instance.logOut();
        // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        //   await FlutterNaverLogin.logOut();
        // }
      } catch (e) {
        print('소셜 로그인 토큰 삭제 중 오류: $e');
      }
    } catch (e) {
      print('인증 토큰 삭제 중 오류: $e');
    }
  }

  // 첫 실행 완료 설정 (SplashScreen 이후)
  Future<void> setFirstRunComplete() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsFirstRun, false);
    } catch (e) {
      print('Error setting first run complete: $e');
    }
  }
}
