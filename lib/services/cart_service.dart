// lib/services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 사용자 장바구니 가져오기
// 예시: cart_service.dart 또는 cart_controller.dart에서 수정
  Future<List<CartItemModel>> getUserCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      // 오류 방지를 위한 안전한 변환
      return snapshot.docs
          .where(
              (doc) => doc.exists && doc.data() != null) // 존재하고 데이터가 있는 문서만 필터링
          .map((doc) => CartItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user cart: $e');
      return [];
    }
  }

  // 장바구니에 상품 추가
  Future<bool> addToCart(String userId, ProductModel product, int quantity,
      Map<String, dynamic>? selectedOptions) async {
    try {
      // 이미 장바구니에 있는지 확인
      QuerySnapshot existing = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .where('productId', isEqualTo: product.id)
          .get();

      if (existing.docs.isNotEmpty) {
        // 이미 존재하는 상품이면 수량만 업데이트
        CartItemModel existingItem =
            CartItemModel.fromFirestore(existing.docs.first);
        int newQuantity = existingItem.quantity + quantity;

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(existingItem.id)
            .update({'quantity': newQuantity});
      } else {
        // 새 상품이면 추가
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .add({
          'productId': product.id,
          'productName': product.name,
          'productImage':
              product.imageUrls.isNotEmpty ? product.imageUrls[0] : null,
          'price': product.sellingPrice,
          'quantity': quantity,
          'selectedOptions': selectedOptions,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // 성공 메시지 표시
      Get.snackbar(
        '장바구니 추가',
        '${product.name}이(가) 장바구니에 추가되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      print('Error adding to cart: $e');

      // 오류 메시지 표시
      Get.snackbar(
        '오류',
        '장바구니에 추가하는 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  // 장바구니 아이템 수량 업데이트
  Future<bool> updateCartItemQuantity(
      String userId, String cartItemId, int quantity) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .update({'quantity': quantity});

      return true;
    } catch (e) {
      print('Error updating cart item quantity: $e');
      return false;
    }
  }

  // 장바구니 아이템 삭제
  Future<bool> removeCartItem(String userId, String cartItemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing cart item: $e');
      return false;
    }
  }

  // 장바구니 비우기
  Future<bool> clearCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  Future<void> syncCart(String userId) async {
    try {
      // 로컬 카트 데이터를 서버에 동기화
      final localCart = await getLocalCart();
      if (localCart.isNotEmpty) {
        await _firestore.collection('carts').doc(userId).set({
          'items': localCart.map((item) => item.toJson()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('카트 동기화 중 오류: $e');
    }
  }

  Future<List<CartItemModel>> getLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('local_cart');
      if (cartJson != null) {
        final List<dynamic> cartData = json.decode(cartJson);
        return cartData.map((item) => CartItemModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('로컬 카트 로드 중 오류: $e');
      return [];
    }
  }
}
