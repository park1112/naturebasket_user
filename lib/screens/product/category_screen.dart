// lib/screens/product/category_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final ProductCategory category;

  const CategoryScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  String _sortBy = '인기순';

  final List<String> _sortOptions = ['인기순', '신상품순', '낮은가격순', '높은가격순'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products =
          await _productService.getProductsByCategory(widget.category);

      setState(() {
        _products = products;
        _sortProducts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortProducts() {
    switch (_sortBy) {
      case '인기순':
        _products.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case '신상품순':
        _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '낮은가격순':
        _products.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case '높은가격순':
        _products.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _buildProductGrid(),
    );
  }

  String _getCategoryTitle() {
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
    }
  }

  Widget _buildProductGrid() {
    return Column(
      children: [
        // 필터 및 정렬 옵션
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '총 ${_products.length}개 상품',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.arrow_drop_down),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                      _sortProducts();
                    });
                  }
                },
                items:
                    _sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // 상품 그리드
        Expanded(
          child: _products.isEmpty
              ? _buildEmptyProducts()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // 화면 너비에 따라 그리드 열 수 조정
                    int crossAxisCount;
                    if (constraints.maxWidth > 1200) {
                      crossAxisCount = 5;
                    } else if (constraints.maxWidth > 900) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 3;
                    } else {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '상품이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 카테고리에 등록된 상품이 없습니다.',
            style: TextStyle(
              color: Colors.grey.shade600,
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
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            AspectRatio(
              aspectRatio: 1,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 친환경 라벨
                    if (product.isEco)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
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

                    // 상품명
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // 할인가가 있는 경우
                    if (product.discountPrice != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
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
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],

                    // 판매가
                    Text(
                      '${product.sellingPrice.toStringAsFixed(0)}원',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),

                    const Spacer(),

                    // 평점 및 리뷰 수
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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
}
