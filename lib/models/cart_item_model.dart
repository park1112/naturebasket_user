// lib/models/cart_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final Map<String, dynamic>? selectedOptions;
  final DateTime addedAt;
  final ProductModel? product; // late 제거하고 nullable로 변경

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.selectedOptions,
    required this.addedAt,
    this.product, // required 제거
  });

  // 합계 계산
  double get totalPrice => price * quantity;

  // Firestore에서 데이터 로드
  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CartItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'],
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      selectedOptions: data['selectedOptions'],
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      product: null, // 이 부분을 수정, 나중에 필요할 때 로드하도록
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'selectedOptions': selectedOptions,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  // 수량 변경한 새 객체 생성
  CartItemModel copyWithQuantity(int newQuantity) {
    return CartItemModel(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      price: price,
      quantity: newQuantity > 0 ? newQuantity : 1,
      selectedOptions: selectedOptions,
      addedAt: addedAt,
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'selectedOptions': selectedOptions,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      selectedOptions: json['selectedOptions'],
      addedAt: DateTime.parse(json['addedAt']),
      product: ProductModel.fromFirestore(json['product']),
    );
  }
}
