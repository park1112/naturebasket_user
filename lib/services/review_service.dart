import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../models/review_model.dart';
import '../models/order_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 상품에 대한 모든 리뷰 가져오기
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  // 사용자가 작성한 모든 리뷰 가져오기
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  // 특정 주문의 리뷰 가져오기
  Future<List<ReviewModel>> getOrderReviews(String orderId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('orderId', isEqualTo: orderId)
        .get();

    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  // 특정 상품의 별점 평균 가져오기
  Future<double> getProductAverageRating(String productId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .get();

    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    final reviews =
        snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  // 리뷰 추가하기
  Future<String> addReview(ReviewModel review) async {
    final docRef = await _firestore.collection('reviews').add(review.toMap());

    // 상품 컬렉션에 평균 평점 업데이트
    await updateProductRating(review.productId);

    return docRef.id;
  }

  // 리뷰 수정하기
  Future<void> updateReview(ReviewModel review) async {
    await _firestore
        .collection('reviews')
        .doc(review.id)
        .update(review.toMap());

    // 상품 컬렉션에 평균 평점 업데이트
    await updateProductRating(review.productId);
  }

  // 리뷰 삭제하기
  Future<void> deleteReview(String reviewId, String productId) async {
    // 리뷰 정보 가져오기
    final reviewDoc =
        await _firestore.collection('reviews').doc(reviewId).get();
    final reviewData = reviewDoc.data();

    // 이미지가 있으면 스토리지에서 삭제
    if (reviewData != null && reviewData['imageUrls'] != null) {
      final List<String> imageUrls = List<String>.from(reviewData['imageUrls']);
      for (String url in imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          print('이미지 삭제 실패: $e');
        }
      }
    }

    // 리뷰 삭제
    await _firestore.collection('reviews').doc(reviewId).delete();

    // 상품 컬렉션에 평균 평점 업데이트
    await updateProductRating(productId);
  }

  // 리뷰 이미지 업로드
  Future<List<String>> uploadReviewImages(
      String userId, List<XFile> images) async {
    List<String> imageUrls = [];

    for (var image in images) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final ref = _storage.ref().child('reviews/$userId/$fileName');

      final uploadTask = ref.putFile(File(image.path));
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      imageUrls.add(url);
    }

    return imageUrls;
  }

  // 상품 평균 평점 업데이트
  Future<void> updateProductRating(String productId) async {
    final double avgRating = await getProductAverageRating(productId);

    await _firestore.collection('products').doc(productId).update({
      'averageRating': avgRating,
      'reviewCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // 리뷰 도움이 됐어요 기능
  Future<void> markReviewAsHelpful(String reviewId) async {
    await _firestore.collection('reviews').doc(reviewId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }

  // 사용자가 리뷰를 작성할 수 있는 상품 목록 가져오기
  Future<List<Map<String, dynamic>>> getReviewableProducts(
      String userId) async {
    List<Map<String, dynamic>> reviewableProducts = [];

    try {
      // 사용자 주문 가져오기
      final orderSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['delivered', 'completed']).get();

      // 주문이 없는 경우
      if (orderSnapshot.docs.isEmpty) {
        return [];
      }

      // 사용자가 작성한 리뷰 가져오기
      final reviewSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      final reviewedProducts = reviewSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productId': data['productId'],
          'orderId': data['orderId'],
          'isDetailReview': data['isDetailReview'] ?? false,
        };
      }).toList();

      // 주문별로 처리
      for (var orderDoc in orderSnapshot.docs) {
        final orderData = orderDoc.data();
        final order = OrderModel.fromMap(orderData, orderDoc.id);

        // 상품별로 처리
        for (var item in order.items) {
          // 이미 작성한 리뷰가 있는지 확인
          final hasDetailReview = reviewedProducts.any((review) =>
              review['productId'] == item.productId &&
              review['orderId'] == order.id &&
              review['isDetailReview'] == true);

          final hasRatingOnly = reviewedProducts.any((review) =>
              review['productId'] == item.productId &&
              review['orderId'] == order.id &&
              review['isDetailReview'] == false);

          // 리뷰 작성 기한 계산 (배송 완료 후 90일)
          final deliveryDate = order.deliveryDate ??
              order.orderDate.add(const Duration(days: 3));
          final reviewDeadline = deliveryDate.add(const Duration(days: 90));

          // 리뷰 작성 기한이 지나지 않았을 경우만 추가
          if (DateTime.now().isBefore(reviewDeadline)) {
            reviewableProducts.add({
              'productId': item.productId,
              'productName': item.productName,
              'productImage': item.productImage,
              'orderId': order.id,
              'orderDate': order.orderDate,
              'deliveryDate': deliveryDate,
              'reviewDeadline': reviewDeadline,
              'hasDetailReview': hasDetailReview,
              'hasRatingOnly': hasRatingOnly,
              'canWriteDetailReview': !hasDetailReview,
              'canWriteRatingOnly': !hasRatingOnly && !hasDetailReview,
            });
          }
        }
      }

      return reviewableProducts;
    } catch (e) {
      print('리뷰 작성 가능한 상품 조회 오류: $e');
      return [];
    }
  }

  // 사용자가 서비스 리뷰를 이미 작성했는지 확인
  Future<bool> hasUserWrittenServiceReview(
      String userId, String orderId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .where('orderId', isEqualTo: orderId)
        .where('reviewType', isEqualTo: 'service')
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
