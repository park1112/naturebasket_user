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
  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  RxBool isLoading = false.obs;
  RxSet<String> selectedItems = <String>{}.obs;

  // 선택된 카트 아이템 목록 (선택된 항목만 필터링)
  List<CartItemModel> get selectedCartItems {
    return cartItems.where((item) => selectedItems.contains(item.id)).toList();
  }

  // 선택된 항목들의 총 금액 계산
  double get totalPrice {
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
    // 로그인 여부 확인
    if (_authController.firebaseUser.value == null) {
      cartItems.clear();
      selectedItems.clear();
      return;
    }

    isLoading.value = true;
    try {
      final userId = _authController.firebaseUser.value!.uid;
      final items = await _cartService.getUserCart(userId);

      if (items.isNotEmpty) {
        cartItems.value = items;
        // 기본적으로 모든 항목 선택
        selectedItems.value = items.map((item) => item.id).toSet();
      } else {
        cartItems.clear();
        selectedItems.clear();
      }
    } catch (e) {
      print('Error loading cart: $e');
      cartItems.clear();
      selectedItems.clear();
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
    // 로그인 여부 확인
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
        await loadCart(); // 추가 후 다시 로드
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
}
