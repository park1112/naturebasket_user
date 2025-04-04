// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_template/models/cart_item_model.dart';
import 'package:flutter/material.dart';

enum OrderStatus {
  pending, // 주문 접수
  confirmed, // 주문 확인
  processing, // 처리 중
  shipping, // 배송 중
  delivered, // 배송 완료
  cancelled, // 주문 취소
  refunded, // 환불 완료
  exchangeRequested, // 교환 요청
  returnRequested, // 반품 요청
  exchangeCompleted, // 교환 완료
  returnCompleted; // 반품 완료

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipping:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
      case OrderStatus.exchangeRequested:
        return Colors.purple;
      case OrderStatus.returnRequested:
        return Colors.indigo;
      case OrderStatus.exchangeCompleted:
        return Colors.teal;
      case OrderStatus.returnCompleted:
        return Colors.blue;
    }
  }
}

class StatusUpdate {
  final String status; // Store status as string representation
  final DateTime date;
  final String? message;

  StatusUpdate({
    required OrderStatus statusEnum,
    required this.date,
    this.message,
  }) : status = statusEnum.toString().split('.').last;

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'date': Timestamp.fromDate(date),
      'message': message,
    };
  }

  factory StatusUpdate.fromMap(Map<String, dynamic> map) {
    return StatusUpdate(
      statusEnum: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      message: map['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'date': date.toIso8601String(),
      'message': message,
    };
  }

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      statusEnum: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      date: DateTime.parse(json['date']),
      message: json['message'],
    );
  }
  OrderStatus get statusEnum {
    return OrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// 수정된 DeliveryInfo 클래스: 배송 시작일, 배송 완료일, 배송 요청사항(request) 필드를 추가
class DeliveryInfo {
  final String name;
  final String phoneNumber;
  final String address;
  final String? addressDetail;
  final String zipCode;
  final String? deliveryOption;
  final String? deliveryNotes;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? request;

  DeliveryInfo({
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.addressDetail,
    required this.zipCode,
    this.deliveryOption,
    this.deliveryNotes,
    this.shippedAt,
    this.deliveredAt,
    this.request,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'addressDetail': addressDetail,
      'zipCode': zipCode,
      'deliveryOption': deliveryOption,
      'deliveryNotes': deliveryNotes,
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'request': request,
    };
  }

  factory DeliveryInfo.fromMap(Map<String, dynamic> map) {
    return DeliveryInfo(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      addressDetail: map['addressDetail'],
      zipCode: map['zipCode'] ?? '',
      deliveryOption: map['deliveryOption'],
      deliveryNotes: map['deliveryNotes'],
      shippedAt: map['shippedAt'] != null
          ? (map['shippedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      request: map['request'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo.fromMap(json);
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final DateTime orderDate;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double total;
  final OrderStatus status;
  final String? paymentMethod;
  final bool isPaid;
  final String? transactionId;
  final DeliveryInfo deliveryInfo;
  final String? notes;
  final List<StatusUpdate>? statusUpdates;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.orderDate,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.total,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.isPaid = false,
    this.transactionId,
    required this.deliveryInfo,
    this.notes,
    this.statusUpdates,
  });

  // 상품 개수
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // 상태 텍스트
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '주문 확인';
      case OrderStatus.processing:
        return '처리 중';
      case OrderStatus.shipping:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
      case OrderStatus.exchangeRequested:
        return '교환 요청';
      case OrderStatus.returnRequested:
        return '반품 요청';
      case OrderStatus.exchangeCompleted:
        return '교환 완료';
      case OrderStatus.returnCompleted:
        return '반품 완료';
      default:
        return '알 수 없음';
    }
  }

  // 문자열에서 OrderStatus enum으로 변환하는 메서드
  static OrderStatus _getOrderStatusFromString(String? statusStr) {
    if (statusStr == null) return OrderStatus.pending;

    try {
      return OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusStr,
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  // Firestore 변환
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 여기서 items가 Map 형태로 들어오면 처리해야 함
    List<CartItemModel> items = [];
    if (data['items'] != null) {
      if (data['items'] is List) {
        items = (data['items'] as List)
            .map((item) => item is Map<String, dynamic>
                ? CartItemModel.fromMap(item)
                : CartItemModel.fromFirestore(item))
            .toList();
      }
    }

    // statusUpdates도 처리
    List<StatusUpdate> statusUpdates = [];
    if (data['statusUpdates'] != null) {
      if (data['statusUpdates'] is List) {
        statusUpdates = (data['statusUpdates'] as List)
            .map((update) =>
                StatusUpdate.fromMap(update as Map<String, dynamic>))
            .toList();
      }
    }

    // deliveryInfo도 안전하게 처리
    DeliveryInfo deliveryInfo;
    if (data['deliveryInfo'] != null &&
        data['deliveryInfo'] is Map<String, dynamic>) {
      deliveryInfo =
          DeliveryInfo.fromMap(data['deliveryInfo'] as Map<String, dynamic>);
    } else {
      // 기본 deliveryInfo 생성
      deliveryInfo = DeliveryInfo(
        name: '',
        phoneNumber: '',
        address: '',
        zipCode: '',
      );
    }

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: items,
      orderDate: data['orderDate'] is Timestamp
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.now(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: _getOrderStatusFromString(data['status']),
      paymentMethod: data['paymentMethod'],
      isPaid: data['isPaid'] ?? false,
      transactionId: data['transactionId'],
      deliveryInfo: deliveryInfo,
      notes: data['notes'],
      statusUpdates: statusUpdates.isEmpty ? null : statusUpdates,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'orderDate': orderDate.toIso8601String(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'transactionId': transactionId,
      'deliveryInfo': deliveryInfo.toJson(),
      'notes': notes,
      'statusUpdates': statusUpdates?.map((update) => update.toJson()).toList(),
    };
  }

  // JSON 역직렬화
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item))
          .toList(),
      orderDate: DateTime.parse(json['orderDate']),
      subtotal: json['subtotal'].toDouble(),
      shippingFee: json['shippingFee'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'],
      transactionId: json['transactionId'],
      deliveryInfo: DeliveryInfo.fromJson(json['deliveryInfo']),
      notes: json['notes'],
      statusUpdates: json['statusUpdates'] != null
          ? (json['statusUpdates'] as List)
              .map((update) => StatusUpdate.fromJson(update))
              .toList()
          : null,
    );
  }

  // 주문 복사 및 업데이트
  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    DateTime? orderDate,
    double? subtotal,
    double? shippingFee,
    double? tax,
    double? total,
    OrderStatus? status,
    String? paymentMethod,
    bool? isPaid,
    String? transactionId,
    DeliveryInfo? deliveryInfo,
    String? notes,
    List<StatusUpdate>? statusUpdates,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      orderDate: orderDate ?? this.orderDate,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      transactionId: transactionId ?? this.transactionId,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      notes: notes ?? this.notes,
      statusUpdates: statusUpdates ?? this.statusUpdates,
    );
  }
}
