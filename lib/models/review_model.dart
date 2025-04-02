// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final double rating;
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final bool isVerifiedPurchase;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.rating,
    required this.content,
    this.imageUrls,
    required this.createdAt,
    required this.isVerifiedPurchase,
  });

  // Firestore에서 데이터 로드
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '익명',
      userPhotoURL: data['userPhotoURL'],
      rating: (data['rating'] ?? 0).toDouble(),
      content: data['content'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'rating': rating,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }
}
