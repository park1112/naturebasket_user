// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';

import '../config/constants.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid uuid = Uuid();

  // 사용자 정보 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('사용자 정보 조회 중 오류: $e');
      return null;
    }
  }

  // 사용자 정보 업데이트
  Future<bool> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (preferences != null) updateData['preferences'] = preferences;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update(updateData);
      }

      return true;
    } catch (e) {
      print('사용자 정보 업데이트 중 오류: $e');
      return false;
    }
  }

  // 프로필 이미지 업로드
  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      String filePath = 'profile_images/$uid.jpg';

      // 스토리지에 이미지 업로드
      await _storage.ref(filePath).putFile(imageFile);

      // 다운로드 URL 가져오기
      String downloadURL = await _storage.ref(filePath).getDownloadURL();

      // 사용자 정보에 이미지 URL 업데이트
      await updateUserProfile(uid: uid, photoURL: downloadURL);

      return downloadURL;
    } catch (e) {
      print('프로필 이미지 업로드 중 오류: $e');
      return null;
    }
  }

  // 사용자 로컬 데이터 저장
  Future<void> saveUserToLocal(UserModel user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.keyUserData, jsonEncode(user.toJson()));
    } catch (e) {
      print('사용자 로컬 데이터 저장 중 오류: $e');
    }
  }

  // 사용자 로컬 데이터 조회
  Future<UserModel?> getUserFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString(AppConstants.keyUserData);

      if (userData != null) {
        Map<String, dynamic> userJson = jsonDecode(userData);
        return UserModel.fromJson(userJson);
      }

      return null;
    } catch (e) {
      print('사용자 로컬 데이터 조회 중 오류: $e');
      return null;
    }
  }

  // 배송지 추가
  Future<bool> addAddress(String uid, AddressModel address) async {
    try {
      // 현재 사용자 정보 조회
      UserModel? user = await getUser(uid);

      if (user == null) {
        print('사용자를 찾을 수 없습니다.');
        return false;
      }

      // 새 배송지 생성 (고유 ID 할당)
      AddressModel newAddress = address.copyWith(
        id: uuid.v4(),
      );

      // 기존 배송지 목록 가져오기
      List<AddressModel> addresses = user.addresses;

      // 새 배송지가 기본 배송지로 설정된 경우 다른 배송지들의 기본 설정 해제
      if (newAddress.isDefault) {
        addresses =
            addresses.map((addr) => addr.copyWith(isDefault: false)).toList();
      }

      // 새 배송지 추가
      addresses.add(newAddress);

      // Firestore 업데이트
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('배송지 추가 중 오류: $e');
      return false;
    }
  }

  // 배송지 업데이트
  Future<bool> updateAddress(String uid, AddressModel address) async {
    try {
      // 현재 사용자 정보 조회
      UserModel? user = await getUser(uid);

      if (user == null) {
        print('사용자를 찾을 수 없습니다.');
        return false;
      }

      // 기존 배송지 목록 가져오기
      List<AddressModel> addresses = user.addresses;

      // 업데이트할 배송지 찾기
      int index = addresses.indexWhere((addr) => addr.id == address.id);

      if (index == -1) {
        print('업데이트할 배송지를 찾을 수 없습니다.');
        return false;
      }

      // 새 배송지가 기본 배송지로 설정된 경우 다른 배송지들의 기본 설정 해제
      if (address.isDefault) {
        addresses = addresses
            .map((addr) =>
                addr.id == address.id ? addr : addr.copyWith(isDefault: false))
            .toList();
      }

      // 배송지 업데이트
      addresses[index] = address;

      // Firestore 업데이트
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('배송지 업데이트 중 오류: $e');
      return false;
    }
  }

  // 배송지 삭제
  Future<bool> deleteAddress(String uid, String addressId) async {
    try {
      // 현재 사용자 정보 조회
      UserModel? user = await getUser(uid);

      if (user == null) {
        print('사용자를 찾을 수 없습니다.');
        return false;
      }

      // 기존 배송지 목록 가져오기
      List<AddressModel> addresses = user.addresses;

      // 삭제할 배송지가 있는지 확인
      int index = addresses.indexWhere((addr) => addr.id == addressId);

      if (index == -1) {
        print('삭제할 배송지를 찾을 수 없습니다.');
        return false;
      }

      // 기본 배송지 여부 확인
      bool wasDefault = addresses[index].isDefault;

      // 배송지 삭제
      addresses.removeAt(index);

      // 삭제한 배송지가 기본 배송지였으면 첫 번째 배송지를 기본 배송지로 설정 (있을 경우)
      if (wasDefault && addresses.isNotEmpty) {
        addresses[0] = addresses[0].copyWith(isDefault: true);
      }

      // Firestore 업데이트
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('배송지 삭제 중 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 상품 추가
  Future<bool> addFavoriteProduct(String uid, String productId) async {
    try {
      // 현재 사용자 정보 조회
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        print('사용자를 찾을 수 없습니다.');
        return false;
      }

      // 현재 즐겨찾기 목록 가져오기
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> favorites = data['favoriteProducts'] ?? [];

      // 이미 즐겨찾기에 없는 경우에만 추가
      if (!favorites.contains(productId)) {
        favorites.add(productId);

        // Firestore 업데이트
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({
          'favoriteProducts': favorites,
        });
      }

      return true;
    } catch (e) {
      print('즐겨찾기 상품 추가 중 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 상품 제거
  Future<bool> removeFavoriteProduct(String uid, String productId) async {
    try {
      // 현재 사용자 정보 조회
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        print('사용자를 찾을 수 없습니다.');
        return false;
      }

      // 현재 즐겨찾기 목록 가져오기
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> favorites = data['favoriteProducts'] ?? [];

      // 즐겨찾기 목록에서 제거
      favorites.remove(productId);

      // Firestore 업데이트
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'favoriteProducts': favorites,
      });

      return true;
    } catch (e) {
      print('즐겨찾기 상품 제거 중 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 상품 목록 조회
  Future<List<String>> getFavoriteProducts(String uid) async {
    try {
      // 현재 사용자 정보 조회
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        print('사용자를 찾을 수 없습니다.');
        return [];
      }

      // 즐겨찾기 목록 가져오기
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> favorites = data['favoriteProducts'] ?? [];

      return favorites.cast<String>();
    } catch (e) {
      print('즐겨찾기 상품 목록 조회 중 오류: $e');
      return [];
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      // Firebase 로그아웃
      await _auth.signOut();

      // 로컬 사용자 데이터 삭제
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);
    } catch (e) {
      print('로그아웃 중 오류: $e');
    }
  }
}
