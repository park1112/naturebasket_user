// lib/controllers/cart_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../controllers/auth_controller.dart';
import '../config/constants.dart';

class CartController extends GetxController {
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();

  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  RxBool isLoading = false.obs;
  RxSet<String> selectedItems = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  // 장바구니 로드
  Future<void> loadCart() async {
    if (_authController.firebaseUser.value == null) return;

    isLoading.value = true;

    try {
      final items = await _cartService.getUserCart(
        _authController.firebaseUser.value!.uid,
      );

      cartItems.value = items;
      // 기본적으로 모든 항목 선택
      selectedItems.value = items.map((item) => item.id).toSet();
    } catch (e) {
      print('Error loading cart: $e');
      Get.snackbar(
        '오류',
        '장바구니를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니에 상품 추가
  Future<bool> addToCart(ProductModel product, int quantity,
      {Map<String, dynamic>? selectedOptions}) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '장바구니에 추가하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    isLoading.value = true;

    try {
      bool success = await _cartService.addToCart(
        _authController.firebaseUser.value!.uid,
        product,
        quantity,
        selectedOptions,
      );

      if (success) {
        await loadCart(); // 장바구니 다시 로드
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding to cart: $e');
      Get.snackbar(
        '오류',
        '장바구니에 추가하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니 아이템 수량 변경
  Future<bool> updateItemQuantity(CartItemModel item, int quantity) async {
    if (_authController.firebaseUser.value == null) return false;
    if (quantity < 1) quantity = 1; // 최소 수량 보장

    isLoading.value = true;

    try {
      bool success = await _cartService.updateCartItemQuantity(
        _authController.firebaseUser.value!.uid,
        item.id,
        quantity,
      );

      if (success) {
        await loadCart(); // 장바구니 다시 로드
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating cart item quantity: $e');
      Get.snackbar(
        '오류',
        '수량 변경 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니 아이템 삭제
  Future<bool> removeItem(CartItemModel item) async {
    if (_authController.firebaseUser.value == null) return false;

    isLoading.value = true;

    try {
      bool success = await _cartService.removeCartItem(
        _authController.firebaseUser.value!.uid,
        item.id,
      );

      if (success) {
        selectedItems.remove(item.id);
        await loadCart(); // 장바구니 다시 로드
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing cart item: $e');
      Get.snackbar(
        '오류',
        '상품 삭제 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니 비우기
  Future<bool> clearCart() async {
    if (_authController.firebaseUser.value == null) return false;

    isLoading.value = true;

    try {
      bool success = await _cartService.clearCart(
        _authController.firebaseUser.value!.uid,
      );

      if (success) {
        cartItems.clear();
        selectedItems.clear();
        return true;
      }
      return false;
    } catch (e) {
      print('Error clearing cart: $e');
      Get.snackbar(
        '오류',
        '장바구니 비우기 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 항목 선택/해제
  void toggleItemSelection(String itemId) {
    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }
  }

  // 전체 선택/해제
  void toggleAllSelection() {
    if (selectedItems.length == cartItems.length) {
      selectedItems.clear();
    } else {
      selectedItems.value = cartItems.map((item) => item.id).toSet();
    }
  }

  // 선택된 항목 계산
  List<CartItemModel> get selectedCartItems {
    return cartItems.where((item) => selectedItems.contains(item.id)).toList();
  }

  // 총 금액 계산
  double get totalPrice {
    return selectedCartItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  // 장바구니 항목 수
  int get cartItemCount => cartItems.length;

  // 선택된 배송 옵션
  String get selectedDeliveryOption =>
      AppConstants.deliveryOptions[0]['id'].toString();
}
