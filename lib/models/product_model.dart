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

enum TaxType {
  taxable, // 과세상품
  taxFree, // 면세상품
  zeroTax, // 영세상품
}

enum ShippingMethod {
  standardDelivery, // 일반택배
  directDelivery, // 직접배송
}

enum ShippingType {
  standard, // 일반배송
  sameDay, // 오늘출발
}

enum ShippingFeeType {
  free, // 무료
  paid, // 유료
}

class ProductOption {
  final String id;
  final String name;
  final double additionalPrice;
  final int stockQuantity;
  final bool isAvailable;

  ProductOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.stockQuantity,
    required this.isAvailable,
  });

  // Firestore에서 데이터 로드
  factory ProductOption.fromMap(Map<String, dynamic> data, String id) {
    return ProductOption(
      id: id,
      name: data['name'] ?? '',
      additionalPrice: (data['additionalPrice'] ?? 0).toDouble(),
      stockQuantity: data['stockQuantity'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'additionalPrice': additionalPrice,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
    };
  }
}

class ShippingInfo {
  final bool hasShipping; // 배송 여부 (true: 배송함, false: 배송없음)
  final ShippingMethod method; // 배송 방법
  final ShippingType type; // 배송 속성
  final Map<String, dynamic>? sameDaySettings; // 오늘출발 설정 (배송시간 등)
  final List<int> holidayDays; // 휴무일 (1: 월요일, 7: 일요일)
  final ShippingFeeType feeType; // 배송비 유형
  final double? feeAmount; // 배송비 금액 (유료일 경우)
  final String? shippingOrigin; // 출고지 주소

  ShippingInfo({
    required this.hasShipping,
    required this.method,
    required this.type,
    this.sameDaySettings,
    required this.holidayDays,
    required this.feeType,
    this.feeAmount,
    this.shippingOrigin,
  });

  // Firestore에서 데이터 로드
  factory ShippingInfo.fromMap(Map<String, dynamic> data) {
    return ShippingInfo(
      hasShipping: data['hasShipping'] ?? true,
      method:
          _getShippingMethodFromString(data['method'] ?? 'standardDelivery'),
      type: _getShippingTypeFromString(data['type'] ?? 'standard'),
      sameDaySettings: data['sameDaySettings'],
      holidayDays: data['holidayDays'] != null
          ? List<int>.from(data['holidayDays'])
          : [],
      feeType: _getShippingFeeTypeFromString(data['feeType'] ?? 'free'),
      feeAmount: data['feeAmount'] != null
          ? (data['feeAmount'] as num).toDouble()
          : null,
      shippingOrigin: data['shippingOrigin'],
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'hasShipping': hasShipping,
      'method': method.toString().split('.').last,
      'type': type.toString().split('.').last,
      'sameDaySettings': sameDaySettings,
      'holidayDays': holidayDays,
      'feeType': feeType.toString().split('.').last,
      'feeAmount': feeAmount,
      'shippingOrigin': shippingOrigin,
    };
  }

  // 문자열에서 배송 방법 enum 반환
  static ShippingMethod _getShippingMethodFromString(String method) {
    switch (method.toLowerCase()) {
      case 'standarddelivery':
        return ShippingMethod.standardDelivery;
      case 'directdelivery':
        return ShippingMethod.directDelivery;
      default:
        return ShippingMethod.standardDelivery;
    }
  }

  // 문자열에서 배송 속성 enum 반환
  static ShippingType _getShippingTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return ShippingType.standard;
      case 'sameday':
        return ShippingType.sameDay;
      default:
        return ShippingType.standard;
    }
  }

  // 문자열에서 배송비 유형 enum 반환
  static ShippingFeeType _getShippingFeeTypeFromString(String feeType) {
    switch (feeType.toLowerCase()) {
      case 'free':
        return ShippingFeeType.free;
      case 'paid':
        return ShippingFeeType.paid;
      default:
        return ShippingFeeType.free;
    }
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String description;
  final List<String> descriptionImages; // 상품 설명에 포함될 이미지들
  final double price;
  final double? discountPrice;
  final List<String> imageUrls;
  final ProductCategory category;
  final Map<String, dynamic>? options; // 옵션 맵 (id -> 옵션 데이터)
  final bool isEco; // 친환경 제품 여부
  final List<String>? ecoLabels; // 친환경 인증 정보
  final int stockQuantity;
  final int maxOrderQuantity; // 최대 주문 가능 수량
  final String origin; // 원산지
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final TaxType taxType; // 부가세 유형 (과세, 면세, 영세)
  final Map<String, dynamic>? specifications; // 상품 상세 스펙
  final List<String>? tags; // 검색 태그
  final DateTime? salesStartDate; // 판매 시작일
  final DateTime? salesEndDate; // 판매 종료일
  final double sellingPrice; // 최종 판매가
  final double discountRate; // 할인율
  final bool isOrganic; // 유기농 여부
  final List<String> images; // 상품 이미지
  final Map<String, dynamic>? details; // 추가 상세 정보
  final ShippingInfo shippingInfo; // 배송 정보
  final DateTime updatedAt;
  final bool isActive; // 상품 활성화 여부
  final bool isFeatured; // 추천 상품 여부
  final String createdBy; // 생성자
  final String updatedBy; // 수정자

  ProductModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.description,
    required this.descriptionImages,
    required this.price,
    this.discountPrice,
    required this.imageUrls,
    required this.category,
    this.options,
    required this.isEco,
    this.ecoLabels,
    required this.stockQuantity,
    required this.maxOrderQuantity,
    required this.origin,
    required this.averageRating,
    required this.reviewCount,
    required this.createdAt,
    required this.taxType,
    this.specifications,
    this.tags,
    this.salesStartDate,
    this.salesEndDate,
    required this.sellingPrice,
    required this.discountRate,
    required this.isOrganic,
    required this.images,
    this.details,
    required this.shippingInfo,
    required this.updatedAt,
    this.isActive = true, // 기본값 true로 설정
    this.isFeatured = false, // 기본값 false로 설정
    required this.createdBy,
    required this.updatedBy,
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

  // 판매 중인지 여부 (판매 기간 체크)
  bool get isOnSale {
    final now = DateTime.now();

    // 판매 시작일이 설정되어 있고, 아직 시작되지 않았다면
    if (salesStartDate != null && now.isBefore(salesStartDate!)) {
      return false;
    }

    // 판매 종료일이 설정되어 있고, 이미 종료되었다면
    if (salesEndDate != null && now.isAfter(salesEndDate!)) {
      return false;
    }

    return isActive; // 활성화 여부 확인
  }

  // Firestore에서 데이터 로드
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 배송 정보 변환
    ShippingInfo shippingInfo = ShippingInfo(
      hasShipping: true,
      method: ShippingMethod.standardDelivery,
      type: ShippingType.standard,
      holidayDays: [],
      feeType: ShippingFeeType.free,
    );

    if (data['shippingInfo'] != null) {
      shippingInfo = ShippingInfo.fromMap(data['shippingInfo']);
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      description: data['description'] ?? '',
      descriptionImages: List<String>.from(data['descriptionImages'] ?? []),
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
      maxOrderQuantity: data['maxOrderQuantity'] ?? 10, // 기본값 10개
      origin: data['origin'] ?? '국내산',
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taxType: _getTaxTypeFromString(data['taxType'] ?? 'taxable'),
      specifications: data['specifications'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      salesStartDate: (data['salesStartDate'] as Timestamp?)?.toDate(),
      salesEndDate: (data['salesEndDate'] as Timestamp?)?.toDate(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      discountRate: (data['discountRate'] ?? 0).toDouble(),
      isOrganic: data['isOrganic'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      details: data['details'],
      shippingInfo: shippingInfo,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      createdBy: data['createdBy'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'descriptionImages': descriptionImages,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrls': imageUrls,
      'category': category.toString().split('.').last,
      'options': options,
      'isEco': isEco,
      'ecoLabels': ecoLabels,
      'stockQuantity': stockQuantity,
      'maxOrderQuantity': maxOrderQuantity,
      'origin': origin,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
      'taxType': taxType.toString().split('.').last,
      'specifications': specifications,
      'tags': tags,
      'salesStartDate': salesStartDate,
      'salesEndDate': salesEndDate,
      'sellingPrice': sellingPrice,
      'discountRate': discountRate,
      'isOrganic': isOrganic,
      'images': images,
      'details': details,
      'shippingInfo': shippingInfo.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'isFeatured': isFeatured,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
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

  // 문자열에서 부가세 유형 enum 반환
  static TaxType _getTaxTypeFromString(String taxType) {
    switch (taxType.toLowerCase()) {
      case 'taxable':
        return TaxType.taxable;
      case 'taxfree':
        return TaxType.taxFree;
      case 'zerotax':
        return TaxType.zeroTax;
      default:
        return TaxType.taxable;
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

  // 부가세 유형 한글명 반환
  String get taxTypeName {
    switch (taxType) {
      case TaxType.taxable:
        return '과세상품';
      case TaxType.taxFree:
        return '면세상품';
      case TaxType.zeroTax:
        return '영세상품';
    }
  }

  // 배송 방법 한글명 반환
  String get shippingMethodName {
    switch (shippingInfo.method) {
      case ShippingMethod.standardDelivery:
        return '일반택배';
      case ShippingMethod.directDelivery:
        return '직접배송';
    }
  }

  // 배송 속성 한글명 반환
  String get shippingTypeName {
    switch (shippingInfo.type) {
      case ShippingType.standard:
        return '일반배송';
      case ShippingType.sameDay:
        return '오늘출발';
    }
  }

  // 배송비 유형 한글명 반환
  String get shippingFeeTypeName {
    switch (shippingInfo.feeType) {
      case ShippingFeeType.free:
        return '무료배송';
      case ShippingFeeType.paid:
        return '유료배송';
    }
  }

  // 휴무일 요일 문자열 반환
  String get holidayDaysString {
    if (shippingInfo.holidayDays.isEmpty) return '없음';

    List<String> days = [];
    if (shippingInfo.holidayDays.contains(1)) days.add('월');
    if (shippingInfo.holidayDays.contains(2)) days.add('화');
    if (shippingInfo.holidayDays.contains(3)) days.add('수');
    if (shippingInfo.holidayDays.contains(4)) days.add('목');
    if (shippingInfo.holidayDays.contains(5)) days.add('금');
    if (shippingInfo.holidayDays.contains(6)) days.add('토');
    if (shippingInfo.holidayDays.contains(7)) days.add('일');

    return days.join(', ');
  }

  // 복사 및 업데이트
  ProductModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    List<String>? descriptionImages,
    double? price,
    double? discountPrice,
    List<String>? imageUrls,
    ProductCategory? category,
    Map<String, dynamic>? options,
    bool? isEco,
    List<String>? ecoLabels,
    int? stockQuantity,
    int? maxOrderQuantity,
    String? origin,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    TaxType? taxType,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    DateTime? salesStartDate,
    DateTime? salesEndDate,
    double? sellingPrice,
    double? discountRate,
    bool? isOrganic,
    List<String>? images,
    Map<String, dynamic>? details,
    ShippingInfo? shippingInfo,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFeatured,
    String? createdBy,
    String? updatedBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      descriptionImages: descriptionImages ?? this.descriptionImages,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      options: options ?? this.options,
      isEco: isEco ?? this.isEco,
      ecoLabels: ecoLabels ?? this.ecoLabels,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      origin: origin ?? this.origin,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      taxType: taxType ?? this.taxType,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      salesStartDate: salesStartDate ?? this.salesStartDate,
      salesEndDate: salesEndDate ?? this.salesEndDate,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountRate: discountRate ?? this.discountRate,
      isOrganic: isOrganic ?? this.isOrganic,
      images: images ?? this.images,
      details: details ?? this.details,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
