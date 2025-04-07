import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:math' show min;

import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import '../../utils/format_helper.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final AuthController _authController = Get.find<AuthController>();
  final ProductController productController = Get.find<ProductController>();
  final CartController _cartController = Get.find<CartController>();

  late TabController _tabController;

  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  int _quantity = 1;
  String? _selectedOptionId;
  ProductOption? _selectedOption;
  bool _isExpanded = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProductData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 상품 정보 로드
      _product = await _productService.getProduct(widget.productId);

      if (_product != null) {
        // 상품 리뷰 로드
        _reviews = await _productService.getProductReviews(widget.productId);

        // 연관 상품 로드
        _relatedProducts = await _productService.getRelatedProducts(_product!);

        // 이미지 프리로딩
        _preloadImages(_product!.images);

        // 위시리스트 상태 체크
        if (_authController.firebaseUser.value != null) {
          productController.isWishlisted.value = await _checkWishlistStatus();
        }

        // 기본 옵션 설정 (옵션이 있는 경우)
        if (_product!.options != null && _product!.options!.isNotEmpty) {
          final options = _product!.options!;
          final firstOptionKey = options.keys.first;
          setState(() {
            _selectedOptionId = firstOptionKey;
            _selectedOption =
                ProductOption.fromMap(options[firstOptionKey], firstOptionKey);
          });
        }
      }
    } catch (e) {
      print('Error loading product data: $e');
      Get.snackbar(
        '오류',
        '상품 정보를 불러오는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkWishlistStatus() async {
    try {
      if (_authController.firebaseUser.value == null || _product == null) {
        return false;
      }
      return await productController.isProductWishlisted(widget.productId);
    } catch (e) {
      print('위시리스트 상태 확인 중 오류: $e');
      return false;
    }
  }

  void _preloadImages(List<String> urls) {
    for (var url in urls) {
      precacheImage(NetworkImage(url), context);
    }
  }

  void _buyNow() async {
    if (_product == null) return;

    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '구매를 진행하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // 장바구니에 상품 추가 후 바로 결제 화면으로 이동
      await _cartController.addToCart(
          _product!, _quantity, _selectedOption?.id);

      // 옵션 정보를 포함한 CartItemModel 생성
      final cartItem = CartItemModel(
        id: '${_product!.id}${_selectedOptionId ?? ""}',
        productId: _product!.id,
        productName: _product!.name,
        price: _getActualPrice(),
        quantity: _quantity,
        productImage:
            _product!.images.isNotEmpty ? _product!.images.first : null,
        selectedOptions: _selectedOption != null
            ? {
                'id': _selectedOption!.id,
                'name': _selectedOption!.name,
                'additionalPrice': _selectedOption!.additionalPrice,
              }
            : null,
        addedAt: DateTime.now(),
      );

      Get.to(() => CheckoutScreen(cartItems: [cartItem]));
    } catch (e) {
      print('Error buying now: $e');
      Get.snackbar(
        '오류',
        '구매 진행 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _addToCart() async {
    if (_product == null) return;
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '장바구니에 추가하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _cartController.addToCart(
          _product!, _quantity, _selectedOption?.id);
      // 다이얼로그에 두 개의 선택 버튼 추가
      Get.dialog(
        AlertDialog(
          title: const Text('장바구니에 상품이 담겼습니다'),
          content: const Text('장바구니로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // 다이얼로그 닫기 → 계속 쇼핑
              child: const Text('쇼핑 계속하기'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => CartScreen());
              },
              child: const Text('장바구니 이동'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      Get.snackbar(
        '오류',
        '장바구니에 추가하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '상품 설명'),
            Tab(text: '배송 정보'),
            Tab(text: '상세 정보'),
            Tab(text: '리뷰'),
          ],
        ),
        SizedBox(
          height: 500,
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(child: _buildDescriptionTab()),
              SingleChildScrollView(child: _buildShippingInfoTab()),
              SingleChildScrollView(child: _buildSpecificationsTab()),
              SingleChildScrollView(child: _buildReviewsTab()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 설명',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 상품 설명 텍스트 (길이에 따라 더보기 버튼 표시)
          if (_product!.description.length > 200 && !_showFullDescription)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_product!.description.substring(0, 200)}...',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showFullDescription = true;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('더보기'),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              _product!.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

          const SizedBox(height: 24),

          // 설명 이미지가 있을 경우 표시
          if (_product!.descriptionImages.isNotEmpty) ...[
            const Text(
              '상품 상세 이미지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_product!.descriptionImages.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _product!.descriptionImages[index],
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.error_outline),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 24),

          // 연관 상품이 있을 경우 표시
          if (_relatedProducts.isNotEmpty) _buildRelatedProducts(),
        ],
      ),
    );
  }

  Widget _buildShippingInfoTab() {
    // 배송 정보가 없으면 기본 안내 메시지 표시
    if (_product!.shippingInfo == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('배송 정보가 없습니다.'),
        ),
      );
    }

    final shippingInfo = _product!.shippingInfo;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '배송 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 배송 유형 및 방법
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRowWithIcon(
                  icon: Icons.local_shipping,
                  label: '배송 방법',
                  value: shippingInfo.method == ShippingMethod.standardDelivery
                      ? '일반택배'
                      : '직접배송',
                ),
                const SizedBox(height: 16),
                _buildInfoRowWithIcon(
                  icon: Icons.access_time,
                  label: '배송 유형',
                  value: shippingInfo.type == ShippingType.sameDay
                      ? '오늘출발'
                      : '일반배송',
                ),
                const SizedBox(height: 16),
                _buildInfoRowWithIcon(
                  icon: Icons.attach_money,
                  label: '배송비',
                  value: shippingInfo.feeType == ShippingFeeType.free
                      ? '무료 배송'
                      : '${shippingInfo.feeAmount?.toStringAsFixed(0) ?? '0'}원',
                ),

                // 오늘출발 설정이 있는 경우 추가 정보 표시
                if (shippingInfo.type == ShippingType.sameDay &&
                    shippingInfo.sameDaySettings != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRowWithIcon(
                    icon: Icons.schedule,
                    label: '당일 출고 기준',
                    value:
                        '${shippingInfo.sameDaySettings!['cutoffTime'] ?? '13:00'} 이전 주문 시',
                    valueColor: AppTheme.primaryColor,
                  ),
                ],

                // 휴무일 정보
                if (shippingInfo.holidayDays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRowWithIcon(
                    icon: Icons.event_busy,
                    label: '배송 휴무일',
                    value: _getHolidayDaysText(shippingInfo.holidayDays),
                  ),
                ],

                // 출고지 정보가 있는 경우 표시
                if (shippingInfo.shippingOrigin != null &&
                    shippingInfo.shippingOrigin!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRowWithIcon(
                    icon: Icons.location_on,
                    label: '출고지',
                    value: shippingInfo.shippingOrigin!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 배송 안내 사항
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '배송 안내',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  '배송은 결제 완료 후 평균 1~3일 내에 출고됩니다.',
                ),
                _buildInfoItem(
                  '도서산간 지역은 추가 배송비가 발생할 수 있습니다.',
                ),
                _buildInfoItem(
                  shippingInfo.type == ShippingType.sameDay
                      ? '오늘출발 상품은 설정된 시간 이전에 결제 완료 시 당일 출고됩니다.'
                      : '배송 기간은 지역에 따라 차이가 있을 수 있습니다.',
                ),
                _buildInfoItem(
                  '배송 현황은 주문 내역에서 확인 가능합니다.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHolidayDaysText(List<int> holidayDays) {
    if (holidayDays.isEmpty) return '없음';

    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    List<String> days = [];

    for (int i = 0; i < 7; i++) {
      if (holidayDays.contains(i + 1)) {
        days.add(dayNames[i]);
      }
    }

    return days.join(', ');
  }

  Widget _buildInfoRowWithIcon({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 상세 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 상품 스펙 정보가 있는 경우
          if (_product!.specifications != null &&
              _product!.specifications!.isNotEmpty)
            Column(
              children: [
                ..._product!.specifications!.entries.map((entry) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '상세 스펙 정보가 없습니다.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 상품 태그 정보
          if (_product!.tags != null && _product!.tags!.isNotEmpty) ...[
            const Text(
              '상품 태그',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _product!.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 평점 요약
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _product!.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingBar.builder(
                    initialRating: _product!.averageRating,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 24,
                    ignoreGestures: true,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {},
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 ${_product!.reviewCount}개의 리뷰',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),

          // 리뷰 목록
          if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 리뷰가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '첫 리뷰를 작성해보세요!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 리뷰 작성 화면으로 이동
                        Get.snackbar(
                          '알림',
                          '리뷰는 상품 구매 후 작성 가능합니다.',
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('리뷰 작성하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _reviews.map((review) {
                return _buildReviewItem(review);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 및 평점
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: review.userPhotoURL != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            review.userPhotoURL!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: review.userPhotoURL == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 사용자 이름 및 평점
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: review.rating.toDouble(),
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 16,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 구매 확인 배지
              if (review.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '구매 확인',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // 리뷰 내용
          Text(
            review.content ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          // 리뷰 이미지
          if (review.imageUrls != null && review.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls!.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: review.imageUrls![index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '연관 상품',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_relatedProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // 상품 상세 페이지로 이동 (현재 페이지 교체)
        Get.off(() => ProductDetailScreen(productId: product.id));
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: SizedBox(
                height: 180,
                width: 180,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            // 상품 정보
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품명
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 가격 정보
                  if (product.discountPrice != null) ...[
                    Text(
                      '${product.price.toStringAsFixed(0)}원',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    '${product.sellingPrice.toStringAsFixed(0)}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Obx(() => Icon(
                        productController.isWishlisted.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: productController.isWishlisted.value
                            ? Colors.red
                            : Colors.grey.shade600,
                      )),
                  onPressed: () => productController.toggleWishlist(_product!),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _product!.isInStock ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text(
                            '장바구니',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _product!.isInStock ? _buyNow : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text(
                            '바로 구매',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  double _getActualPrice() {
    if (_product == null) return 0;

    double basePrice = _product!.discountPrice ?? _product!.price;

    if (_selectedOption != null) {
      return basePrice + _selectedOption!.additionalPrice;
    }

    return basePrice;
  }

  bool _isOptionAvailable(String optionId) {
    if (_product?.options == null ||
        !_product!.options!.containsKey(optionId)) {
      return false;
    }

    final optionData = _product!.options![optionId];
    return (optionData['isAvailable'] ?? false) &&
        ((optionData['stockQuantity'] ?? 0) > 0);
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _isLoading
        ? '로딩 중...'
        : (_product == null ? '상품 정보 없음' : _product!.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Get.to(() => CartScreen()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _product == null
              ? _buildProductNotFound()
              : _buildProductDetail(),
    );
  }

  Widget _buildProductNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '상품을 찾을 수 없습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '해당 상품이 삭제되었거나 존재하지 않습니다.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('이전 페이지로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetail() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadProductData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageGallery(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductBasicInfo(),
                      const SizedBox(height: 16),
                      _buildCategoryAndOrigin(),
                      const SizedBox(height: 16),
                      _buildPriceSection(),
                      const SizedBox(height: 24),
                      if (_product!.options != null &&
                          _product!.options!.isNotEmpty)
                        _buildOptionsSection(),
                      const SizedBox(height: 16),
                      _buildQuantitySelector(),
                      const SizedBox(height: 24),
                      _buildDetailTabs(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            itemCount: _product!.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _product!.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey.shade400),
                ),
              );
            },
          ),
        ),
        if (_product!.images.length > 1)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _product!.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: CachedNetworkImage(
                        imageUrl: _product!.images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상품명
        Text(
          _product!.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 평점
        Row(
          children: [
            RatingBar.builder(
              initialRating: _product!.averageRating,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 20,
              ignoreGestures: true,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {},
            ),
            const SizedBox(width: 8),
            Text(
              '${_product!.averageRating.toStringAsFixed(1)} (${_product!.reviewCount})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 태그 및 라벨
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_product!.isEco)
              _buildTag(
                label: '친환경',
                color: Colors.green,
                icon: Icons.eco,
              ),
            if (_product!.isOrganic)
              _buildTag(
                label: '유기농',
                color: Colors.teal,
                icon: Icons.spa,
              ),

            // 오늘 출발 가능 여부
            if (_product!.shippingInfo.type == ShippingType.sameDay)
              _buildTag(
                label: '오늘출발',
                color: Colors.blue,
                icon: Icons.local_shipping,
              ),

            // 배송비 무료 여부
            if (_product!.shippingInfo.feeType == ShippingFeeType.free)
              _buildTag(
                label: '무료배송',
                color: Colors.purple,
                icon: Icons.card_giftcard,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndOrigin() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: '카테고리',
            value: _product!.categoryName,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: '원산지',
            value: _product!.origin,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: '부가세 유형',
            value: _product!.taxTypeName,
          ),
          if (_product!.isEco && _product!.ecoLabels != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '친환경 인증',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _product!.ecoLabels!.map((label) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_product!.discountPrice != null &&
            _product!.discountPrice! < _product!.price)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 할인율
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _product!.discountPercentage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 원가
                  Text(
                    FormatHelper.formatPrice(_product!.price),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),

        // 현재 선택된 가격 (옵션 포함)
        Text(
          FormatHelper.formatPrice(_getActualPrice()),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        if (_selectedOption != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '(${_product!.sellingPrice.toStringAsFixed(0)}원 + 옵션 ${_selectedOption!.additionalPrice.toStringAsFixed(0)}원)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '옵션 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ExpansionTile(
              title: Text(
                _selectedOption?.name ?? '옵션 선택',
                style: TextStyle(
                  color: _selectedOption == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                  fontWeight: _selectedOption == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: _selectedOption != null
                  ? Text(
                      '+${_selectedOption!.additionalPrice.toStringAsFixed(0)}원',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
              children: _buildOptionItems(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptionItems() {
    if (_product?.options == null) return [];

    List<Widget> optionWidgets = [];

    _product!.options!.forEach((optionId, optionData) {
      final option = ProductOption.fromMap(optionData, optionId);
      final isAvailable = _isOptionAvailable(optionId);

      optionWidgets.add(
        ListTile(
          title: Text(
            option.name,
            style: TextStyle(
              color: isAvailable ? Colors.black87 : Colors.grey.shade400,
              decoration: isAvailable ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text(
            isAvailable
                ? '${option.additionalPrice > 0 ? '+' : ''}${option.additionalPrice.toStringAsFixed(0)}원 (재고: ${option.stockQuantity}개)'
                : '품절',
            style: TextStyle(
              color: isAvailable
                  ? option.additionalPrice > 0
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600
                  : Colors.grey.shade400,
            ),
          ),
          trailing: _selectedOptionId == optionId
              ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
              : null,
          enabled: isAvailable,
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedOptionId = optionId;
                    _selectedOption = option;
                  });
                }
              : null,
        ),
      );

      // 구분선 추가 (마지막 항목 제외)
      if (optionId != _product!.options!.keys.last) {
        optionWidgets.add(const Divider(height: 1));
      }
    });

    return optionWidgets;
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '구매수량',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 상품금액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                FormatHelper.formatPrice(_getActualPrice() * _quantity),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
