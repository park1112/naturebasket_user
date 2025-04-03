import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/auth_controller.dart';
import 'package:flutter_login_template/controllers/cart_controller.dart';
import 'package:flutter_login_template/models/address_model.dart' as address;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/order_model.dart';
import 'cart_service.dart';
import '../models/cart_item_model.dart';

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

      // 현재 시간을 직접 설정 (FieldValue.serverTimestamp() 대신)
      final now = DateTime.now();

      // 아이템 리스트를 맵으로 변환 (serverTimestamp를 사용하지 않게)
      final List<Map<String, dynamic>> itemsData = items.map((item) {
        final Map<String, dynamic> itemMap = item.toMap();
        // Firestore에 저장할 수 없는 DateTime 객체를 Timestamp로 변환
        if (itemMap.containsKey('addedAt') && itemMap['addedAt'] is DateTime) {
          itemMap['addedAt'] =
              Timestamp.fromDate(itemMap['addedAt'] as DateTime);
        }
        return itemMap;
      }).toList();

      // 상태 업데이트에서도 현재 시간 직접 설정
      final statusUpdate = {
        'status': OrderStatus.pending.toString().split('.').last,
        'date': Timestamp.fromDate(now), // DateTime 대신 Timestamp 사용
        'message': '주문이 접수되었습니다.',
      };

      // 주문 데이터 맵 직접 생성
      Map<String, dynamic> orderData = {
        'userId': userId,
        'items': itemsData,
        'orderDate': Timestamp.fromDate(now), // DateTime 대신 Timestamp 사용
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'tax': tax,
        'total': subtotal + shippingFee + tax,
        'status': OrderStatus.pending.toString().split('.').last,
        'paymentMethod': paymentMethod,
        'isPaid': false,
        'deliveryInfo': deliveryInfo.toMap(),
        'notes': notes,
        'statusUpdates': [statusUpdate],
      };

      // Firestore에 주문 저장
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .set(orderData);

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
          .get();

      List<OrderModel> orders = [];
      for (var doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc);
          orders.add(order);
        } catch (e) {
          print('주문 데이터 변환 오류: $e');
          // 오류가 발생한 주문은 건너뜀
        }
      }

      return orders;
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

      // 현재 시간을 Timestamp로 직접 설정
      final now = Timestamp.fromDate(DateTime.now());

      // 상태 업데이트 맵 생성
      Map<String, dynamic> statusUpdate = {
        'status': status.toString().split('.').last,
        'date': now,
        'message': message ?? '주문 상태가 업데이트 되었습니다.',
      };

      // 기존 상태 업데이트 목록 가져오기
      Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> updatesData = data['statusUpdates'] ?? [];

      // 새로운 상태 업데이트 추가
      updatesData.add(statusUpdate);

      // 주문 정보 업데이트
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': status.toString().split('.').last,
        'statusUpdates': updatesData,
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

  Future<void> placeOrder({
    required BuildContext context,
    required AuthController authController,
    required CartController cartController,
    required List<CartItemModel> cartItems,
    required address.AddressModel? selectedAddress,
    required String requestText,
    required String paymentMethod,
    required Function(bool isLoading) setLoadingState,
    required Function(String? orderId) onComplete,
  }) async {
    if (selectedAddress == null || selectedAddress.address.isEmpty) {
      Get.snackbar(
        '알림',
        '배송지를 선택해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setLoadingState(true);

    try {
      // Save the selected address if it's new
      if (selectedAddress.id.isEmpty) {
        // Add address saving logic here if needed
      }

      // Create order in Firebase
      final userId = authController.firebaseUser.value!.uid;
      final orderId = await createOrderInFirebase(
        userId: userId,
        cartItems: cartItems,
        addressInfo: selectedAddress,
        deliveryRequest: requestText,
        paymentMethod: paymentMethod,
      );

      if (orderId == null) {
        throw Exception('주문 생성에 실패했습니다.');
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update payment status
      await updateOrderPaymentStatus(
        orderId,
        true,
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Complete the order process
      onComplete(orderId);
    } catch (e) {
      print('주문 처리 중 오류 발생: $e');
      Get.snackbar(
        '오류',
        '주문 처리 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      setLoadingState(false);
    }
  }

  // Simplified order creation function
  Future<String?> createOrderInFirebase({
    required String userId,
    required List<CartItemModel> cartItems,
    required address.AddressModel addressInfo,
    required String deliveryRequest,
    required String paymentMethod,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CartService cartService = CartService();

      // Generate order ID
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get current timestamp (avoid serverTimestamp in arrays)
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      // Calculate totals
      final subtotal =
          cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      const shippingFee = 0.0; // Free shipping
      const tax = 0.0; // No tax
      final total = subtotal + shippingFee + tax;

      // Create delivery info
      final deliveryInfo = {
        'name': addressInfo.recipient,
        'phoneNumber': addressInfo.contact,
        'address': addressInfo.address,
        'addressDetail': addressInfo.detailAddress,
        'zipCode': '00000', // Default value
        'deliveryNotes': addressInfo.deliveryMessage,
        'request': deliveryRequest,
      };

      // Create status updates without timestamp logic, just plain data
      final initialStatus = {
        'status': 'pending',
        'date': timestamp,
        'message': '주문이 접수되었습니다.',
      };

      // Create items list without timestamp references
      final itemsData = cartItems
          .map((item) => {
                'id': item.id,
                'productId': item.productId,
                'productName': item.productName,
                'productImage': item.productImage,
                'price': item.price,
                'quantity': item.quantity,
                'totalPrice': item.totalPrice,
                // Don't include serverTimestamp or complex objects
              })
          .toList();

      // Create the order document
      await firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .set({
        'id': orderId,
        'userId': userId,
        'items': itemsData, // Plain maps, no serverTimestamp
        'orderDate': timestamp,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'tax': tax,
        'total': total,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'isPaid': false,
        'deliveryInfo': deliveryInfo,
        'statusUpdates': [initialStatus], // Array with plain objects
        'createdAt': timestamp,
      });

      // Clear cart after successful order
      await cartService.clearCart(userId);

      return orderId;
    } catch (e) {
      print('주문 생성 중 오류: $e');
      return null;
    }
  }

// Update payment status without complex models
  Future<bool> updateOrderPaymentStatus(String orderId, bool isPaid,
      {String? transactionId}) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Simple update data
      Map<String, dynamic> updateData = {
        'isPaid': isPaid,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      // Add status update for payment
      if (isPaid) {
        // Get the existing document
        final docRef =
            firestore.collection(AppConstants.ordersCollection).doc(orderId);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          final List<dynamic> existingUpdates = data['statusUpdates'] ?? [];

          // Add new status update
          existingUpdates.add({
            'status': 'confirmed',
            'date': Timestamp.fromDate(now),
            'message': '결제가 완료되었습니다.',
          });

          // Update the document with new status and updates
          await docRef.update({
            'status': 'confirmed',
            'statusUpdates': existingUpdates,
            ...updateData,
          });
        }
      } else {
        // Just update payment status
        await firestore
            .collection(AppConstants.ordersCollection)
            .doc(orderId)
            .update(updateData);
      }

      return true;
    } catch (e) {
      print('주문 결제 상태 업데이트 중 오류: $e');
      return false;
    }
  }
}
