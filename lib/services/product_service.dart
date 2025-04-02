import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import 'package:flutter/material.dart'; // SnackBar 색상 등 UI 요소에 필요할 수 있음
import 'package:get/get.dart'; // GetX 스낵바 사용
import '../config/constants.dart'; // 컬렉션 이름 등 상수 사용

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 상수 사용 권장
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // 카테고리별 상품 불러오기
  Future<List<ProductModel>> getProductsByCategory(ProductCategory category,
      {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category.toString().split('.').last)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // 친환경 상품 불러오기 (Firestore 필드 이름을 isEcoFriendly로 변경)
  Future<List<ProductModel>> getEcoProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('isEcoFriendly', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting eco products: $e');
      return [];
    }
  }

  // 페이지네이션을 위한 상품 목록 가져오기
  Future<List<ProductModel>> fetchProductsPaginated({
    required int limit, // 한 번에 가져올 문서 수
    DocumentSnapshot? startAfterDoc, // 이전 페이지의 마지막 문서 (다음 페이지 시작점)
    String? categoryId, // [선택 사항] 카테고리 필터링
  }) async {
    try {
      Query query = _productsCollection
          .orderBy('createdAt', descending: true) // 정렬 기준 (예: 최신순)
          .limit(limit);

      // 카테고리 필터링 적용
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId',
            isEqualTo: categoryId); // 'categoryId' 필드가 있다고 가정
      }

      // 다음 페이지 로딩 시 시작점 설정
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      QuerySnapshot snapshot = await query.get();

      // Firestore 문서를 ProductModel 리스트로 변환
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      print(
          "Firestore Error fetching paginated products: ${e.code} - ${e.message}");
      Get.snackbar(
        "오류",
        "상품 목록을 불러오는 중 오류 발생 (코드: ${e.code})",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.kErrorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return [];
    } catch (e) {
      print("Unexpected Error fetching paginated products: $e");
      Get.snackbar(
        "오류",
        AppConstants.kMsgErrorUnknown,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.kErrorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return [];
    }
  }

  // ProductModel의 ID로 실제 Firestore DocumentSnapshot 가져오기 (startAfterDocument에 필요)
  Future<DocumentSnapshot?> getProductDocument(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      print("Error getting product document: $e");
      return null;
    }
  }

  // 인기 상품 불러오기 (평점 기준)
  Future<List<ProductModel>> getPopularProducts({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting popular products: $e');
      return [];
    }
  }

  // 단일 상품 정보 가져오기
  Future<ProductModel?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // 상품 목록 가져오기 (에러 핸들링 추가)
  Future<List<ProductModel>> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _productsCollection
          .orderBy('createdAt', descending: true)
          .get(); // 예시: 최신순 정렬
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      // stackTrace 로깅 추가 가능
      // 개발 중 상세 로그 확인
      print("Firestore Error fetching products: ${e.code} - ${e.message}");
      // print(stackTrace); // 필요시 스택 트레이스 확인

      // 사용자에게 보여줄 스낵바 메시지
      Get.snackbar(
        "데이터 로딩 실패",
        "상품 목록을 불러오는 중 오류가 발생했습니다. 네트워크 상태를 확인하거나 잠시 후 다시 시도해주세요. (코드: ${e.code})",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
      );
      return []; // 오류 발생 시 빈 리스트 반환
    } catch (e, stackTrace) {
      // 예상치 못한 다른 종류의 에러 처리
      print("Unexpected Error fetching products: $e");
      // print(stackTrace);

      Get.snackbar(
        "알 수 없는 오류",
        "상품 목록 로딩 중 예상치 못한 오류가 발생했습니다.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
      );
      return [];
    }
  }

  // 단일 상품 가져오기 (에러 핸들링 추가)
  Future<ProductModel?> fetchProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      } else {
        // 상품이 없는 경우 (오류는 아니지만 사용자 알림)
        // Get.snackbar("알림", "해당 상품 정보를 찾을 수 없습니다."); // 컨트롤러에서 처리하는 것이 더 일반적
        print("Product not found: $productId");
        return null;
      }
    } on FirebaseException catch (e) {
      print(
          "Firestore Error fetching product $productId: ${e.code} - ${e.message}");
      Get.snackbar(
        "데이터 로딩 실패",
        "상품 정보를 불러오는 중 오류가 발생했습니다.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
      );
      return null;
    } catch (e) {
      print("Unexpected Error fetching product $productId: $e");
      Get.snackbar(
        "알 수 없는 오류",
        "상품 정보 로딩 중 예상치 못한 오류가 발생했습니다.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
      );
      return null;
    }
  }

  // 상품 리뷰 가져오기
  Future<List<ReviewModel>> getProductReviews(String productId,
      {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting product reviews: $e');
      return [];
    }
  }

  // 연관 상품 가져오기
  Future<List<ProductModel>> getRelatedProducts(ProductModel product,
      {int limit = 6}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('category',
              isEqualTo: product.category.toString().split('.').last)
          .where(FieldPath.documentId, isNotEqualTo: product.id)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting related products: $e');
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

      QuerySnapshot nameSnapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: keyword)
          .where('name', isLessThanOrEqualTo: keyword + '\uf8ff')
          .limit(limit)
          .get();

      QuerySnapshot tagSnapshot = await _firestore
          .collection('products')
          .where('tags', arrayContains: keyword)
          .limit(limit)
          .get();

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
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('상품 목록 조회 중 오류: $e');
      return [];
    }
  }
}
