// lib/services/wishlist_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 찜 목록에 상품 추가
  Future<bool> addToWishlist(String userId, ProductModel product) async {
    try {
      // 이미 찜 목록에 있는지 확인
      QuerySnapshot existing = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .where('productId', isEqualTo: product.id)
          .get();

      if (existing.docs.isNotEmpty) {
        // 이미 찜한 상품이면 스킵
        return true;
      }

      // 찜 목록에 추가
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .add({
        'productId': product.id,
        'productName': product.name,
        'productImage':
            product.imageUrls.isNotEmpty ? product.imageUrls[0] : null,
        'price': product.price,
        'discountPrice': product.discountPrice,
        'addedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        '찜 목록 추가',
        '${product.name}이(가) 찜 목록에 추가되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      print('Error adding to wishlist: $e');

      Get.snackbar(
        '오류',
        '찜 목록에 추가하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  // 찜 목록에서 상품 제거
  Future<bool> removeFromWishlist(String userId, String wishlistItemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(wishlistItemId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // 사용자의 찜 목록 가져오기
  Future<List<DocumentSnapshot>> getUserWishlist(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error getting user wishlist: $e');
      return [];
    }
  }

  // 상품이 찜 목록에 있는지 확인
  Future<bool> isProductInWishlist(String userId, String productId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }
}
