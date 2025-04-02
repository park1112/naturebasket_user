import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  Rx<UserModel?> get user => _authController.userModel;

  RxBool isLoading = false.obs;
  Rx<File?> selectedImage = Rx<File?>(null);

  // 프로필 이미지 선택
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('오류', '이미지 선택 중 오류가 발생했습니다: $e');
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? name,
  }) async {
    if (_authController.firebaseUser.value == null || user.value == null) {
      Get.snackbar('오류', '로그인된 사용자 정보가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;

      String uid = _authController.firebaseUser.value!.uid;
      String? photoURL;

      // 이미지가 선택되었다면 업로드
      if (selectedImage.value != null) {
        photoURL = await _firestoreService.uploadProfileImage(
          uid,
          selectedImage.value!,
        );
      }

      // 프로필 정보 업데이트
      await _firestoreService.updateUserProfile(
        uid: uid,
        name: name,
        photoURL: photoURL,
      );

      // 사용자 정보 리로드
      await _reloadUserData(uid);

      Get.snackbar('성공', '프로필이 업데이트되었습니다.');

      // 이미지 선택 초기화
      selectedImage.value = null;
    } catch (e) {
      Get.snackbar('오류', '프로필 업데이트 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 사용자 정보 다시 로드
  Future<void> _reloadUserData(String uid) async {
    try {
      UserModel? userData = await _firestoreService.getUser(uid);
      if (userData != null) {
        _authController.userModel.value = userData;
      }
    } catch (e) {
      print('Error reloading user data: $e');
    }
  }
}
