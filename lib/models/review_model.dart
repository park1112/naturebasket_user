import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final double rating;
  final String? content; // Optional for star-only reviews
  final List<String>? tags; // For review tags like '맛있어요', '배송이 빨라요' etc.
  final List<String>? imageUrls;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final String orderId; // Associated order ID
  final DateTime? deliveryDate; // When the product was delivered
  final DateTime reviewDeadline; // Deadline for leaving a review
  final bool isDetailReview; // Whether it's a detailed review or just a rating
  final int helpfulCount; // Number of users who found this review helpful
  final String?
      reviewType; // 'service' for service review, 'product' for product review

  ReviewModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.rating,
    this.content,
    this.tags,
    this.imageUrls,
    required this.createdAt,
    required this.isVerifiedPurchase,
    required this.orderId,
    this.deliveryDate,
    required this.reviewDeadline,
    required this.isDetailReview,
    this.helpfulCount = 0,
    this.reviewType,
  });

  // Firestore에서 데이터 로드
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '익명',
      userPhotoURL: data['userPhotoURL'],
      rating: (data['rating'] ?? 0).toDouble(),
      content: data['content'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      orderId: data['orderId'] ?? '',
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      reviewDeadline: (data['reviewDeadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 90)),
      isDetailReview: data['isDetailReview'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      reviewType: data['reviewType'],
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'rating': rating,
      'content': content,
      'tags': tags,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerifiedPurchase': isVerifiedPurchase,
      'orderId': orderId,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'reviewDeadline': Timestamp.fromDate(reviewDeadline),
      'isDetailReview': isDetailReview,
      'helpfulCount': helpfulCount,
      'reviewType': reviewType,
    };
  }

  // 업데이트된 리뷰 생성을 위한 복사본 만들기
  ReviewModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    String? userId,
    String? userName,
    String? userPhotoURL,
    double? rating,
    String? content,
    List<String>? tags,
    List<String>? imageUrls,
    DateTime? createdAt,
    bool? isVerifiedPurchase,
    String? orderId,
    DateTime? deliveryDate,
    DateTime? reviewDeadline,
    bool? isDetailReview,
    int? helpfulCount,
    String? reviewType,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      orderId: orderId ?? this.orderId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      reviewDeadline: reviewDeadline ?? this.reviewDeadline,
      isDetailReview: isDetailReview ?? this.isDetailReview,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reviewType: reviewType ?? this.reviewType,
    );
  }
}
