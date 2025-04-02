// lib/controllers/auth_controller.dart
import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:flutter_naver_login/flutter_naver_login.dart';
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
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CartService _cartService = CartService();

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);

  RxBool isLoading = false.obs;
  RxString verificationId = ''.obs;
  RxInt? resendToken;

  // 로그인 상태 체크
  bool get isLoggedIn => firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();

    // Firebase 인증 상태 리스너 설정
    firebaseUser.bindStream(_authService.authStateChanges);

    // 인증 상태에 따른 초기 화면 이동
    ever(firebaseUser, _setInitialScreen);
  }

  // 초기 화면 설정 (사용자 존재 여부 및 첫 실행 여부에 따라 이동)
  _setInitialScreen(User? user) async {
    try {
      if (user == null) {
        // 첫 실행 여부 확인
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;
        if (isFirstRun) {
          Get.offAll(() => const SplashScreen());
        } else {
          Get.offAll(() => const LoginScreen());
        }
      } else {
        // 사용자 데이터 로드 (Firestore 및 로컬 저장)
        await _loadUserData(user.uid);
        // 로컬 카트를 서버에 동기화 (CartService가 존재할 경우)
        await _cartService
            .syncCart(user.uid); // syncLocalCartToServer 메서드를 syncCart로 수정
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      print('Error in setInitialScreen: $e');
      Get.offAll(() => const LoginScreen());
    }
  }

  // Firestore에서 사용자 데이터 로드 및 SharedPreferences에 저장
  Future<void> _loadUserData(String uid) async {
    try {
      // Firestore 저장 완료 대기를 위한 짧은 지연 (옵션)
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

  // SharedPreferences에서 사용자 데이터 로드 (오프라인 접근용)
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

  // 네이버 로그인
  // Future<void> signInWithNaver() async {
  //   try {
  //     isLoading.value = true;
  //     await _authService.signInWithNaver();
  //   } catch (e) {
  //     Get.snackbar('로그인 오류', '네이버 로그인에 실패했습니다: $e');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // 페이스북 로그인
  Future<void> signInWithFacebook() async {
    try {
      isLoading.value = true;
      await _authService.signInWithFacebook();
    } catch (e) {
      Get.snackbar('로그인 오류', '페이스북 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 전화번호 인증 요청
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

  // 인증 코드 확인
  Future<void> verifyPhoneCode(String smsCode) async {
    if (verificationId.value.isEmpty) {
      Get.snackbar('오류', '인증 ID가 없습니다. 전화번호 인증을 다시 시도해주세요.');
      return;
    }
    try {
      isLoading.value = true;
      await _authService.verifyPhoneCode(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      Get.snackbar('인증 성공', '전화번호 인증에 성공했습니다.');
    } catch (e) {
      Get.snackbar('인증 오류', '인증 코드가 올바르지 않습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
    } catch (e) {
      Get.snackbar('로그인 오류', '구글 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 이메일 로그인
  Future<void> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.snackbar('로그인 성공', '이메일로 로그인되었습니다.');
    } catch (e) {
      Get.snackbar('로그인 오류', '이메일 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 회원가입 (이메일 기반)
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
      }
      Get.snackbar('회원가입 성공', '회원가입이 완료되었습니다.');
    } catch (e) {
      Get.snackbar('회원가입 오류', '회원가입 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
      userModel.value = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      Get.snackbar('로그아웃', '로그아웃되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final String? userId = firebaseUser.value?.uid;
      if (userId == null) {
        Get.snackbar('오류', '로그인 정보를 찾을 수 없습니다.');
        return;
      }
      // 인증 정보 및 사용자 데이터 삭제 (프로필 이미지 삭제 및 백업 등 내부 처리)
      await _authService.deleteUser(userId);
      userModel.value = null;
      firebaseUser.value = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      // Firebase 인증 로그아웃 (예외 발생 시 무시)
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        print('Firebase signOut error (무시): $signOutError');
      }
      // 모든 인증 토큰 및 자동 로그인 정보 삭제
      await _clearAllAuthTokens();
      Get.snackbar('계정 삭제', '계정이 삭제되었습니다.');
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar('오류', '계정 삭제 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 모든 인증 토큰 및 자동 로그인 정보 삭제
  Future<void> _clearAllAuthTokens() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
      await prefs.remove(AppConstants.keyIsFirstRun);
      // 소셜 로그인 토큰 삭제
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

  // 첫 실행 완료 설정
  Future<void> setFirstRunComplete() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsFirstRun, false);
    } catch (e) {
      print('Error setting first run complete: $e');
    }
  }
}
