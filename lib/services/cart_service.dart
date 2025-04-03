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
  Future<List<CartItemModel>> getUserCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      List<CartItemModel> cartItems = [];

      for (var doc in snapshot.docs) {
        // 각 장바구니 아이템에 대해 상품 정보를 조회
        String productId = doc.get('productId');
        DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(productId).get();

        if (productDoc.exists) {
          ProductModel product = ProductModel.fromFirestore(productDoc);

          cartItems.add(CartItemModel(
            id: doc.id,
            productId: productId,
            productName: product.name,
            productImage: product.images.isNotEmpty ? product.images[0] : null,
            price: product.sellingPrice, // 현재 판매가를 사용
            quantity: doc.get('quantity'),
            selectedOptions: doc.get('selectedOptions'),
            addedAt: (doc.get('addedAt') as Timestamp).toDate(),
          ));
        }
      }

      return cartItems;
    } catch (e) {
      print('Error getting user cart: $e');
      return [];
    }
  }

  // 장바구니에 상품 추가
  Future<bool> addToCart(
      String userId, ProductModel product, int quantity, String? option) async {
    try {
      final cartItemData = {
        'productId': product.id, // 상품 ID만 저장
        'quantity': quantity,
        'selectedOptions': option,
        'addedAt': DateTime.now(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .add(cartItemData);
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
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

  Future<void> updateQuantity(
      String userId, String itemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(userId, itemId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(itemId)
            .update({'quantity': quantity});
      }
    } catch (e) {
      print('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }
}
