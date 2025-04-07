// lib/controllers/cart_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../controllers/auth_controller.dart';
import '../config/constants.dart';

/// 개별 카트 아이템의 상태를 관리하는 컨트롤러
class CartItemState {
  // 아이템 데이터
  final CartItemModel item;
  // 선택 상태
  final RxBool isSelected = true.obs;
  // 수량
  final RxInt quantity;
  // 로딩 상태
  final RxBool isUpdating = false.obs;

  CartItemState(this.item) : quantity = RxInt(item.quantity);

  // 아이템 가격 계산 (선택된 경우만 계산)
  double get totalPrice => isSelected.value ? item.price * quantity.value : 0.0;

  // 아이템의 최신 상태를 반영한 CartItemModel 반환
  CartItemModel get updatedItem => item.copyWith(quantity: quantity.value);
}

class CartController extends GetxController {
  // 서비스 인스턴스: CartService는 직접 생성, AuthController는 Get.find로 주입
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();

  // 카트 아이템 상태 관리 (각 아이템의 독립적인 상태 관리)
  final RxMap<String, CartItemState> itemStates = <String, CartItemState>{}.obs;

  // 전체 로딩 상태
  final RxBool isLoading = false.obs;

  // 자동으로 계산되는 총 금액 (각 아이템의 totalPrice의 합)
  double get totalPrice {
    return itemStates.values.fold(0.0, (sum, state) => sum + state.totalPrice);
  }

  // 전체 아이템 수
  int get cartItemCount => itemStates.length;

  // 선택된 아이템 수
  int get selectedItemCount =>
      itemStates.values.where((state) => state.isSelected.value).length;

  // 모두 선택 여부
  bool get isAllSelected =>
      itemStates.isNotEmpty &&
      itemStates.values.every((state) => state.isSelected.value);

  // 선택된 배송 옵션 (상수값 사용)
  String get selectedDeliveryOption => AppConstants.deliveryOptions.isNotEmpty
      ? AppConstants.deliveryOptions[0]['id'].toString()
      : '';

  // 카트 아이템 리스트 (원본 데이터)
  List<CartItemModel> get cartItems =>
      itemStates.values.map((state) => state.item).toList();

  // 선택된 카트 아이템 목록
  List<CartItemModel> get selectedCartItems {
    return itemStates.values
        .where((state) => state.isSelected.value)
        .map((state) => state.updatedItem)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  // 장바구니 로드
  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      if (_authController.firebaseUser.value != null) {
        final items = await _cartService.getUserCart(
          _authController.firebaseUser.value!.uid,
        );

        // 기존 상태 초기화 후 새로운 상태 생성
        itemStates.clear();
        for (var item in items) {
          itemStates[item.id] = CartItemState(item);
        }

        update(); // UI 업데이트 알림
      }
    } catch (e) {
      print('Error loading cart: $e');
      Get.snackbar('오류', '장바구니를 불러오는 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니에 상품 추가
  Future<void> addToCart(
      ProductModel product, int quantity, String? option) async {
    try {
      isLoading.value = true;
      if (_authController.firebaseUser.value == null) {
        Get.snackbar('알림', '로그인이 필요합니다.');
        return;
      }

      await _cartService.addToCart(
        _authController.firebaseUser.value!.uid,
        product,
        quantity,
        null,
      );

      await loadCart(); // 장바구니 새로고침
      Get.snackbar('알림', '장바구니에 상품이 담겼습니다.');
    } catch (e) {
      print('Error adding to cart: $e');
      Get.snackbar('오류', '장바구니 담기에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 장바구니 아이템 수량 변경 (낙관적 업데이트 방식)
  Future<void> updateItemQuantity(CartItemModel item, int quantity) async {
    if (_authController.firebaseUser.value == null) return;
    if (quantity < 1) quantity = 1; // 최소 수량 보장

    // 이미 같은 수량이면 아무 작업도 하지 않음
    if (item.quantity == quantity) return;

    // 먼저 로컬 상태 업데이트 (낙관적 업데이트)
    final oldQuantity = item.quantity;
    final index = cartItems.indexWhere((i) => i.id == item.id);

    if (index != -1) {
      // 로컬 상태 즉시 업데이트
      final updatedItem = item.copyWith(quantity: quantity);
      cartItems[index] = updatedItem;

      // 총 금액 즉시 업데이트
      updateTotalPrice();
      update(); // UI 새로고침
    }

    // 백그라운드에서 서버 업데이트 시도
    try {
      bool success = await _cartService.updateCartItemQuantity(
        _authController.firebaseUser.value!.uid,
        item.id,
        quantity,
      );

      // 서버 업데이트 실패 시 원래 상태로 되돌림
      if (!success && index != -1) {
        cartItems[index] = item.copyWith(quantity: oldQuantity);
        updateTotalPrice();
        update();

        Get.snackbar(
          '오류',
          '수량 변경에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      // 오류 발생 시 원래 상태로 되돌림
      if (index != -1) {
        cartItems[index] = item.copyWith(quantity: oldQuantity);
        updateTotalPrice();
        update();
      }

      print('Error updating cart item quantity: $e');
      Get.snackbar(
        '오류',
        '수량 변경 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ID로 장바구니 아이템 수량 변경
  Future<void> updateItemQuantityById(String itemId, int quantity) async {
    if (_authController.firebaseUser.value == null) return;
    if (quantity < 1) quantity = 1; // 최소 수량 보장

    final itemState = itemStates[itemId];
    if (itemState == null) return;

    final item = itemState.item;

    // 이미 같은 수량이면 아무 작업도 하지 않음
    if (item.quantity == quantity) return;

    // 먼저 로컬 상태 업데이트 (낙관적 업데이트)
    final oldQuantity = item.quantity;

    // 로컬 상태 즉시 업데이트
    itemState.quantity.value = quantity;

    // 총 금액 즉시 업데이트
    update(); // UI 새로고침

    // 백그라운드에서 서버 업데이트 시도
    try {
      bool success = await _cartService.updateCartItemQuantity(
        _authController.firebaseUser.value!.uid,
        itemId,
        quantity,
      );

      // 서버 업데이트 실패 시 원래 상태로 되돌림
      if (!success) {
        itemState.quantity.value = oldQuantity;
        update();

        Get.snackbar(
          '오류',
          '수량 변경에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      // 오류 발생 시 원래 상태로 되돌림
      itemState.quantity.value = oldQuantity;
      update();

      print('Error updating cart item quantity: $e');
      Get.snackbar(
        '오류',
        '수량 변경 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // 장바구니에서 아이템 삭제
  Future<bool> removeItem(String itemId) async {
    if (_authController.firebaseUser.value == null) return false;

    final state = itemStates[itemId];
    if (state == null) return false;

    try {
      bool success = await _cartService.removeCartItem(
        _authController.firebaseUser.value!.uid,
        itemId,
      );

      if (success) {
        // 성공하면 로컬 상태에서 제거
        itemStates.remove(itemId);
        update(); // UI 업데이트 알림
      }

      return success;
    } catch (e) {
      print('Error removing cart item: $e');
      Get.snackbar(
        '오류',
        '상품 삭제 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
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
        itemStates.clear();
        update(); // UI 업데이트 알림
      }

      return success;
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

  // 항목 선택/해제 토글
  void toggleItemSelection(String itemId) {
    final state = itemStates[itemId];
    if (state != null) {
      state.isSelected.toggle();
      update(); // 총액 업데이트를 위해 필요
    }
  }

  // 전체 선택/해제 토글
  void toggleAllSelection() {
    bool newValue = !isAllSelected;

    for (var state in itemStates.values) {
      state.isSelected.value = newValue;
    }

    update(); // 총액 업데이트를 위해 필요
  }

  // 전체 선택된 상품 삭제
  Future<void> removeSelectedItems() async {
    // 선택된 아이템 ID 목록
    final selectedIds = itemStates.values
        .where((state) => state.isSelected.value)
        .map((state) => state.item.id)
        .toList();

    for (String id in selectedIds) {
      await removeItem(id);
    }
  }

  // 선택된 항목만 남기기
  Future<void> keepSelectedItemsOnly() async {
    // 선택되지 않은 아이템 ID 목록
    final unselectedIds = itemStates.values
        .where((state) => !state.isSelected.value)
        .map((state) => state.item.id)
        .toList();

    for (String id in unselectedIds) {
      await removeItem(id);
    }
  }

  // 총 금액 업데이트
  void updateTotalPrice() {
    // totalPrice는 getter이므로 자동으로 계산됨
    update(); // UI 업데이트를 위해 호출
  }
}
