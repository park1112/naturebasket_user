// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/cart_item_model.dart';

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

  String get text {
    switch (this) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '결제 완료';
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
    }
  }

  static OrderStatus fromString(String status) {
    try {
      return OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }
}

class StatusUpdate {
  final String status; // Store status as string representation
  final DateTime date;
  final String? message;
  final List<String>? requestedItems; // 교환/반품 요청 상품 ID 목록

  StatusUpdate({
    required this.status,
    required this.date,
    this.message,
    this.requestedItems,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'status': status,
      'date': Timestamp.fromDate(date),
      'message': message,
    };

    if (requestedItems != null && requestedItems!.isNotEmpty) {
      map['requestedItems'] = requestedItems;
    }

    return map;
  }

  factory StatusUpdate.fromMap(Map<String, dynamic> map) {
    List<String>? requestedItems;
    if (map['requestedItems'] != null) {
      requestedItems = List<String>.from(map['requestedItems']);
    }

    return StatusUpdate(
      status: map['status'] ?? 'pending',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      message: map['message'],
      requestedItems: requestedItems,
    );
  }

  OrderStatus get statusEnum => OrderStatus.fromString(status);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'status': status,
      'date': date.toIso8601String(),
      'message': message,
    };

    if (requestedItems != null && requestedItems!.isNotEmpty) {
      json['requestedItems'] = List<String>.from(requestedItems!);
    }

    return json;
  }

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    List<String>? requestedItems;
    if (json['requestedItems'] != null) {
      requestedItems = List<String>.from(json['requestedItems']);
    }

    return StatusUpdate(
      status: json['status'] ?? 'pending',
      date: DateTime.parse(json['date']),
      message: json['message'],
      requestedItems: requestedItems,
    );
  }
}

/// 배송 정보 클래스
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
  final String? trackingNumber;
  final String? carrierName;

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
    this.trackingNumber,
    this.carrierName,
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
      'trackingNumber': trackingNumber,
      'carrierName': carrierName,
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
          ? (map['shippedAt'] is Timestamp)
              ? (map['shippedAt'] as Timestamp).toDate()
              : null
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] is Timestamp)
              ? (map['deliveredAt'] as Timestamp).toDate()
              : null
          : null,
      request: map['request'],
      trackingNumber: map['trackingNumber'],
      carrierName: map['carrierName'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo.fromMap(json);
  }

  DeliveryInfo copyWith({
    String? name,
    String? phoneNumber,
    String? address,
    String? addressDetail,
    String? zipCode,
    String? deliveryOption,
    String? deliveryNotes,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? request,
    String? trackingNumber,
    String? carrierName,
  }) {
    return DeliveryInfo(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      zipCode: zipCode ?? this.zipCode,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      request: request ?? this.request,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      carrierName: carrierName ?? this.carrierName,
    );
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
  final List<String>? exchangeReturnRequestIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.exchangeReturnRequestIds,
    this.createdAt,
    this.updatedAt,
  });

  // 상품 개수
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // 상태 텍스트
  String get statusText => status.text;

  // 교환/반품 요청 여부 확인
  bool get hasExchangeReturnRequest {
    if (exchangeReturnRequestIds != null &&
        exchangeReturnRequestIds!.isNotEmpty) {
      return true;
    }

    if (statusUpdates == null || statusUpdates!.isEmpty) {
      return false;
    }

    return statusUpdates!.any((update) =>
        update.status == 'exchangeRequested' ||
        update.status == 'returnRequested');
  }

  // 배송 완료 날짜
  DateTime? get deliveryDate => deliveryInfo.deliveredAt;

  // Firestore 변환
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // items 처리
    List<CartItemModel> items = [];
    if (data['items'] != null) {
      if (data['items'] is List) {
        items = (data['items'] as List)
            .map((item) =>
                CartItemModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    // statusUpdates 처리
    List<StatusUpdate> statusUpdates = [];
    if (data['statusUpdates'] != null) {
      if (data['statusUpdates'] is List) {
        statusUpdates = (data['statusUpdates'] as List)
            .map((update) =>
                StatusUpdate.fromMap(Map<String, dynamic>.from(update)))
            .toList();
      }
    }

    // deliveryInfo 처리
    DeliveryInfo deliveryInfo;
    if (data['deliveryInfo'] != null && data['deliveryInfo'] is Map) {
      deliveryInfo =
          DeliveryInfo.fromMap(Map<String, dynamic>.from(data['deliveryInfo']));
    } else {
      // 기본 deliveryInfo 생성
      deliveryInfo = DeliveryInfo(
        name: '',
        phoneNumber: '',
        address: '',
        zipCode: '',
      );
    }

    // exchangeReturnRequestIds 처리
    List<String>? exchangeReturnRequestIds;
    if (data['exchangeReturnRequestIds'] != null) {
      exchangeReturnRequestIds =
          List<String>.from(data['exchangeReturnRequestIds']);
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
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      paymentMethod: data['paymentMethod'],
      isPaid: data['isPaid'] ?? false,
      transactionId: data['transactionId'],
      deliveryInfo: deliveryInfo,
      notes: data['notes'],
      statusUpdates: statusUpdates.isEmpty ? null : statusUpdates,
      exchangeReturnRequestIds: exchangeReturnRequestIds,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Map에서 OrderModel 생성
  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    // items 처리
    List<CartItemModel> items = [];
    if (data['items'] != null) {
      if (data['items'] is List) {
        items = (data['items'] as List)
            .map((item) =>
                CartItemModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    // statusUpdates 처리
    List<StatusUpdate> statusUpdates = [];
    if (data['statusUpdates'] != null) {
      if (data['statusUpdates'] is List) {
        statusUpdates = (data['statusUpdates'] as List)
            .map((update) =>
                StatusUpdate.fromMap(Map<String, dynamic>.from(update)))
            .toList();
      }
    }

    // deliveryInfo 처리
    DeliveryInfo deliveryInfo;
    if (data['deliveryInfo'] != null && data['deliveryInfo'] is Map) {
      deliveryInfo =
          DeliveryInfo.fromMap(Map<String, dynamic>.from(data['deliveryInfo']));
    } else {
      // 기본 deliveryInfo 생성
      deliveryInfo = DeliveryInfo(
        name: '',
        phoneNumber: '',
        address: '',
        zipCode: '',
      );
    }

    // exchangeReturnRequestIds 처리
    List<String>? exchangeReturnRequestIds;
    if (data['exchangeReturnRequestIds'] != null) {
      exchangeReturnRequestIds =
          List<String>.from(data['exchangeReturnRequestIds']);
    }

    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      items: items,
      orderDate: data['orderDate'] is Timestamp
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.now(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      paymentMethod: data['paymentMethod'],
      isPaid: data['isPaid'] ?? false,
      transactionId: data['transactionId'],
      deliveryInfo: deliveryInfo,
      notes: data['notes'],
      statusUpdates: statusUpdates.isEmpty ? null : statusUpdates,
      exchangeReturnRequestIds: exchangeReturnRequestIds,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'orderDate': Timestamp.fromDate(orderDate),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'transactionId': transactionId,
      'deliveryInfo': deliveryInfo.toMap(),
      'notes': notes,
      'statusUpdates': statusUpdates?.map((update) => update.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    } else {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    if (exchangeReturnRequestIds != null &&
        exchangeReturnRequestIds!.isNotEmpty) {
      map['exchangeReturnRequestIds'] = exchangeReturnRequestIds;
    }

    return map;
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    final json = {
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

    if (createdAt != null) {
      json['createdAt'] = createdAt!.toIso8601String();
    }

    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toIso8601String();
    }

    if (exchangeReturnRequestIds != null &&
        exchangeReturnRequestIds!.isNotEmpty) {
      json['exchangeReturnRequestIds'] = exchangeReturnRequestIds;
    }

    return json;
  }

  // JSON 역직렬화
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item))
          .toList();
    }

    List<StatusUpdate>? statusUpdates;
    if (json['statusUpdates'] != null) {
      statusUpdates = (json['statusUpdates'] as List)
          .map((update) => StatusUpdate.fromJson(update))
          .toList();
    }

    List<String>? exchangeReturnRequestIds;
    if (json['exchangeReturnRequestIds'] != null) {
      exchangeReturnRequestIds =
          List<String>.from(json['exchangeReturnRequestIds']);
    }

    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      items: items,
      orderDate: DateTime.parse(json['orderDate']),
      subtotal: json['subtotal'].toDouble(),
      shippingFee: json['shippingFee'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      status: OrderStatus.fromString(json['status']),
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'],
      transactionId: json['transactionId'],
      deliveryInfo: DeliveryInfo.fromJson(json['deliveryInfo']),
      notes: json['notes'],
      statusUpdates: statusUpdates,
      exchangeReturnRequestIds: exchangeReturnRequestIds,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
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
    List<String>? exchangeReturnRequestIds,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      exchangeReturnRequestIds:
          exchangeReturnRequestIds ?? this.exchangeReturnRequestIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
