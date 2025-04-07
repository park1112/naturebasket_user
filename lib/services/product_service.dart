// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/product_model.dart';
import '../models/review_model.dart';
import '../config/constants.dart';
import '../utils/custom_loading.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference _reviewsCollection =
      FirebaseFirestore.instance.collection('reviews');
  final CollectionReference _wishlistsCollection =
      FirebaseFirestore.instance.collection('wishlists');

  // 상품 기본 정보 로드 (ID로)
  Future<ProductModel?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();

      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 정보를 불러오는 중 오류가 발생했습니다.');
      return null;
    } catch (e) {
      _handleGenericError(e, '상품 정보 로드 중 예상치 못한 오류가 발생했습니다.');
      return null;
    }
  }

  // 카테고리별 상품 불러오기
  Future<List<ProductModel>> getProductsByCategory(ProductCategory category,
      {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '카테고리별 상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '카테고리별 상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 친환경 상품 불러오기
  Future<List<ProductModel>> getEcoProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isEco', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '친환경 상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '친환경 상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 유기농 상품 불러오기
  Future<List<ProductModel>> getOrganicProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isOrganic', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '유기농 상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '유기농 상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 인기 상품 불러오기 (평점 기준)
  Future<List<ProductModel>> getPopularProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '인기 상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '인기 상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 신상품 불러오기
  Future<List<ProductModel>> getNewProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '신상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '신상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 추천 상품 불러오기
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '추천 상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '추천 상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 모든 상품 불러오기
  Future<List<ProductModel>> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // ID로 상품 상세 정보 불러오기
  Future<ProductModel?> fetchProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();

      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      } else {
        Get.snackbar(
          '알림',
          '해당 상품을 찾을 수 없습니다.',
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 상세 정보를 불러오는 중 오류가 발생했습니다.');
      return null;
    } catch (e) {
      _handleGenericError(e, '상품 상세 정보 로드 중 예상치 못한 오류가 발생했습니다.');
      return null;
    }
  }

  // 페이지네이션을 위한 상품 목록 가져오기
  Future<List<ProductModel>> fetchProductsPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    String? categoryId,
    String? searchKeyword,
    bool? isEco,
    bool? isOrganic,
    String? sortBy,
    bool descending = true,
  }) async {
    try {
      Query query = _productsCollection.where('isActive', isEqualTo: true);

      // 필터 적용
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryId);
      }

      if (isEco != null) {
        query = query.where('isEco', isEqualTo: isEco);
      }

      if (isOrganic != null) {
        query = query.where('isOrganic', isEqualTo: isOrganic);
      }

      // 정렬 적용
      if (sortBy != null) {
        query = query.orderBy(sortBy, descending: descending);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      // 키워드 검색이 있는 경우 (부분 일치 검색은 Firestore에서 직접 지원하지 않음)
      // 시작 부분 일치 검색만 가능
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: searchKeyword)
            .where('name', isLessThanOrEqualTo: searchKeyword + '\uf8ff');
      }

      // 시작점 설정 (페이지네이션)
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 목록을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '상품 목록 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // ProductModel의 ID로 실제 Firestore DocumentSnapshot 가져오기 (페이지네이션용)
  Future<DocumentSnapshot?> getProductDocument(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      print('상품 문서 가져오기 오류: $e');
      return null;
    }
  }

  // 상품 리뷰 가져오기
  Future<List<ReviewModel>> getProductReviews(String productId,
      {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _reviewsCollection
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 리뷰를 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '상품 리뷰 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 연관 상품 가져오기
  Future<List<ProductModel>> getRelatedProducts(ProductModel product,
      {int limit = 6}) async {
    try {
      // 1. 같은 카테고리의 상품 가져오기
      QuerySnapshot categorySnapshot = await _productsCollection
          .where('category',
              isEqualTo: product.category.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: product.id)
          .limit(limit)
          .get();

      List<ProductModel> relatedProducts = categorySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      // 카테고리 상품이 limit보다 적으면 태그 기반으로 추가 검색
      if (relatedProducts.length < limit &&
          product.tags != null &&
          product.tags!.isNotEmpty) {
        // 이미 가져온 상품 ID 목록
        List<String> existingIds = relatedProducts.map((p) => p.id).toList();
        existingIds.add(product.id); // 현재 상품도 제외

        // 태그 기반 검색 (첫번째 태그 사용)
        QuerySnapshot tagSnapshot = await _productsCollection
            .where('tags', arrayContains: product.tags!.first)
            .where('isActive', isEqualTo: true)
            .limit(limit * 2) // 더 많이 가져와서 필터링
            .get();

        // 이미 있는 상품 제외하고 추가
        for (var doc in tagSnapshot.docs) {
          if (!existingIds.contains(doc.id) && relatedProducts.length < limit) {
            relatedProducts.add(ProductModel.fromFirestore(doc));
            existingIds.add(doc.id);
          }
        }
      }

      return relatedProducts;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '연관 상품을 불러오는 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '연관 상품 로드 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 키워드로 상품 검색
  Future<List<ProductModel>> searchProducts(String keyword,
      {int limit = 20}) async {
    try {
      if (keyword.trim().isEmpty) {
        return await getPopularProducts(limit: limit);
      }

      // 이름 기준 검색 (시작 부분 일치)
      QuerySnapshot nameSnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: keyword)
          .where('name', isLessThanOrEqualTo: keyword + '\uf8ff')
          .limit(limit)
          .get();

      // 태그 기준 검색
      QuerySnapshot tagSnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('tags', arrayContains: keyword)
          .limit(limit)
          .get();

      // 결과 합치기 (중복 제거)
      Set<String> productIds = {};
      List<ProductModel> results = [];

      for (var doc in nameSnapshot.docs) {
        if (!productIds.contains(doc.id)) {
          productIds.add(doc.id);
          results.add(ProductModel.fromFirestore(doc));
        }
      }

      for (var doc in tagSnapshot.docs) {
        if (!productIds.contains(doc.id)) {
          productIds.add(doc.id);
          results.add(ProductModel.fromFirestore(doc));
        }
      }

      return results;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 검색 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '상품 검색 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  // 위시리스트 상태 확인
  Future<bool> isProductInWishlist(String userId, String productId) async {
    try {
      DocumentSnapshot wishlistDoc = await _wishlistsCollection
          .doc(userId)
          .collection('items')
          .doc(productId)
          .get();

      return wishlistDoc.exists;
    } catch (e) {
      print('위시리스트 상태 확인 오류: $e');
      return false;
    }
  }

  // 위시리스트에 상품 추가
  Future<bool> addToWishlist(String userId, ProductModel product) async {
    try {
      // CustomLoading.showLoading();

      // 위시리스트 아이템 추가
      await _wishlistsCollection
          .doc(userId)
          .collection('items')
          .doc(product.id)
          .set({
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'discountPrice': product.discountPrice,
        'sellingPrice': product.sellingPrice,
        'imageUrl': product.images.isNotEmpty ? product.images.first : null,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 위시리스트 카운트 업데이트
      DocumentReference userWishlistRef = _wishlistsCollection.doc(userId);
      DocumentSnapshot userWishlistDoc = await userWishlistRef.get();

      if (userWishlistDoc.exists) {
        await userWishlistRef.update({
          'count': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userWishlistRef.set({
          'userId': userId,
          'count': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        '알림',
        '${product.name}이(가) 찜 목록에 추가되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '찜 목록에 추가하는 중 오류가 발생했습니다.');
      return false;
    } catch (e) {
      _handleGenericError(e, '찜 목록에 추가하는 중 예상치 못한 오류가 발생했습니다.');
      return false;
    } finally {
      // CustomLoading.hideLoading();
    }
  }

  // 위시리스트에서 상품 제거
  Future<bool> removeFromWishlist(String userId, String productId) async {
    try {
      // CustomLoading.showLoading();

      // 위시리스트 아이템 삭제
      await _wishlistsCollection
          .doc(userId)
          .collection('items')
          .doc(productId)
          .delete();

      // 위시리스트 카운트 업데이트
      DocumentReference userWishlistRef = _wishlistsCollection.doc(userId);

      await userWishlistRef.update({
        'count': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        '알림',
        '찜 목록에서 상품이 제거되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '찜 목록에서 제거하는 중 오류가 발생했습니다.');
      return false;
    } catch (e) {
      _handleGenericError(e, '찜 목록에서 제거하는 중 예상치 못한 오류가 발생했습니다.');
      return false;
    } finally {
      // CustomLoading.hideLoading();
    }
  }

  // 리뷰 작성
  Future<bool> addReview({
    required String userId,
    required String productId,
    required String userName,
    String? userPhotoURL,
    required String content,
    required int rating,
    List<String>? imageUrls,
    bool isVerifiedPurchase = false,
  }) async {
    try {
      LoadingOverlay.show(Get.context!);

      // 리뷰 추가
      DocumentReference reviewRef = _reviewsCollection.doc();
      await reviewRef.set({
        'id': reviewRef.id,
        'userId': userId,
        'productId': productId,
        'userName': userName,
        'userPhotoURL': userPhotoURL,
        'content': content,
        'rating': rating,
        'imageUrls': imageUrls ?? [],
        'isVerifiedPurchase': isVerifiedPurchase,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 상품 평점 업데이트
      DocumentReference productRef = _productsCollection.doc(productId);
      DocumentSnapshot productDoc = await productRef.get();

      if (productDoc.exists) {
        Map<String, dynamic> data = productDoc.data() as Map<String, dynamic>;
        int currentReviewCount = data['reviewCount'] ?? 0;
        double currentAverageRating = (data['averageRating'] ?? 0).toDouble();

        // 새 평균 평점 계산
        double newAverageRating;
        if (currentReviewCount == 0) {
          newAverageRating = rating.toDouble();
        } else {
          double totalRating = currentAverageRating * currentReviewCount;
          newAverageRating = (totalRating + rating) / (currentReviewCount + 1);
        }

        // 상품 정보 업데이트
        await productRef.update({
          'reviewCount': FieldValue.increment(1),
          'averageRating': double.parse(newAverageRating.toStringAsFixed(1)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        '리뷰 작성 완료',
        '상품 리뷰가 성공적으로 등록되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '리뷰 작성 중 오류가 발생했습니다.');
      return false;
    } catch (e) {
      _handleGenericError(e, '리뷰 작성 중 예상치 못한 오류가 발생했습니다.');
      return false;
    } finally {
      LoadingOverlay.hide();
    }
  }

  // 에러 핸들링 헬퍼 함수
  void _handleFirebaseError(FirebaseException e, String message) {
    print('Firebase 오류: ${e.code} - ${e.message}');

    Get.snackbar(
      '오류',
      '$message (${e.code})',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red.shade700,
      duration: const Duration(seconds: 3),
    );
  }

  void _handleGenericError(dynamic e, String message) {
    print('일반 오류: $e');

    Get.snackbar(
      '오류',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red.shade700,
      duration: const Duration(seconds: 3),
    );
  }
}
