import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import 'auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/custom_loading.dart'; // 로딩 인디케이터 사용

class ProductController extends GetxController {
  final ProductService _productService = ProductService();
  final WishlistService _wishlistService = WishlistService();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var featuredProducts = <ProductModel>[].obs; // 추천 상품 목록 (예시)
  var currentProduct = Rxn<ProductModel>(); // 현재 보고 있는 상품 상세 정보

  // 상품 관련 상태 변수
  Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  RxList<ProductModel> ecoProducts = <ProductModel>[].obs;
  RxList<ProductModel> newProducts = <ProductModel>[].obs;
  RxList<ProductModel> categoryProducts = <ProductModel>[].obs;
  RxList<ProductModel> relatedProducts = <ProductModel>[].obs;
  RxList<ProductModel> searchResults = <ProductModel>[].obs;
  RxList<ProductModel> products = <ProductModel>[].obs;

  // 리뷰 관련 상태 변수
  RxList<ReviewModel> productReviews = <ReviewModel>[].obs;

  // 로딩 및 찜하기 상태
  RxBool isLoading = false.obs;
  RxBool isLoadingReviews = false.obs;
  RxBool isWishlisted = false.obs;
  RxSet<String> favoriteProductIds = <String>{}.obs;

  // 정렬 및 필터 옵션
  RxString sortBy = '인기순'.obs;
  RxBool sortDescending = true.obs;
  final List<String> sortOptions = ['인기순', '신상품순', '낮은가격순', '높은가격순'];

  final filterOrganic = false.obs;
  final filterEcoFriendly = false.obs;
  final selectedCategory = ''.obs;
  final searchQuery = ''.obs;

  int page = 1;

  // --- 페이지네이션 상태 변수 ---
  var paginatedProducts = <ProductModel>[].obs; // 화면에 표시될 상품 리스트
  var isMoreLoading = false.obs; // 추가 로딩 상태 (스크롤 맨 아래)
  var hasMore = true.obs; // 더 불러올 데이터가 있는지 여부
  DocumentSnapshot? _lastDocument; // 마지막으로 로드된 문서 (다음 페이지 요청 시 사용)
  final int _limit = 10; // 페이지당 아이템 수
  String? currentCategoryId; // 현재 필터링 중인 카테고리 ID (선택 사항)

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

  // 홈페이지 상품 로드 (인기, 친환경, 카테고리별 일부 상품)
  Future<void> loadHomePageProducts() async {
    isLoading.value = true;
    try {
      final futures = await Future.wait([
        _productService.getPopularProducts(),
        _productService.getEcoProducts(),
        _productService.getProductsByCategory(ProductCategory.food, limit: 6),
      ]);
      popularProducts.value = futures[0];
      ecoProducts.value = futures[1];
      newProducts.value = futures[2];
    } catch (e) {
      print('Error loading home page products: $e');
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
        if (_authController.firebaseUser.value != null) {
          isWishlisted.value = await _wishlistService.isProductInWishlist(
              _authController.firebaseUser.value!.uid, productId);
        }
        loadProductReviews(productId);
        loadRelatedProducts(product);
      }
    } catch (e) {
      print('Error loading product details: $e');
      Get.snackbar(
        '오류',
        '상품 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 상품 리뷰 로드
  Future<void> loadProductReviews(String productId) async {
    isLoadingReviews.value = true;
    try {
      final reviews = await _productService.getProductReviews(productId);
      productReviews.value = reviews;
    } catch (e) {
      print('Error loading product reviews: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  // 연관 상품 로드
  Future<void> loadRelatedProducts(ProductModel product) async {
    try {
      final products = await _productService.getRelatedProducts(product);
      relatedProducts.value = products;
    } catch (e) {
      print('Error loading related products: $e');
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
      print('Error loading category products: $e');
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
  Future<void> searchProducts(String keyword) async {
    isLoading.value = true;
    try {
      if (keyword.isEmpty) {
        searchResults.value = await _productService.getPopularProducts();
      } else {
        searchResults.value = await _productService.searchProducts(keyword);
      }
    } catch (e) {
      print('Error searching products: $e');
      Get.snackbar(
        '오류',
        '상품 검색 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
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
      if (isWishlisted.value) {
        // 찜 목록에서 제거 (WishlistService 구현에 따라 처리)
        isWishlisted.value = false;
        Get.snackbar(
          '알림',
          '${product.name}이(가) 찜 목록에서 제거되었습니다.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        await _wishlistService.addToWishlist(
          _authController.firebaseUser.value!.uid,
          product,
        );
        isWishlisted.value = true;
      }
    } catch (e) {
      print('Error toggling wishlist: $e');
      Get.snackbar(
        '오류',
        '찜하기 처리 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // 스크롤 리스너 함수
  void _scrollListener() {
    // 현재 스크롤 위치가 최대 스크롤 가능 범위의 80% 이상일 때 + 추가 로딩 중이 아닐 때 + 더 로드할 데이터가 있을 때
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8 &&
        !isMoreLoading.value &&
        hasMore.value) {
      fetchMoreProducts();
    }
  }

  // 초기 상품 데이터 로드 (첫 페이지)
  Future<void> fetchInitialProducts({String? categoryId}) async {
    if (isLoading.value) return; // 중복 로딩 방지

    isLoading.value = true;
    currentCategoryId = categoryId; // 현재 카테고리 설정
    _lastDocument = null; // 초기화 시 마지막 문서 null로 설정
    hasMore.value = true; // 초기에는 더 있다고 가정
    paginatedProducts.clear(); // 기존 목록 초기화

    try {
      List<ProductModel> initialProducts =
          await _productService.fetchProductsPaginated(
        limit: _limit,
        categoryId: currentCategoryId, // 카테고리 필터 적용
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
      print("Error fetching initial products in controller: $e");
      // Service에서 SnackBar를 이미 표시했을 수 있음
    } finally {
      isLoading.value = false;
    }
  }

  // 추가 상품 데이터 로드 (다음 페이지)
  Future<void> fetchMoreProducts() async {
    // 추가 로딩 중이거나, 더 이상 데이터가 없거나, 마지막 문서 정보가 없으면 실행 안 함
    if (isMoreLoading.value || !hasMore.value || _lastDocument == null) return;

    isMoreLoading.value = true;

    try {
      List<ProductModel> moreProducts =
          await _productService.fetchProductsPaginated(
        limit: _limit,
        startAfterDoc: _lastDocument, // 마지막 문서 기준으로 다음 데이터 요청
        categoryId: currentCategoryId, // 동일한 카테고리 필터 유지
      );

      if (moreProducts.isNotEmpty) {
        _lastDocument =
            await _productService.getProductDocument(moreProducts.last.id);
        paginatedProducts.addAll(moreProducts); // 기존 리스트에 추가
      }

      if (moreProducts.length < _limit) {
        hasMore.value = false; // 마지막 페이지 도달
      }
    } catch (e) {
      print("Error fetching more products in controller: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  // 검색 또는 필터 변경 시 호출될 수 있는 함수 (페이지네이션 초기화 필요)
  void applyFilterOrSearch(String? newCategoryId) {
    // 새로운 필터(예: 카테고리)로 초기 데이터 다시 로드
    fetchInitialProducts(categoryId: newCategoryId);
  }

  // 상품 상세 화면 초기화 (화면 종료 시)
  void clearProductDetails() {
    selectedProduct.value = null;
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
    loadProducts(refresh: true);
  }

  // 카테고리 필터 적용
  void applyCategoryFilter(ProductCategory category) {
    categoryProducts.value = categoryProducts
        .where((product) => product.category == category)
        .toList();
  }

  // 가격 필터 적용
  void applyPriceFilter(double minPrice, double maxPrice) {
    categoryProducts.value = categoryProducts
        .where((product) =>
            product.sellingPrice >= minPrice &&
            product.sellingPrice <= maxPrice)
        .toList();
  }

  // 평점 필터 적용
  void applyRatingFilter(double minRating) {
    categoryProducts.value = categoryProducts
        .where((product) => product.averageRating >= minRating)
        .toList();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        page = 1;
        products.clear();
      }
      isLoading.value = true;

      final query = _firestore
          .collection('products')
          .where('isOrganic', isEqualTo: filterOrganic.value)
          .where('isEcoFriendly', isEqualTo: filterEcoFriendly.value);

      if (selectedCategory.value.isNotEmpty) {
        query.where('category', isEqualTo: selectedCategory.value);
      }

      if (searchQuery.value.isNotEmpty) {
        query
            .where('name', isGreaterThanOrEqualTo: searchQuery.value)
            .where('name', isLessThan: searchQuery.value + 'z');
      }

      final snapshot = await query.get();
      final newProducts =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      products.addAll(newProducts);
      page++;
    } catch (e) {
      print('상품 로드 중 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFavorite(String productId) {
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
    } else {
      favoriteProductIds.add(productId);
    }
  }

  // 전체 상품 목록 로딩 (Service의 에러 처리에 의존)
  Future<void> fetchAllProducts() async {
    try {
      isLoading.value = true;
      // CustomLoading.showLoading(); // 필요하다면 전체 화면 로딩 표시
      products.assignAll(await _productService.fetchProducts());
    } catch (e) {
      // Service에서 이미 SnackBar를 보여줬을 수 있음.
      // Controller 레벨에서 추가 처리가 필요하다면 여기에 작성
      print("Error in ProductController fetchAllProducts: $e");
    } finally {
      isLoading.value = false;
      // CustomLoading.hideLoading(); // 전체 화면 로딩 숨김
    }
  }

  // 상품 ID로 상세 정보 로딩
  Future<void> fetchProductDetails(String productId) async {
    try {
      isLoading.value = true; // 상세 화면 자체 로딩 상태 관리 가능
      currentProduct.value = await _productService.fetchProductById(productId);
      if (currentProduct.value == null) {
        // Service에서 상품 없음을 처리하지 않았다면 여기서 처리
        Get.snackbar("알림", "상품 정보를 찾을 수 없습니다.");
        // 필요시 이전 화면으로 돌아가기 Get.back();
      }
    } catch (e) {
      print("Error in ProductController fetchProductDetails: $e");
      // Service에서 스낵바를 보여줬으므로 여기서는 추가 로깅 외엔 생략 가능
    } finally {
      isLoading.value = false;
    }
  }
}
