import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';
import '../controllers/auth_controller.dart';

class ReviewController extends GetxController {
  final ReviewService _reviewService = ReviewService();
  final AuthController _authController = Get.find<AuthController>();

  // 리뷰 목록 관련 변수
  final RxList<ReviewModel> productReviews = <ReviewModel>[].obs;
  final RxList<ReviewModel> userReviews = <ReviewModel>[].obs;
  final RxList<Map<String, dynamic>> reviewableProducts =
      <Map<String, dynamic>>[].obs;

  // 리뷰 상세 정보
  final Rx<ReviewModel?> selectedReview = Rx<ReviewModel?>(null);

  // 로딩 상태
  final RxBool isLoadingProductReviews = false.obs;
  final RxBool isLoadingUserReviews = false.obs;
  final RxBool isLoadingReviewableProducts = false.obs;
  final RxBool isSubmittingReview = false.obs;

  // 통계 정보
  final RxDouble averageRating = 0.0.obs;
  final RxInt reviewCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // 사용자가 로그인한 경우 리뷰 작성 가능한 상품 목록 로드
    if (_authController.isLoggedIn.value) {
      loadReviewableProducts();
    }

    // 사용자 로그인 상태 변경시 리뷰 작성 가능 상품 목록 갱신
    ever(_authController.isLoggedIn, (isLoggedIn) {
      if (isLoggedIn) {
        loadReviewableProducts();
      } else {
        reviewableProducts.clear();
      }
    });
  }

  // 상품 리뷰 목록 로드
  Future<void> loadProductReviews(String productId) async {
    isLoadingProductReviews.value = true;
    try {
      final reviews = await _reviewService.getProductReviews(productId);
      productReviews.assignAll(reviews);

      // 통계 정보 계산
      if (reviews.isNotEmpty) {
        double totalRating = 0;
        for (var review in reviews) {
          totalRating += review.rating;
        }
        averageRating.value = totalRating / reviews.length;
        reviewCount.value = reviews.length;
      } else {
        averageRating.value = 0;
        reviewCount.value = 0;
      }
    } catch (e) {
      print('상품 리뷰 로드 오류: $e');
      Get.snackbar(
        '오류',
        '리뷰를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingProductReviews.value = false;
    }
  }

  // 사용자 리뷰 목록 로드
  Future<void> loadUserReviews() async {
    if (_authController.firebaseUser.value == null) return;

    isLoadingUserReviews.value = true;
    try {
      final reviews = await _reviewService
          .getUserReviews(_authController.firebaseUser.value!.uid);
      userReviews.assignAll(reviews);
    } catch (e) {
      print('사용자 리뷰 로드 오류: $e');
      Get.snackbar(
        '오류',
        '리뷰를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingUserReviews.value = false;
    }
  }

  // 리뷰 작성 가능한 상품 목록 로드
  Future<void> loadReviewableProducts() async {
    if (_authController.firebaseUser.value == null) return;

    isLoadingReviewableProducts.value = true;
    try {
      final products = await _reviewService
          .getReviewableProducts(_authController.firebaseUser.value!.uid);
      reviewableProducts.assignAll(products);
    } catch (e) {
      print('리뷰 작성 가능 상품 로드 오류: $e');
    } finally {
      isLoadingReviewableProducts.value = false;
    }
  }

  // 별점만 등록하기
  Future<bool> submitRatingOnly({
    required String productId,
    required String productName,
    String? productImage,
    required String orderId,
    required double rating,
  }) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '리뷰 작성을 위해 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    isSubmittingReview.value = true;
    try {
      // 리뷰 작성 기한 계산 (배송 완료 후 90일)
      final now = DateTime.now();
      final reviewDeadline = now.add(const Duration(days: 90));

      // 리뷰 모델 생성
      final review = ReviewModel(
        id: '', // Firestore에서 자동 생성됨
        productId: productId,
        productName: productName,
        productImage: productImage,
        userId: _authController.firebaseUser.value!.uid,
        userName: _authController.userModel.value?.name ?? '익명',
        userPhotoURL: _authController.userModel.value?.photoURL,
        rating: rating,
        content: null,
        tags: null,
        imageUrls: null,
        createdAt: now,
        isVerifiedPurchase: true,
        orderId: orderId,
        deliveryDate: now.subtract(const Duration(days: 3)), // 예시값
        reviewDeadline: reviewDeadline,
        isDetailReview: false,
        reviewType: 'product',
      );

      // 리뷰 등록
      await _reviewService.addReview(review);

      // 데이터 갱신
      await loadReviewableProducts();
      if (productReviews.isNotEmpty) {
        await loadProductReviews(productId);
      }

      Get.snackbar(
        '별점 등록 완료',
        '별점이 성공적으로 등록되었습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      return true;
    } catch (e) {
      print('별점 등록 오류: $e');
      Get.snackbar(
        '오류',
        '별점을 등록하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isSubmittingReview.value = false;
    }
  }

  // 상세 리뷰 등록하기
  Future<bool> submitDetailReview({
    required String productId,
    required String productName,
    String? productImage,
    required String orderId,
    required double rating,
    required String content,
    List<String>? tags,
    List<XFile>? images,
  }) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '리뷰 작성을 위해 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    isSubmittingReview.value = true;
    try {
      // 이미지 업로드 (있는 경우)
      List<String>? imageUrls;
      if (images != null && images.isNotEmpty) {
        imageUrls = await _reviewService.uploadReviewImages(
          _authController.firebaseUser.value!.uid,
          images,
        );
      }

      // 리뷰 작성 기한 계산 (배송 완료 후 90일)
      final now = DateTime.now();
      final reviewDeadline = now.add(const Duration(days: 90));

      // 리뷰 모델 생성
      final review = ReviewModel(
        id: '', // Firestore에서 자동 생성됨
        productId: productId,
        productName: productName,
        productImage: productImage,
        userId: _authController.firebaseUser.value!.uid,
        userName: _authController.userModel.value?.name ?? '익명',
        userPhotoURL: _authController.userModel.value?.photoURL,
        rating: rating,
        content: content,
        tags: tags,
        imageUrls: imageUrls,
        createdAt: now,
        isVerifiedPurchase: true,
        orderId: orderId,
        deliveryDate: now.subtract(const Duration(days: 3)), // 예시값
        reviewDeadline: reviewDeadline,
        isDetailReview: true,
        reviewType: 'product',
      );

      // 리뷰 등록
      await _reviewService.addReview(review);

      // 데이터 갱신
      await loadReviewableProducts();
      if (productReviews.isNotEmpty) {
        await loadProductReviews(productId);
      }

      Get.snackbar(
        '리뷰 등록 완료',
        '상세 리뷰가 성공적으로 등록되었습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      return true;
    } catch (e) {
      print('상세 리뷰 등록 오류: $e');
      Get.snackbar(
        '오류',
        '리뷰를 등록하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isSubmittingReview.value = false;
    }
  }

  // 리뷰 도움됨 표시
  Future<void> markAsHelpful(String reviewId) async {
    try {
      await _reviewService.markReviewAsHelpful(reviewId);

      // 리뷰 목록 갱신
      final index =
          productReviews.indexWhere((review) => review.id == reviewId);
      if (index != -1) {
        final review = productReviews[index];
        productReviews[index] = review.copyWith(
          helpfulCount: review.helpfulCount + 1,
        );
      }

      Get.snackbar(
        '평가 완료',
        '리뷰가 도움이 되었다고 평가했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      print('리뷰 도움됨 표시 오류: $e');
    }
  }

  // 리뷰 삭제하기
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      await _reviewService.deleteReview(reviewId, productId);

      // 리뷰 목록에서 삭제
      productReviews.removeWhere((review) => review.id == reviewId);
      userReviews.removeWhere((review) => review.id == reviewId);

      // 리뷰 작성 가능 목록 갱신
      await loadReviewableProducts();

      Get.snackbar(
        '삭제 완료',
        '리뷰가 성공적으로 삭제되었습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      return true;
    } catch (e) {
      print('리뷰 삭제 오류: $e');
      Get.snackbar(
        '오류',
        '리뷰를 삭제하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }
}
