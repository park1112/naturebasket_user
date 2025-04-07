import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../config/constants.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';
import 'package:flutter_login_template/models/cart_item_model.dart';

class OrderController extends GetxController {
  final OrderService _orderService = OrderService();
  final AuthController _authController = Get.find<AuthController>();
  final CartController _cartController = Get.find<CartController>();

  // 주문 목록 및 선택된 주문 상태
  RxList<OrderModel> orders = <OrderModel>[].obs;
  Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);

  // 로딩, 처리, 결제 상태
  RxBool isLoading = false.obs;
  RxBool isProcessing = false.obs;
  RxBool isPaid = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  // 주문 목록 로드
  Future<void> loadOrders() async {
    if (!_authController.isLoggedIn.value) return;
    isLoading.value = true;
    try {
      String uid = _authController.firebaseUser.value!.uid;
      orders.value = await _orderService.getUserOrders(uid);
    } catch (e) {
      print('주문 목록 로드 중 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 주문 상세 조회
  Future<void> loadOrderDetails(String orderId) async {
    isLoading.value = true;
    try {
      OrderModel? order = await _orderService.getOrderById(orderId);
      if (order != null) {
        selectedOrder.value = order;
        isPaid.value = order.isPaid;
      }
    } catch (e) {
      print('주문 상세 조회 중 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 새 주문 생성
  Future<String?> createOrder(DeliveryInfo deliveryInfo,
      {String? paymentMethod, String? notes}) async {
    if (!_authController.isLoggedIn.value) {
      Get.snackbar('로그인 필요', '주문하려면 로그인이 필요합니다.');
      return null;
    }
    isProcessing.value = true;
    try {
      String uid = _authController.firebaseUser.value!.uid;
      List<CartItemModel> items = _cartController.cartItems;
      if (items.isEmpty) {
        Get.snackbar('오류', '장바구니가 비어 있습니다.');
        return null;
      }

      // 주문 금액 계산
      Map<String, double> amounts = await _orderService.calculateOrderTotal(
          items, _cartController.selectedDeliveryOption);

      // 주문 생성
      String? orderId = await _orderService.createOrder(
        userId: uid,
        items: items,
        subtotal: amounts['subtotal'] ?? 0,
        shippingFee: amounts['shippingFee'] ?? 0,
        tax: amounts['tax'] ?? 0,
        deliveryInfo: deliveryInfo,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      if (orderId != null) {
        Get.snackbar('주문 완료', AppConstants.successOrder);
        await loadOrders();
      }
      return orderId;
    } catch (e) {
      print('주문 생성 중 오류: $e');
      Get.snackbar('오류', '주문 처리 중 오류가 발생했습니다.');
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  // 주문 취소
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    isProcessing.value = true;
    try {
      bool success = await _orderService.cancelOrder(orderId, reason: reason);
      if (success) {
        Get.snackbar('주문 취소', '주문이 취소되었습니다.');
        await loadOrders();
        if (selectedOrder.value != null && selectedOrder.value!.id == orderId) {
          await loadOrderDetails(orderId);
        }
      }
      return success;
    } catch (e) {
      print('주문 취소 중 오류: $e');
      Get.snackbar('오류', '주문 취소 중 오류가 발생했습니다.');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // 결제 처리 (예시로 결제 성공 가정)
  Future<bool> processPayment(String orderId, String method) async {
    isProcessing.value = true;
    try {
      bool paymentSuccess = true; // 실제 결제 연동은 추가 구현 필요
      if (paymentSuccess) {
        bool success = await _orderService.updatePaymentStatus(orderId, true,
            transactionId:
                '${method}_${DateTime.now().millisecondsSinceEpoch}');
        if (success) {
          isPaid.value = true;
          await loadOrderDetails(orderId);
        }
        return success;
      } else {
        Get.snackbar('결제 실패', '결제 처리 중 오류가 발생했습니다.');
        return false;
      }
    } catch (e) {
      print('결제 처리 중 오류: $e');
      Get.snackbar('오류', '결제 처리 중 오류가 발생했습니다.');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
}
