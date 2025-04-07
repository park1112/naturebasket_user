import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final ProductCategory category;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<ProductModel> _products = [];
  String _errorMessage = '';

  // 필터 및 정렬 상태
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  // 필터 옵션
  final List<String> _filterOptions = ['전체', '세일중', '인기상품', '신상품'];

  // 정렬 옵션
  final List<String> _sortOptions = ['최신순', '가격 낮은순', '가격 높은순', '인기순'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 카테고리에 따른 상품 로드
      final products =
          await _productService.getProductsByCategory(widget.category);

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '상품을 불러오는 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
      print('Error loading products: $e');
    }
  }

  // 카테고리 이름 얻기
  String _getCategoryName() {
    switch (widget.category) {
      case ProductCategory.food:
        return '식품';
      case ProductCategory.living:
        return '생활용품';
      case ProductCategory.beauty:
        return '뷰티';
      case ProductCategory.fashion:
        return '패션';
      case ProductCategory.home:
        return '가정용품';
      case ProductCategory.eco:
        return '친환경/자연';
      default:
        return '전체 상품';
    }
  }

  // 카테고리 아이콘 얻기
  IconData _getCategoryIcon() {
    switch (widget.category) {
      case ProductCategory.food:
        return Icons.restaurant;
      case ProductCategory.living:
        return Icons.cleaning_services;
      case ProductCategory.beauty:
        return Icons.face;
      case ProductCategory.fashion:
        return Icons.checkroom;
      case ProductCategory.home:
        return Icons.chair;
      case ProductCategory.eco:
        return Icons.eco;
      default:
        return Icons.shopping_bag;
    }
  }

  // 카테고리 색상 얻기
  Color _getCategoryColor() {
    switch (widget.category) {
      case ProductCategory.food:
        return Colors.green;
      case ProductCategory.living:
        return Colors.blue;
      case ProductCategory.beauty:
        return Colors.purple;
      case ProductCategory.fashion:
        return Colors.orange;
      case ProductCategory.home:
        return Colors.brown;
      case ProductCategory.eco:
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 체크
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isWebLayout = screenSize.width > 900;

    // 그리드 열 개수 설정
    final int crossAxisCount = isWebLayout ? 4 : (isSmallScreen ? 2 : 3);

    // 카테고리 색상 가져오기
    final Color categoryColor = _getCategoryColor();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: _getCategoryName(),
        backgroundColor: categoryColor,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: CustomScrollView(
                slivers: [
                  // 카테고리 헤더
                  SliverToBoxAdapter(
                    child: _buildCategoryHeader(categoryColor, isSmallScreen),
                  ),

                  // 필터 및 정렬 옵션
                  SliverToBoxAdapter(
                    child: _buildFilterOptions(isSmallScreen),
                  ),

                  // 에러 메시지 표시
                  if (_errorMessage.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ),
                    ),

                  // 상품이 없는 경우
                  if (_products.isEmpty && _errorMessage.isEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '상품이 없습니다',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 상품 그리드
                  if (_products.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return GestureDetector(
                              onTap: () => Get.to(
                                () => ProductDetailScreen(
                                    productId: _products[index].id),
                                transition: Transition.rightToLeft,
                              ),
                              child: ProductCard(
                                product: _products[index],
                              ),
                            );
                          },
                          childCount: _products.length,
                        ),
                      ),
                    ),

                  // 하단 여백
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryHeader(Color categoryColor, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 ${_products.length}개 상품',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  Widget _buildFilterOptions(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // 필터 옵션
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: _getCategoryColor().withOpacity(0.2),
                    side: BorderSide.none, // 검은색 테두리 제거
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _getCategoryColor()
                          : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          // 여기서 필터링 로직 추가 가능
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 정렬 옵션
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: _selectedSort,
                icon: const Icon(Icons.arrow_drop_down),
                underline: Container(
                  height: 0,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSort = newValue;
                      // 여기서 정렬 로직 추가 가능
                    });
                  }
                },
                items:
                    _sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
