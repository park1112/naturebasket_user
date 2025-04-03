import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/order_model.dart';
import 'cart_service.dart';
import 'package:flutter_login_template/models/cart_item_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CartService _cartService = CartService();
  final uuid = Uuid();

  // 주문 생성
  Future<String?> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double subtotal,
    required double shippingFee,
    required double tax,
    required DeliveryInfo deliveryInfo,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      // 주문 ID 생성
      String orderId = uuid.v4();

      // 주문 데이터 생성 (주문 날짜를 orderedAt 으로 통일)
      OrderModel order = OrderModel(
        id: orderId,
        userId: userId,
        items: items,
        orderDate: DateTime.now(), // 변경된 부분
        subtotal: subtotal,
        shippingFee: shippingFee,
        tax: tax,
        total: subtotal + shippingFee + tax,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        isPaid: false,
        deliveryInfo: deliveryInfo,
        notes: notes,
        statusUpdates: [
          StatusUpdate(
            status: OrderStatus.pending,
            date: DateTime.now(),
            message: '주문이 접수되었습니다.',
          ),
        ],
      );

      // Firestore에 주문 저장
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .set(order.toMap());

      // 주문 완료 후 카트 비우기
      await _cartService.clearCart(userId);

      return orderId;
    } catch (e) {
      print('주문 생성 중 오류: $e');
      return null;
    }
  }

  // 사용자 주문 목록 조회
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderedAt', descending: true) // 변경된 부분
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('사용자 주문 목록 조회 중 오류: $e');
      return [];
    }
  }

  // 주문 상세 조회
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('주문 상세 조회 중 오류: $e');
      return null;
    }
  }

  // 주문 상태 업데이트
  Future<bool> updateOrderStatus(String orderId, OrderStatus status,
      {String? message}) async {
    try {
      // 현재 주문 정보 가져오기
      DocumentSnapshot orderDoc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        print('주문을 찾을 수 없습니다.');
        return false;
      }

      // 상태 업데이트 기록 추가
      StatusUpdate statusUpdate = StatusUpdate(
        status: status,
        date: DateTime.now(),
        message: message ?? '주문 상태가 업데이트 되었습니다.',
      );

      // 기존 상태 업데이트 목록 가져오기
      Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> updatesData = data['statusUpdates'] ?? [];
      List<StatusUpdate> updates =
          updatesData.map((update) => StatusUpdate.fromMap(update)).toList();

      // 새로운 상태 업데이트 추가
      updates.add(statusUpdate);

      // 주문 정보 업데이트
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': status.toString().split('.').last,
        'statusUpdates': updates.map((update) => update.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('주문 상태 업데이트 중 오류: $e');
      return false;
    }
  }

  // 주문 결제 상태 업데이트
  Future<bool> updatePaymentStatus(String orderId, bool isPaid,
      {String? transactionId}) async {
    try {
      Map<String, dynamic> updateData = {
        'isPaid': isPaid,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);

      // 결제 완료 시 상태 업데이트
      if (isPaid) {
        await updateOrderStatus(orderId, OrderStatus.confirmed,
            message: '결제가 완료되었습니다.');
      }

      return true;
    } catch (e) {
      print('주문 결제 상태 업데이트 중 오류: $e');
      return false;
    }
  }

  // 주문 취소
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await updateOrderStatus(orderId, OrderStatus.cancelled,
          message: reason ?? '주문이 취소되었습니다.');
      return true;
    } catch (e) {
      print('주문 취소 중 오류: $e');
      return false;
    }
  }

  // 결제 금액 계산 (세금, 배송비 등 포함)
  Future<Map<String, double>> calculateOrderTotal(
      List<CartItemModel> items, String deliveryOption) async {
    try {
      double subtotal = 0;
      for (var item in items) {
        subtotal += item.totalPrice;
      }

      double shippingFee = 0;
      final deliveryOptions = AppConstants.deliveryOptions;
      for (var option in deliveryOptions) {
        if (option['id'] == deliveryOption) {
          shippingFee = option['price'].toDouble();
          break;
        }
      }

      double tax = subtotal * 0.1;
      double total = subtotal + shippingFee + tax;

      return {
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'tax': tax,
        'total': total,
      };
    } catch (e) {
      print('주문 금액 계산 중 오류: $e');
      return {
        'subtotal': 0,
        'shippingFee': 0,
        'tax': 0,
        'total': 0,
      };
    }
  }

  Future<OrderModel?> getOrderDetails(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      print('주문 상세 조회 중 오류: $e');
      return null;
    }
  }
}
