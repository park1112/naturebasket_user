// lib/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory {
  food, // 식품
  living, // 생활용품
  beauty, // 뷰티
  fashion, // 패션
  home, // 가정용품
  eco, // 친환경/자연
}

class ProductModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> imageUrls;
  final ProductCategory category;
  final Map<String, dynamic>? options;
  final bool isEco; // 친환경 제품 여부
  final List<String>? ecoLabels; // 친환경 인증 정보
  final int stockQuantity;
  final int stock;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final Map<String, dynamic>? specifications; // 상품 상세 스펙
  final List<String>? tags; // 검색 태그
  final double sellingPrice;
  final double discountRate;
  final bool isOrganic;
  final List<String> images;
  final Map<String, dynamic>? details;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.imageUrls,
    required this.category,
    this.options,
    required this.isEco,
    this.ecoLabels,
    required this.stockQuantity,
    required this.stock,
    required this.averageRating,
    required this.reviewCount,
    required this.createdAt,
    this.specifications,
    this.tags,
    required this.sellingPrice,
    required this.discountRate,
    required this.isOrganic,
    required this.images,
    this.details,
    required this.updatedAt,
  });
  // 할인율 계산
  double get calculatedDiscountRate {
    if (discountPrice == null || discountPrice! >= price) return 0;
    return ((price - discountPrice!) / price * 100).round() / 100;
  }

  // 할인율 퍼센트 표시 (정수)
  String get discountPercentage {
    if (discountPrice == null || discountPrice! >= price) return "0%";
    return "${((price - discountPrice!) / price * 100).round()}%";
  }

  // 재고 있는지 여부
  bool get isInStock => stockQuantity > 0;

  // Firestore에서 데이터 로드
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPrice: data['discountPrice'] != null
          ? (data['discountPrice'] as num).toDouble()
          : null,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: _getCategoryFromString(data['category'] ?? 'eco'),
      options: data['options'],
      isEco: data['isEco'] ?? false,
      ecoLabels: data['ecoLabels'] != null
          ? List<String>.from(data['ecoLabels'])
          : null,
      stockQuantity: data['stockQuantity'] ?? 0,
      stock: data['stock'] ?? 0,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specifications: data['specifications'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      discountRate: (data['discountRate'] ?? 0).toDouble(),
      isOrganic: data['isOrganic'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      details: data['details'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrls': imageUrls,
      'category': category.toString().split('.').last,
      'options': options,
      'isEco': isEco,
      'ecoLabels': ecoLabels,
      'stockQuantity': stockQuantity,
      'stock': stock,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': FieldValue.serverTimestamp(),
      'specifications': specifications,
      'tags': tags,
      'sellingPrice': sellingPrice,
      'discountRate': discountRate,
      'isOrganic': isOrganic,
      'images': images,
      'details': details,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // 문자열에서 카테고리 enum 반환
  static ProductCategory _getCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return ProductCategory.food;
      case 'living':
        return ProductCategory.living;
      case 'beauty':
        return ProductCategory.beauty;
      case 'fashion':
        return ProductCategory.fashion;
      case 'home':
        return ProductCategory.home;
      case 'eco':
        return ProductCategory.eco;
      default:
        return ProductCategory.eco;
    }
  }

  // 카테고리 한글명 반환
  String get categoryName {
    switch (category) {
      case ProductCategory.food:
        return '식품';
      case ProductCategory.living:
        return '생활용품';
      case ProductCategory.beauty:
        return '뷰티';
      case ProductCategory.fashion:
        return '패션';
      case ProductCategory.home:
        return '가정용품';
      case ProductCategory.eco:
        return '친환경/자연';
    }
  }

  // 복사 및 업데이트
  ProductModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    double? price,
    double? discountPrice,
    List<String>? imageUrls,
    ProductCategory? category,
    Map<String, dynamic>? options,
    bool? isEco,
    List<String>? ecoLabels,
    int? stockQuantity,
    int? stock,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    double? sellingPrice,
    double? discountRate,
    bool? isOrganic,
    List<String>? images,
    Map<String, dynamic>? details,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      options: options ?? this.options,
      isEco: isEco ?? this.isEco,
      ecoLabels: ecoLabels ?? this.ecoLabels,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stock: stock ?? this.stock,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountRate: discountRate ?? this.discountRate,
      isOrganic: isOrganic ?? this.isOrganic,
      images: images ?? this.images,
      details: details ?? this.details,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
