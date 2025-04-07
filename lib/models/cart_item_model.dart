// lib/models/cart_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final DateTime addedAt;
  final String? optionId;
  final String? optionName;
  final double? optionPrice;
  final Map<String, dynamic>? selectedOptions; // 레거시 지원용

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.addedAt,
    this.optionId,
    this.optionName,
    this.optionPrice,
    this.selectedOptions,
  });

  double get totalPrice => price * quantity;

  // Firestore 문서에서 변환
  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CartItemModel.fromMap(data, id: doc.id);
  }

  // Map에서 변환
  factory CartItemModel.fromMap(Map<String, dynamic> map, {String? id}) {
    // 옵션 관련 처리: 기존 JSON 문자열과 새로운 필드 모두 지원
    String? optionId = map['optionId'];
    String? optionName = map['optionName'];
    double? optionPrice;

    if (map['optionPrice'] != null) {
      optionPrice = (map['optionPrice'] is num)
          ? (map['optionPrice'] as num).toDouble()
          : null;
    }

    Map<String, dynamic>? selectedOptions;
    if (map['selectedOptions'] != null) {
      if (map['selectedOptions'] is String) {
        try {
          selectedOptions = json.decode(map['selectedOptions']);
        } catch (e) {
          selectedOptions = null;
        }
      } else if (map['selectedOptions'] is Map) {
        selectedOptions = Map<String, dynamic>.from(map['selectedOptions']);
      }
    }

    // 날짜 필드 처리
    DateTime addedAt;
    if (map['addedAt'] is Timestamp) {
      addedAt = (map['addedAt'] as Timestamp).toDate();
    } else if (map['addedAt'] is String) {
      try {
        addedAt = DateTime.parse(map['addedAt']);
      } catch (e) {
        addedAt = DateTime.now();
      }
    } else {
      addedAt = DateTime.now();
    }

    return CartItemModel(
      id: id ?? map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      addedAt: addedAt,
      optionId: optionId,
      optionName: optionName,
      optionPrice: optionPrice,
      selectedOptions: selectedOptions,
    );
  }

  // Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    final map = {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'addedAt': addedAt,
    };

    if (optionId != null) map['optionId'] = optionId;
    if (optionName != null) map['optionName'] = optionName;
    if (optionPrice != null) map['optionPrice'] = optionPrice;

    // 레거시 지원
    if (selectedOptions != null) {
      map['selectedOptions'] = selectedOptions;
    }

    return map;
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    final json = toMap();
    json['id'] = id;
    json['addedAt'] = addedAt.toIso8601String();
    json['totalPrice'] = totalPrice;
    return json;
  }

  // JSON 역직렬화
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel.fromMap(json);
  }

  // 항목 복사 및 업데이트
  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    DateTime? addedAt,
    String? optionId,
    String? optionName,
    double? optionPrice,
    Map<String, dynamic>? selectedOptions,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      optionId: optionId ?? this.optionId,
      optionName: optionName ?? this.optionName,
      optionPrice: optionPrice ?? this.optionPrice,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }

  // 수량 증가 헬퍼 메서드
  CartItemModel incrementQuantity(int amount) {
    return copyWith(quantity: quantity + amount);
  }

  // 수량 감소 헬퍼 메서드
  CartItemModel decrementQuantity(int amount) {
    final newQuantity = quantity - amount;
    return copyWith(quantity: newQuantity > 0 ? newQuantity : 1);
  }
}
