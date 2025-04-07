// lib/controllers/product_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/cart_item_model.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/custom_loading.dart';

class ProductController extends GetxController {
  final ProductService _productService = ProductService();
  final WishlistService _wishlistService = WishlistService();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 상품 관련 상태 변수
  var currentProduct = Rxn<ProductModel>(); // 현재 보고 있는 상품 상세 정보
  var selectedProduct = Rxn<ProductModel>(); // 선택된 상품

  // 상품 목록 변수
  RxList<ProductModel> popularProducts = <ProductModel>[].obs; // 인기 상품
  RxList<ProductModel> featuredProducts = <ProductModel>[].obs; // 추천 상품
  RxList<ProductModel> ecoProducts = <ProductModel>[].obs; // 친환경 상품
  RxList<ProductModel> newProducts = <ProductModel>[].obs; // 신상품
  RxList<ProductModel> categoryProducts = <ProductModel>[].obs; // 카테고리별 상품
  RxList<ProductModel> relatedProducts = <ProductModel>[].obs; // 연관 상품
  RxList<ProductModel> searchResults = <ProductModel>[].obs; // 검색 결과
  RxList<ProductModel> products = <ProductModel>[].obs; // 전체 상품 목록

  // 리뷰 관련 상태 변수
  RxList<ReviewModel> productReviews = <ReviewModel>[].obs;

  // 로딩 및 찜하기 상태
  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool isLoadingReviews = false.obs;
  RxBool isWishlisted = false.obs;
  RxSet<String> favoriteProductIds = <String>{}.obs;

  // 정렬 및 필터 옵션
  RxString sortBy = '인기순'.obs;
  RxBool sortDescending = true.obs;
  final List<String> sortOptions = ['인기순', '신상품순', '낮은가격순', '높은가격순'];

  // 필터링 상태
  final filterOrganic = false.obs;
  final filterEcoFriendly = false.obs;
  final selectedCategory = ''.obs;
  final searchQuery = ''.obs;

  // 페이지네이션 상태 변수
  var paginatedProducts = <ProductModel>[].obs; // 화면에 표시될 상품 리스트
  var hasMore = true.obs; // 더 불러올 데이터가 있는지 여부
  DocumentSnapshot? _lastDocument; // 마지막으로 로드된 문서 (다음 페이지 요청 시 사용)
  final int _limit = 10; // 페이지당 아이템 수
  RxString currentCategoryId = ''.obs; // 현재 필터링 중인 카테고리 ID
  RxInt page = 1.obs; // 현재 페이지

  // 스크롤 감지를 위한 컨트롤러
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadHomePageProducts();
    loadProducts();
    // 스크롤 리스너 추가: 스크롤이 맨 아래 근처로 오면 추가 데이터 로드
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  // 홈페이지 상품 로드 (인기, 친환경, 신상품, 추천 상품)
  Future<void> loadHomePageProducts() async {
    isLoading.value = true;
    try {
      final futures = await Future.wait([
        _productService.getPopularProducts(),
        _productService.getEcoProducts(),
        _productService.getNewProducts(),
        _productService.getFeaturedProducts(),
      ]);

      popularProducts.value = futures[0];
      ecoProducts.value = futures[1];
      newProducts.value = futures[2];
      featuredProducts.value = futures[3];
    } catch (e) {
      print('홈페이지 상품 로드 오류: $e');
      Get.snackbar(
        '오류',
        '상품을 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 상품 상세 로드
  Future<void> loadProductDetails(String productId) async {
    isLoading.value = true;
    try {
      final product = await _productService.getProduct(productId);
      if (product != null) {
        selectedProduct.value = product;
        currentProduct.value = product;

        // 위시리스트 상태 확인
        if (_authController.firebaseUser.value != null) {
          isWishlisted.value = await isProductWishlisted(productId);
        }

        // 리뷰 및 연관 상품 로드
        loadProductReviews(productId);
        loadRelatedProducts(product);
      }
    } catch (e) {
      print('상품 상세 로드 오류: $e');
      Get.snackbar(
        '오류',
        '상품 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 상품이 위시리스트에 있는지 확인
  Future<bool> isProductWishlisted(String productId) async {
    try {
      if (_authController.firebaseUser.value == null) {
        return false;
      }
      return await _productService.isProductInWishlist(
        _authController.firebaseUser.value!.uid,
        productId,
      );
    } catch (e) {
      print('위시리스트 상태 확인 오류: $e');
      return false;
    }
  }

  // 상품 리뷰 로드
  Future<void> loadProductReviews(String productId) async {
    isLoadingReviews.value = true;
    try {
      final reviews = await _productService.getProductReviews(productId);
      productReviews.value = reviews;
    } catch (e) {
      print('상품 리뷰 로드 오류: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  // 연관 상품 로드
  Future<void> loadRelatedProducts(ProductModel product) async {
    try {
      final related = await _productService.getRelatedProducts(product);
      relatedProducts.value = related;
    } catch (e) {
      print('연관 상품 로드 오류: $e');
    }
  }

  // 카테고리별 상품 로드
  Future<void> loadCategoryProducts(ProductCategory category) async {
    isLoading.value = true;
    try {
      final products = await _productService.getProductsByCategory(category);
      categoryProducts.value = products;
      sortCategoryProducts();
    } catch (e) {
      print('카테고리별 상품 로드 오류: $e');
      Get.snackbar(
        '오류',
        '카테고리 상품을 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 정렬 옵션 변경 및 적용
  void changeSortOption(String option) {
    sortBy.value = option;
    sortCategoryProducts();
  }

  // 카테고리 상품 정렬
  void sortCategoryProducts() {
    switch (sortBy.value) {
      case '인기순':
        categoryProducts
            .sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case '신상품순':
        categoryProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '낮은가격순':
        categoryProducts
            .sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case '높은가격순':
        categoryProducts
            .sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
    }
  }

  // 상품 검색
  Future<List<ProductModel>> searchProducts(String keyword,
      {int limit = 20}) async {
    try {
      final trimmedKeyword = keyword.trim();
      if (trimmedKeyword.isEmpty) {
        return await _productService.getPopularProducts(limit: limit);
      }

      Query query =
          _firestore.collection('products').where('isActive', isEqualTo: true);

      // 'name' 필드를 기준으로 범위 쿼리 실행
      query = query
          .where('name', isGreaterThanOrEqualTo: trimmedKeyword)
          .where('name', isLessThanOrEqualTo: trimmedKeyword + '\uf8ff')
          .limit(limit);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      _handleFirebaseError(e, '상품 검색 중 오류가 발생했습니다.');
      return [];
    } catch (e) {
      _handleGenericError(e, '상품 검색 중 예상치 못한 오류가 발생했습니다.');
      return [];
    }
  }

  void _handleFirebaseError(FirebaseException e, String message) {
    // Firebase 오류 로그 출력
    print('Firebase 오류: ${e.code} - ${e.message}');

    // 사용자에게 스낵바로 에러 메시지 표시
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
    // 일반 오류 로그 출력
    print('일반 오류: $e');

    // 사용자에게 스낵바로 에러 메시지 표시
    Get.snackbar(
      '오류',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red.shade700,
      duration: const Duration(seconds: 3),
    );
  }

  // 찜하기 토글
  Future<void> toggleWishlist(ProductModel product) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '찜하기를 이용하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      LoadingOverlay.show(Get.context!);

      final userId = _authController.firebaseUser.value!.uid;

      if (isWishlisted.value) {
        // 찜 목록에서 제거
        final success =
            await _productService.removeFromWishlist(userId, product.id);
        if (success) {
          isWishlisted.value = false;
          favoriteProductIds.remove(product.id);
        }
      } else {
        // 찜 목록에 추가
        final success = await _productService.addToWishlist(userId, product);
        if (success) {
          isWishlisted.value = true;
          favoriteProductIds.add(product.id);
        }
      }
    } catch (e) {
      print('찜하기 토글 오류: $e');
      Get.snackbar(
        '오류',
        '찜하기 처리 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      LoadingOverlay.hide();
    }
  }

  // 스크롤 리스너 함수
  void _scrollListener() {
    // 현재 스크롤 위치가 최대 스크롤 가능 범위의 80% 이상일 때 + 추가 로딩 중이 아닐 때 + 더 로드할 데이터가 있을 때
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8 &&
        !isLoadingMore.value &&
        hasMore.value) {
      fetchMoreProducts();
    }
  }

  // 초기 상품 데이터 로드 (첫 페이지)
  Future<void> fetchInitialProducts({
    String? categoryId,
    String? searchKeyword,
    bool? isEco,
    bool? isOrganic,
    String? sortField,
    bool descending = true,
  }) async {
    if (isLoading.value) return; // 중복 로딩 방지

    isLoading.value = true;
    currentCategoryId.value = categoryId ?? ''; // 현재 카테고리 설정
    _lastDocument = null; // 초기화 시 마지막 문서 null로 설정
    hasMore.value = true; // 초기에는 더 있다고 가정
    paginatedProducts.clear(); // 기존 목록 초기화
    page.value = 1; // 페이지 초기화

    try {
      List<ProductModel> initialProducts =
          await _productService.fetchProductsPaginated(
        limit: _limit,
        categoryId: categoryId,
        searchKeyword: searchKeyword,
        isEco: isEco,
        isOrganic: isOrganic,
        sortBy: sortField,
        descending: descending,
      );

      if (initialProducts.isNotEmpty) {
        // 마지막 문서 스냅샷 저장 (다음 페이지 요청에 사용)
        _lastDocument =
            await _productService.getProductDocument(initialProducts.last.id);
      }

      if (initialProducts.length < _limit) {
        hasMore.value = false; // 가져온 개수가 limit보다 작으면 더 이상 데이터 없음
      }

      paginatedProducts.assignAll(initialProducts); // UI 업데이트
    } catch (e) {
      print("초기 상품 로드 오류: $e");
      // 이미 productService에서 오류 메시지를 표시했을 것임
    } finally {
      isLoading.value = false;
    }
  }

  // 추가 상품 데이터 로드 (다음 페이지)
  Future<void> fetchMoreProducts() async {
    // 추가 로딩 중이거나, 더 이상 데이터가 없거나, 마지막 문서 정보가 없으면 실행 안 함
    if (isLoadingMore.value || !hasMore.value || _lastDocument == null) return;

    isLoadingMore.value = true;

    try {
      List<ProductModel> moreProducts =
          await _productService.fetchProductsPaginated(
        limit: _limit,
        startAfterDoc: _lastDocument,
        categoryId:
            currentCategoryId.value.isEmpty ? null : currentCategoryId.value,
        sortBy: _getSortField(),
        descending: sortDescending.value,
      );

      if (moreProducts.isNotEmpty) {
        _lastDocument =
            await _productService.getProductDocument(moreProducts.last.id);
        paginatedProducts.addAll(moreProducts); // 기존 리스트에 추가
        page.value++;
      }

      if (moreProducts.length < _limit) {
        hasMore.value = false; // 마지막 페이지 도달
      }
    } catch (e) {
      print("추가 상품 로드 오류: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  // 정렬 필드 변환 헬퍼 함수
  String? _getSortField() {
    switch (sortBy.value) {
      case '인기순':
        return 'averageRating';
      case '신상품순':
        return 'createdAt';
      case '낮은가격순':
        sortDescending.value = false;
        return 'sellingPrice';
      case '높은가격순':
        sortDescending.value = true;
        return 'sellingPrice';
      default:
        return 'createdAt';
    }
  }

  // 검색 또는 필터 변경 시 호출될 수 있는 함수 (페이지네이션 초기화 필요)
  void applyFilterOrSearch({
    String? newCategoryId,
    String? searchKeyword,
    bool? isEco,
    bool? isOrganic,
  }) {
    // 정렬 필드 및 방향 설정
    String? sortField = _getSortField();
    bool descending = sortDescending.value;

    // 새로운 필터로 초기 데이터 다시 로드
    fetchInitialProducts(
      categoryId: newCategoryId,
      searchKeyword: searchKeyword,
      isEco: isEco,
      isOrganic: isOrganic,
      sortField: sortField,
      descending: descending,
    );
  }

  // 상품 상세 화면 초기화 (화면 종료 시)
  void clearProductDetails() {
    selectedProduct.value = null;
    currentProduct.value = null;
    productReviews.clear();
    relatedProducts.clear();
    isWishlisted.value = false;
  }

  // 필터 초기화
  void resetFilters() {
    filterOrganic.value = false;
    filterEcoFriendly.value = false;
    selectedCategory.value = '';
    searchQuery.value = '';
    sortBy.value = '인기순';
    sortDescending.value = true;
    applyFilterOrSearch();
  }

  // 리뷰 작성
  Future<bool> addReview({
    required String productId,
    required String content,
    required int rating,
    List<String>? imageUrls,
  }) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '리뷰를 작성하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    try {
      LoadingOverlay.show(Get.context!);

      final userId = _authController.firebaseUser.value!.uid;
      final userName =
          _authController.firebaseUser.value?.displayName ?? '익명 사용자';
      final userPhotoURL = _authController.firebaseUser.value?.photoURL;

      bool success = await _productService.addReview(
        userId: userId,
        productId: productId,
        userName: userName,
        userPhotoURL: userPhotoURL,
        content: content,
        rating: rating,
        imageUrls: imageUrls,
        // TODO: 실제 구매 확인 로직 구현
        isVerifiedPurchase: true,
      );

      if (success) {
        // 리뷰 목록 새로고침
        await loadProductReviews(productId);

        // 상품 정보 갱신 (평점 반영)
        await loadProductDetails(productId);
      }

      return success;
    } catch (e) {
      print('리뷰 작성 오류: $e');
      Get.snackbar(
        '오류',
        '리뷰 작성 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      LoadingOverlay.hide();
    }
  }

  // 모든 상품 로드 (단순 목록용)
  Future<void> loadProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        page.value = 1;
        products.clear();
      }

      isLoading.value = true;

      final newProducts = await _productService.fetchProducts();
      products.addAll(newProducts);

      page.value++;
    } catch (e) {
      print('상품 로드 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 찜 상태 토글 간소화 버전 (아이디 기반)
  void toggleFavorite(String productId) {
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
    } else {
      favoriteProductIds.add(productId);
    }
  }

  // 카테고리별 상품 필터링 (Firestore 쿼리 없이 로컬에서)
  void filterByCategory(ProductCategory category) {
    categoryProducts.value =
        products.where((product) => product.category == category).toList();
  }

  // 가격 범위 필터링 (로컬)
  void filterByPriceRange(double minPrice, double maxPrice) {
    categoryProducts.value = categoryProducts
        .where((product) =>
            product.sellingPrice >= minPrice &&
            product.sellingPrice <= maxPrice)
        .toList();
  }

  // 상품 정렬 (로컬)
  void sortProducts(String sortOption) {
    sortBy.value = sortOption;

    switch (sortOption) {
      case '인기순':
        products.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case '신상품순':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '낮은가격순':
        products.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case '높은가격순':
        products.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
    }
  }

  // 리뷰 평점 필터링 (Firestore 쿼리 없이 로컬에서)
  void filterByRating(double minRating) {
    categoryProducts.value = categoryProducts
        .where((product) => product.averageRating >= minRating)
        .toList();
  }
}
