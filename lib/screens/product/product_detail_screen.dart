// lib/screens/product/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/product_controller.dart';
import 'package:flutter_login_template/models/cart_item_model.dart';
import 'package:flutter_login_template/screens/checkout/checkout_screen.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../utils/custom_loading.dart';
import '../cart/cart_screen.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/format_helper.dart';

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
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();
  final ProductController productController = Get.find<ProductController>();

  late TabController _tabController;

  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductData().then((_) {
      productController.loadProductDetails(widget.productId);
    });
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
        preloadImages(_product!.images);
      }
    } catch (e) {
      print('Error loading product data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      final cartController = Get.find<CartController>();
      // 장바구니에 상품 추가 후 바로 결제 화면으로 이동
      await cartController.addToCart(_product!, _quantity, null);

      // 추가한 아이템을 바로 가져옴
      final cartItem = CartItemModel(
        id: _product!.id,
        productId: _product!.id,
        productName: _product!.name,
        price: _product!.sellingPrice,
        quantity: _quantity,
        productImage: _product!.images.firstOrNull,
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
      final cartController = Get.find<CartController>();
      await cartController.addToCart(_product!, _quantity, null);

      // 장바구니로 이동할지 물어보기
      Get.dialog(
        AlertDialog(
          title: const Text('장바구니에 상품이 담겼습니다'),
          content: const Text('장바구니로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('쇼핑 계속하기'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.to(() => const CartScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('장바구니로 이동'),
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

  void _navigateToCart() {
    Get.to(() => const CartScreen());
  }

  @override
  Widget build(BuildContext context) {
    // AppBar의 title을 결정하는 로직을 분리하거나 삼항 연산자를 사용합니다.
    String appBarTitle;
    if (_isLoading) {
      appBarTitle = '로딩 중...'; // 로딩 중일 때 표시할 텍스트
    } else if (_product == null) {
      appBarTitle = '상품 정보 없음'; // 상품 정보가 없을 때 표시할 텍스트
    } else {
      // _product가 null이 아님이 확인되었으므로 ! 대신 . 사용 가능 (혹은 그대로 ! 사용)
      appBarTitle = _product!.name;
      // 또는 안전하게 접근: appBarTitle = _product.name;
    }

    return Scaffold(
      appBar: AppBar(
        // 결정된 appBarTitle을 사용합니다.
        title: Text(appBarTitle),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _product == null
              ? _buildProductNotFound()
              : _buildWebLayout(), // Scaffold 제거하고 바로 내용 반환
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
            child: const Text('이전 페이지로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              _buildImageGallery(false),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(),
                    const SizedBox(height: 24),
                    _buildQuantitySelector(),
                    const SizedBox(height: 32),
                    _buildDetailTabs(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 수량 선택 UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '구매수량',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                            icon: const Icon(Icons.remove, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_quantity < 99) {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            },
                            icon: const Icon(Icons.add, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 총 상품 금액
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 상품 금액',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        FormatHelper.formatPrice(
                            _product!.sellingPrice * _quantity),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 장바구니 버튼
                  Row(
                    children: [
                      Container(
                          width: 48,
                          height: 48,
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
                                  color: Colors.red,
                                )),
                            onPressed: () =>
                                productController.toggleWishlist(_product!),
                          )),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      _product!.isInStock ? _addToCart : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('장바구니에 담기'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      _product!.isInStock ? _buyNow : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('바로 구매'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Image.network(
            _product!.images[_currentImageIndex],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.image_not_supported,
                    color: Colors.grey.shade400),
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
                    ),
                    child: Image.network(
                      _product!.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리
        Text(
          _product!.categoryName,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 상품명
        Text(
          _product!.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 평점
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _product!.averageRating.floor()
                      ? Icons.star
                      : (index < _product!.averageRating
                          ? Icons.star_half
                          : Icons.star_border),
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${_product!.averageRating.toStringAsFixed(1)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_product!.reviewCount})',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 친환경 제품 라벨
        if (_product!.isEco)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.green.shade700,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '친환경 제품',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // 가격 정보
        if (_product!.discountPrice != null)
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

        // 판매가
        Text(
          FormatHelper.formatPrice(_product!.sellingPrice),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
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
                  Container(
                    width: 50,
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_quantity < 99) {
                        setState(() {
                          _quantity++;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
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
                FormatHelper.formatPrice(_product!.sellingPrice * _quantity),
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
          const SizedBox(height: 16),
          Text(
            _product!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
          if (_product!.isEco) ...[
            const SizedBox(height: 24),
            _buildEcoInfo(),
          ],
          const SizedBox(height: 32),
          if (_relatedProducts.isNotEmpty) _buildRelatedProducts(),
        ],
      ),
    );
  }

  Widget _buildEcoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                '친환경 제품 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '이 제품은 환경과 건강을 생각하는 소비자를 위해 다음과 같은 친환경 기준을 충족합니다:',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (_product!.ecoLabels != null && _product!.ecoLabels!.isNotEmpty)
            ...List.generate(_product!.ecoLabels!.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                        _product!.ecoLabels![index],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '친환경 소재 및 제조 공정 활용',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
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
          const SizedBox(height: 16),
          // 상품 스펙 테이블
          if (_product!.specifications != null) ...[
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
          ] else
            Text(
              '상세 스펙 정보가 없습니다.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
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
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _product!.averageRating.floor()
                            ? Icons.star
                            : (index < _product!.averageRating
                                ? Icons.star_half
                                : Icons.star_border),
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
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
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
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
            review.content,
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
                    ? ResponsiveImageContainer(
                        imageUrl: product.images[0],
                        aspectRatio: 1.0,
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 1. 이미지 URL 유효성 검사 헬퍼 함수
  bool isValidImageUrl(String url) {
    return url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  // 2. 이미지 크기 최적화
  String getOptimizedImageUrl(String url, {int? width, int? height}) {
    // Firebase Storage URL에 크기 파라미터 추가
    if (url.contains('firebasestorage.googleapis.com')) {
      final uri = Uri.parse(url);
      final params = Map<String, dynamic>.from(uri.queryParameters);
      if (width != null) params['w'] = width.toString();
      if (height != null) params['h'] = height.toString();
      return uri.replace(queryParameters: params).toString();
    }
    return url;
  }

  // 3. 이미지 프리로딩
  void preloadImages(List<String> urls) {
    for (var url in urls) {
      precacheImage(NetworkImage(url), context);
    }
  }
}

// 1. 이미지 위젯 공통 컴포넌트 생성
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image Error: $error');
          return Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey.shade400,
            ),
          );
        },
      ),
    );
  }
}

// 2. 이미지 크기 제약 해결을 위한 래퍼 위젯
class ResponsiveImageContainer extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio;

  const ResponsiveImageContainer({
    required this.imageUrl,
    this.aspectRatio = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ProductImage(
            imageUrl: imageUrl,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
        },
      ),
    );
  }
}
