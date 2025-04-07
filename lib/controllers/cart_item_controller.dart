import 'package:get/get.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../controllers/auth_controller.dart';

/// 각 카트 아이템을 독립적으로 관리하는 컨트롤러
class CartItemController extends GetxController {
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();

  // 상품 데이터
  final Rx<CartItemModel> item;

  // 선택 상태
  final RxBool isSelected = true.obs;

  // 금액 계산용 콜백
  final Function() onPriceUpdated;

  CartItemController({
    required CartItemModel initialItem,
    required bool initialSelected,
    required this.onPriceUpdated,
  }) : item = Rx<CartItemModel>(initialItem) {
    isSelected.value = initialSelected;
  }

  // 수량 변경
  Future<void> updateQuantity(int newQuantity) async {
    if (newQuantity != item.value.quantity && newQuantity > 0) {
      // 이전 값 저장
      final previousItem = item.value;

      // UI 즉시 업데이트 (낙관적 업데이트)
      item.value = item.value.copyWith(quantity: newQuantity);

      try {
        // 서버에 수량 변경 요청
        await _cartService.updateCartItemQuantity(
            _authController.firebaseUser.value!.uid,
            item.value.id,
            newQuantity);

        // 가격 업데이트 콜백 호출
        onPriceUpdated();
      } catch (e) {
        // 오류 발생 시 이전 상태로 복원
        item.value = previousItem;
        Get.snackbar('오류', '수량 변경에 실패했습니다');
      }
    }
  }

  // 선택 상태 토글
  void toggleSelection(bool value) {
    if (isSelected.value != value) {
      isSelected.value = value;
      onPriceUpdated(); // 선택 상태 변경 시 가격 업데이트
    }
  }

  // 아이템 삭제
  Future<void> removeItem() async {
    try {
      await _cartService.removeFromCart(item.value.id, item.value.productId);
      // 삭제 후 처리는 상위 컨트롤러에서 처리
    } catch (e) {
      Get.snackbar('오류', '상품 삭제에 실패했습니다');
    }
  }
}
