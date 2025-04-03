// lib/controllers/cart_controller.dart
import 'package:get/get.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../controllers/auth_controller.dart';
import '../config/constants.dart';

class CartController extends GetxController {
  // 서비스 인스턴스: CartService는 직접 생성, AuthController는 Get.find로 주입
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();

  // Rx 변수들을 즉시 초기화하여 late 변수로 인한 에러 방지
  final cartItems = <CartItemModel>[].obs;
  final isLoading = false.obs;
  final totalPrice = 0.0.obs;
  RxSet<String> selectedItems = <String>{}.obs;

  // 선택된 카트 아이템 목록 (선택된 항목만 필터링)
  List<CartItemModel> get selectedCartItems {
    return cartItems.where((item) => selectedItems.contains(item.id)).toList();
  }

  // 선택된 항목들의 총 금액 계산
  double get totalPriceValue {
    return selectedCartItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  // 전체 장바구니 항목 수
  int get cartItemCount => cartItems.length;

  // 선택된 배송 옵션 (상수값 사용, 상황에 맞게 수정 가능)
  String get selectedDeliveryOption => AppConstants.deliveryOptions.isNotEmpty
      ? AppConstants.deliveryOptions[0]['id'].toString()
      : '';

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  // 장바구니 로드: 현재 로그인된 사용자의 카트 정보를 불러옵니다.
  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      if (_authController.firebaseUser.value != null) {
        final items = await _cartService.getUserCart(
          _authController.firebaseUser.value!.uid,
        );
        cartItems.value = items;
        updateTotalPrice();
      }
    } catch (e) {
      print('Error loading cart: $e');
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

      final cartItem = CartItemModel(
        id: '', // Firebase에서 자동 생성
        productId: product.id,
        productName: product.name,
        productImage:
            product.images.isNotEmpty ? product.images[0] : null, // 첫 번째 이미지 사용
        price: product.sellingPrice,
        quantity: quantity,
        selectedOptions: null,
        addedAt: DateTime.now(),
      );

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
        await loadCart(); // 변경 후 다시 로드
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

  // 장바구니에서 아이템 삭제
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
        await loadCart(); // 삭제 후 다시 로드
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

  // 항목 선택/해제 토글
  void toggleItemSelection(String itemId) {
    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }
  }

  // 전체 선택/해제 토글
  void toggleAllSelection() {
    if (selectedItems.length == cartItems.length) {
      selectedItems.clear();
    } else {
      selectedItems.value = cartItems.map((item) => item.id).toSet();
    }
  }

  void updateTotalPrice() {
    totalPrice.value = cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.firebaseUser.value == null) return;

      final success = await CartService().removeCartItem(
        authController.firebaseUser.value!.uid,
        itemId,
      );

      if (success) {
        cartItems.removeWhere((item) => item.id == itemId);
        updateTotalPrice();
      }
    } catch (e) {
      print('Error removing item from cart: $e');
      Get.snackbar('오류', '상품 삭제에 실패했습니다.');
    }
  }
}
