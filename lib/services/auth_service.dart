import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_login_template/config/constants.dart';
// import 'package:flutter_naver_login/flutter_naver_login.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 감지
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 네이버 로그인
  // Future<UserCredential?> signInWithNaver() async {
  //   try {
  //     if (kIsWeb) {
  //       throw '웹에서는 네이버 로그인을 지원하지 않습니다.';
  //     }

  //     if (!(Platform.isAndroid || Platform.isIOS)) {
  //       throw '모바일 플랫폼에서만 네이버 로그인이 가능합니다.';
  //     }

  //     // 네이버 로그인 SDK 사용하여 로그인
  //     // NaverLoginResult result = await FlutterNaverLogin.logIn();

  //     if (result.status == NaverLoginStatus.loggedIn) {
  //       // 액세스 토큰 가져오기
  //       final NaverAccessToken token =
  //           await FlutterNaverLogin.currentAccessToken;

  //       // 네이버 사용자 프로필 정보 가져오기
  //       NaverAccountResult account = await FlutterNaverLogin.currentAccount();

  //       // Firebase 사용자 생성 또는 업데이트
  //       UserCredential userCredential = await _createOrUpdateNaverUser(account);

  //       return userCredential;
  //     }
  //     return null;
  //   } catch (e) {
  //     print('Naver sign in error: $e');
  //     rethrow;
  //   }
  // }

  // // 네이버 사용자 생성 또는 업데이트 (Firebase Custom Auth 구현 예시)
  // Future<UserCredential> _createOrUpdateNaverUser(
  //     NaverAccountResult account) async {
  //   // 실제 구현에서는 Firebase Function을 통해 받은 커스텀 토큰으로 로그인
  //   // 이 예시에서는 실제 통합 구현이 불가능하므로 이메일/비밀번호 로그인으로 대체

  //   try {
  //     // 이메일로 기존 사용자 확인 (실제 구현에서는 네이버 ID로 매칭)
  //     UserCredential? userCredential;
  //     try {
  //       userCredential = await _auth.signInWithEmailAndPassword(
  //         email: '${account.email}',
  //         password: 'naver_auth_${account.id}', // 실제 구현에서는 이렇게 하지 않음
  //       );
  //     } catch (e) {
  //       // 사용자가 없으면 새로 생성
  //       userCredential = await _auth.createUserWithEmailAndPassword(
  //         email: '${account.email}',
  //         password: 'naver_auth_${account.id}', // 실제 구현에서는 이렇게 하지 않음
  //       );
  //     }

  //     // 사용자 정보 업데이트
  //     await userCredential.user?.updateDisplayName(account.name);
  //     await userCredential.user?.updatePhotoURL(account.profileImage);

  //     // Firestore에 사용자 정보 저장
  //     if (userCredential.user != null) {
  //       await _firestoreService.createOrUpdateUser(
  //         UserModel(
  //           uid: userCredential.user!.uid,
  //           name: account.name,
  //           email: account.email,
  //           photoURL: account.profileImage,
  //           loginType: LoginType.naver,
  //           lastLogin: DateTime.now(),
  //         ),
  //       );
  //     }

  //     return userCredential;
  //   } catch (e) {
  //     print('Create/Update Naver user error: $e');
  //     rethrow;
  //   }
  // }

  // 페이스북 로그인
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // 웹용 페이스북 로그인
        FacebookAuth instance = FacebookAuth.instance;
        final LoginResult result = await instance.login();

        if (result.status == LoginStatus.success) {
          // 액세스 토큰 얻기
          final AccessToken accessToken = result.accessToken!;

          // Facebook 인증 정보 생성
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Firebase에 로그인
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);

          // 페이스북에서 추가 사용자 정보 가져오기
          final userData = await FacebookAuth.instance.getUserData();

          // Firestore에 사용자 정보 저장
          if (userCredential.user != null) {
            await _firestoreService.createOrUpdateUser(
              UserModel(
                uid: userCredential.user!.uid,
                name: userCredential.user!.displayName,
                email: userCredential.user!.email,
                photoURL: userCredential.user!.photoURL,
                loginType: LoginType.facebook,
                lastLogin: DateTime.now(),
              ),
            );
          }

          return userCredential;
        }

        return null;
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 모바일용 페이스북 로그인
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          // 액세스 토큰 얻기
          final AccessToken accessToken = result.accessToken!;

          // Facebook 인증 정보 생성
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Firebase에 로그인
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);

          // 페이스북에서 추가 사용자 정보 가져오기
          final userData = await FacebookAuth.instance.getUserData();

          // Firestore에 사용자 정보 저장
          if (userCredential.user != null) {
            await _firestoreService.createOrUpdateUser(
              UserModel(
                uid: userCredential.user!.uid,
                name: userCredential.user!.displayName,
                email: userCredential.user!.email,
                photoURL: userCredential.user!.photoURL,
                loginType: LoginType.facebook,
                lastLogin: DateTime.now(),
              ),
            );
          }

          return userCredential;
        }

        return null;
      } else {
        throw '지원하지 않는 플랫폼입니다.';
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      rethrow;
    }
  }

  // 전화번호 로그인 - 인증 코드 요청
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(String) onVerificationCompleted,
    required Function(String) onError,
  }) async {
    try {
      if (kIsWeb) {
        // 웹용 reCAPTCHA 설정
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
          phoneNumber: phoneNumber,
        );
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android 자동 인증만 지원
          if (!kIsWeb && Platform.isAndroid) {
            await _auth.signInWithCredential(credential);
            onVerificationCompleted('인증이 자동으로 완료되었습니다.');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? '전화번호 인증에 실패했습니다.');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // 자동 코드 검색 시간 초과
        },
      );
    } catch (e) {
      onError('전화번호 인증 요청 중 오류가 발생했습니다: $e');
    }
  }

  // 전화번호 로그인 - 인증 코드 확인
  Future<UserCredential?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // 인증 정보 생성
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Firebase에 로그인
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장
      if (userCredential.user != null) {
        await _firestoreService.createOrUpdateUser(
          UserModel(
            uid: userCredential.user!.uid,
            phoneNumber: userCredential.user!.phoneNumber,
            loginType: LoginType.phone,
            lastLogin: DateTime.now(),
          ),
        );
      }

      return userCredential;
    } catch (e) {
      print('Phone verification error: $e');
      rethrow;
    }
  }

  // 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 구글 로그인 초기화
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 플랫폼 확인 및 적절한 로그인 방식 적용
      if (kIsWeb) {
        // 웹용 구글 로그인
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        // 기존 사용자 데이터 확인
        UserModel? existingUser =
            await _firestoreService.getUser(userCredential.user!.uid);

        // Firestore에 사용자 정보 저장
        if (userCredential.user != null) {
          // 기존 데이터와 새 데이터 병합
          await _firestoreService.createOrUpdateUser(
            UserModel(
              uid: userCredential.user!.uid,
              name: existingUser?.name ?? userCredential.user!.displayName,
              email: userCredential.user!.email,
              photoURL: existingUser?.photoURL ?? userCredential.user!.photoURL,
              loginType: LoginType.google,
              lastLogin: DateTime.now(),
            ),
          );
        }

        return userCredential;
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 모바일용 구글 로그인
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          return null; // 사용자가 로그인 취소
        }

        // 인증 정보 얻기
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // 구글 인증 정보 생성
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase에 로그인
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Firestore에 사용자 정보 저장
        if (userCredential.user != null) {
          await _firestoreService.createOrUpdateUser(
            UserModel(
              uid: userCredential.user!.uid,
              name: userCredential.user!.displayName,
              email: userCredential.user!.email,
              photoURL: userCredential.user!.photoURL,
              loginType: LoginType.google,
              lastLogin: DateTime.now(),
            ),
          );
        }

        return userCredential;
      } else {
        throw '지원하지 않는 플랫폼입니다.';
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 현재 사용자의 로그인 타입 확인
        UserModel? userModel = await _firestoreService.getUser(user.uid);

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            if (userModel?.loginType == LoginType.naver) {
              // await FlutterNaverLogin.logOut();
            } else if (userModel?.loginType == LoginType.google) {
              // 구글 로그아웃 추가
              await GoogleSignIn().signOut();
            }
          } catch (e) {
            print('Social logout error: $e');
            // 소셜 로그아웃 실패해도 계속 진행
          }
        }

        // 페이스북 로그아웃
        if (userModel?.loginType == LoginType.facebook) {
          await FacebookAuth.instance.logOut();
        }
      }

      // Firebase 로그아웃
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // 계정 삭제
  Future<void> deleteUser(String uid) async {
    try {
      // 1. 유효한 UID 검증
      if (uid.isEmpty) {
        throw Exception("유효하지 않은 사용자 ID입니다.");
      }

      // 2. Firestore에서 사용자 문서 가져오기
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("해당 ID의 사용자가 존재하지 않습니다.");
      }

      // 사용자 데이터 가져오기
      final Map<String, dynamic>? userData =
          userDoc.data() as Map<String, dynamic>?;

      // 3. 프로필 이미지 삭제 처리: 사용자 데이터에 photoURL이 있을 경우에만 삭제 시도
      if (userData != null &&
          userData.containsKey("photoURL") &&
          (userData["photoURL"]?.toString().isNotEmpty ?? false)) {
        try {
          final storageRef = _storage.ref('profile_images/$uid.jpg');
          await storageRef.delete();
          print('프로필 이미지가 성공적으로 삭제되었습니다.');
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            print('프로필 이미지 파일이 존재하지 않아 삭제를 건너뜁니다.');
          } else {
            print('프로필 이미지 삭제 중 오류: $e');
          }
        }
      } else {
        print('사용자 정보에 프로필 이미지 URL이 없으므로, 이미지 삭제를 건너뜁니다.');
      }

      // 4. 사용자 데이터를 백업 컬렉션(deleted_users)에 저장 (삭제 시간 추가)
      if (userData != null) {
        userData["deletedAt"] = FieldValue.serverTimestamp();
        await _firestore.collection("deleted_users").doc(uid).set(userData);
        print('사용자 데이터가 백업 컬렉션(deleted_users)에 저장되었습니다.');
      }

      // 5. Firestore에서 사용자 문서 삭제
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();
      print('Firestore에서 사용자 데이터가 삭제되었습니다.');

      // 6. Firebase Auth 사용자 삭제 시도 (선택 사항)
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          await currentUser.delete();
          print('Firebase Auth 사용자 계정이 삭제되었습니다.');
        }
      } catch (authError) {
        if (authError is FirebaseAuthException &&
            authError.code == 'requires-recent-login') {
          throw Exception("계정 삭제를 위해 재로그인이 필요합니다.");
        } else {
          print('Firebase Auth 사용자 삭제 중 오류: $authError');
        }
      }

      // 7. 로그아웃 및 로그인 관련 토큰 삭제 처리
      await FirebaseAuth.instance.signOut();
      print('사용자가 로그아웃되었습니다.');
      // 필요 시 SharedPreferences나 기타 저장소에 저장된 토큰도 삭제하세요.
      // 예: await SharedPreferences.getInstance().then((prefs) => prefs.clear());
    } catch (e) {
      print('사용자 삭제 중 오류 발생: $e');
      rethrow;
    }
  }
}
