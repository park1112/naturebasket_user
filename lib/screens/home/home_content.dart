import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import '../product/category_screen.dart';
import '../product/product_detail_screen.dart';
import '../product/search_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<ProductModel> _popularProducts = [];
  List<ProductModel> _ecoProducts = [];
  List<ProductModel> _newProducts = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final futures = await Future.wait([
        _productService.getPopularProducts(),
        _productService.getEcoProducts(),
        _productService.getProductsByCategory(ProductCategory.food, limit: 6),
      ]);
      // 위젯이 마운트되어 있는지 확인 후 상태 업데이트
      if (mounted) {
        setState(() {
          _popularProducts = futures[0];
          _ecoProducts = futures[1];
          _newProducts = futures[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      // 위젯이 마운트되어 있는지 확인 후 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CustomLoading())
        : SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  // 하단 네비게이션 바 등의 높이를 고려하여 패딩 추가
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: ConstrainedBox(
                  // 화면 최소 높이 보장 (스크롤 가능 영역 확보)
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight, // AppBar 높이 고려
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isSmallScreen = constraints.maxWidth < 600;
                      bool isWebLayout = constraints.maxWidth > 900;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16.0 : 24.0,
                          horizontal: isWebLayout
                              ? 40.0
                              : (isSmallScreen ? 16.0 : 24.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 메인 배너
                            _buildMainBanner(isSmallScreen, isWebLayout),
                            const SizedBox(height: 24),
                            // 카테고리 메뉴
                            _buildCategoryMenu(isSmallScreen, isWebLayout),
                            const SizedBox(height: 24),
                            // 추천 상품 섹션
                            _buildProductSection(
                              '지금 인기 있는 상품',
                              '고객들이 가장 많이 찾는 인기 상품을 소개합니다.',
                              _popularProducts,
                              isSmallScreen,
                              isWebLayout,
                            ),
                            const SizedBox(height: 24),
                            // 친환경 상품 섹션
                            _buildProductSection(
                              '친환경 제품',
                              '환경과 건강을 생각하는 친환경 제품들을 만나보세요.',
                              _ecoProducts,
                              isSmallScreen,
                              isWebLayout,
                            ),
                            const SizedBox(height: 24),
                            // 신상품 섹션
                            _buildProductSection(
                              '신상품',
                              '네이처바스켓의 새로운 상품을 소개합니다.',
                              _newProducts,
                              isSmallScreen,
                              isWebLayout,
                            ),
                            const SizedBox(height: 24),
                            // 하단 프로모션 배너
                            _buildBottomBanner(isSmallScreen, isWebLayout),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildMainBanner(bool isSmallScreen, bool isWebLayout) {
    const String bannerImageUrl =
        'https://source.unsplash.com/random/1200x400/?nature,organic';

    return Container(
      width: double.infinity,
      height: isWebLayout ? 400 : (isSmallScreen ? 200 : 300),
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8.0 : 16.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: bannerImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: isSmallScreen ? 40 : 64,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Text(
                      '자연과 함께하는 라이프스타일',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWebLayout ? 32 : (isSmallScreen ? 20 : 24),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Text(
                      '네이처바스켓에서 건강하고 친환경적인 제품을 만나보세요.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => const CategoryScreen(
                            category: ProductCategory.eco,
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                    child: const Text('구경하기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMenu(bool isSmallScreen, bool isWebLayout) {
    final categories = [
      {
        'icon': Icons.restaurant,
        'title': '식품',
        'category': ProductCategory.food,
      },
      {
        'icon': Icons.cleaning_services,
        'title': '생활용품',
        'category': ProductCategory.living,
      },
      {
        'icon': Icons.face,
        'title': '뷰티',
        'category': ProductCategory.beauty,
      },
      {
        'icon': Icons.checkroom,
        'title': '패션',
        'category': ProductCategory.fashion,
      },
      {
        'icon': Icons.chair,
        'title': '가정용품',
        'category': ProductCategory.home,
      },
      {
        'icon': Icons.eco,
        'title': '친환경/자연',
        'category': ProductCategory.eco,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 16.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWebLayout ? 6 : (isSmallScreen ? 3 : 4),
              // childAspectRatio: 1.0, // 기존 고정 비율
              // 화면이 작을 때(isSmallScreen) 세로 길이를 가로 길이의 1.05배로 약간 늘려줌
              // 이렇게 하면 셀의 높이가 약간 더 확보되어 내용물이 넘치는 것을 방지할 수 있음
              childAspectRatio: isSmallScreen ? (1.0 / 1.05) : 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              // _buildCategoryItem 호출은 변경 없음
              return _buildCategoryItem(
                categories[index]['icon'] as IconData,
                categories[index]['title'] as String,
                categories[index]['category'] as ProductCategory,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      IconData icon, String title, ProductCategory category) {
    return InkWell(
      onTap: () {
        Get.to(() => CategoryScreen(category: category));
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, // 필요하다면 이 값들도 반응형으로 만들 수 있음 (아래 방법 2 참고)
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 6), // 원래 값으로 되돌리거나 4 유지
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(
    String title,
    String subtitle,
    List<ProductModel> products,
    bool isSmallScreen,
    bool isWebLayout,
  ) {
    return Container(
      margin: EdgeInsets.only(
        top: isSmallScreen ? 24.0 : 32.0,
        bottom: isSmallScreen ? 8.0 : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (title == '친환경 제품') {
                    Get.to(() => const CategoryScreen(
                          category: ProductCategory.eco,
                        ));
                  } else if (title == '신상품') {
                    Get.to(() => const CategoryScreen(
                          category:
                              ProductCategory.food, // 예시: 신상품은 Food 카테고리로 가정
                        ));
                  } else {
                    // 인기 상품 등 다른 섹션은 검색 화면 등으로 이동 가능
                    Get.to(() => const SearchScreen());
                  }
                },
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300, // 상품 카드 높이에 맞게 조정
            child: products.isEmpty
                ? Center(
                    child: Text(
                      '상품 준비 중입니다.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: product.id));
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white, // 카드 배경색 추가 (그림자 등 효과를 위해)
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            // 은은한 그림자 효과 (선택 사항)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180, // 이미지 영역 높이 고정
              width: double.infinity, // 너비 채우기
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2.0, // 로딩 인디케이터 두께 조절
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade100, // 에러 시 배경색
                          child: Icon(
                            Icons.broken_image_outlined, // 다른 아이콘 사용
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.image_not_supported_outlined, // 다른 아이콘 사용
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            // 상품 정보 영역은 Expanded로 남은 공간 채우기
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0), // 패딩 약간 줄임
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // 요소 간 간격 균등 배분
                  children: [
                    // 친환경 태그 + 상품명
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isEco)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.green.shade100) // 테두리 추가
                                ),
                            child: Text(
                              '친환경',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Text(
                          product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14), // 폰트 크기 조정
                          maxLines: 2, // 최대 2줄까지 표시
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // 가격 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.discountPrice != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  product.discountPercentage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.price.toStringAsFixed(0)}원',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500, // 색상 약간 연하게
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '${product.sellingPrice.toStringAsFixed(0)}원',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor, // AppTheme 색상 사용
                          ),
                        ),
                      ],
                    ),

                    // 평점 및 리뷰 수
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber.shade600, size: 14), // 색상 조정
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner(bool isSmallScreen, bool isWebLayout) {
    // 웹 레이아웃이거나 작은 화면이 아닐 때만 이미지 표시
    bool showImage = !isSmallScreen;

    return Container(
      width: double.infinity,
      // 높이를 유동적으로 설정 (하드코딩 제거)
      // height: isWebLayout ? 300 : (isSmallScreen ? 150 : 200),
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 16.0 : 24.0,
        // horizontal 값 수정: 웹 레이아웃일 때만 40.0 적용
        horizontal:
            isWebLayout ? 40.0 : 0, // 좌우 마진은 부모 Padding에서 관리하므로 0으로 설정하거나 제거
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 배경 패턴 (필요하다면 유지)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.1,
                child: Image.network(
                  'https://source.unsplash.com/random/1200x400/?pattern,leaf',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.transparent), // 에러 시 빈 컨테이너
                  loadingBuilder: (context, child, loadingProgress) {
                    // 로딩 중 빈 컨테이너
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.transparent);
                  },
                ),
              ),
            ),
          ),
          // 배너 콘텐츠
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Row(
              children: [
                // 텍스트 및 버튼 영역
                Expanded(
                  // SingleChildScrollView로 감싸서 내용이 넘칠 경우 스크롤 가능하게 함
                  child: SingleChildScrollView(
                    physics:
                        const NeverScrollableScrollPhysics(), // 부모 스크롤과 충돌 방지
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Column 크기를 내용에 맞게 조절
                      children: [
                        Text(
                          '친환경 캠페인',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '지구를 위한 작은 실천',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '네이처바스켓과 함께 환경을 생각하는 라이프스타일을 시작해보세요.',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Get.snackbar(
                              '알림',
                              '캠페인 페이지는 아직 준비 중입니다.',
                              snackPosition: SnackPosition.TOP,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 24,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                          ),
                          child: const Text('더 알아보기'),
                        ),
                      ],
                    ),
                  ),
                ),
                // 이미지 영역 (웹 또는 큰 화면에서만 표시)
                if (showImage)
                  SizedBox(
                    width: isWebLayout ? 200 : 150,
                    child: Icon(
                      Icons.eco_outlined, // 아이콘 변경 (선택 사항)
                      size: isWebLayout ? 120 : 80,
                      color: Colors.green.shade300.withOpacity(0.8), // 투명도 추가
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
