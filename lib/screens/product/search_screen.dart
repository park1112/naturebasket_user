// lib/screens/product/search_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialKeyword;

  const SearchScreen({
    Key? key,
    this.initialKeyword,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// lib/screens/product/search_screen.dart (계속)
class _SearchScreenState extends State<SearchScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _searchController.text = widget.initialKeyword!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _productService.searchProducts(keyword);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _performSearch,
            child: const Text('검색'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 인기 검색어 또는 최근 검색어 (간단하게 구현)
          if (!_hasSearched) _buildSearchSuggestions(),

          // 검색 결과
          if (_hasSearched)
            Expanded(
              child: _isLoading
                  ? const Center(child: CustomLoading())
                  : _searchResults.isEmpty
                      ? _buildEmptyResults()
                      : _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final popularKeywords = ['친환경', '유기농', '비건', '무설탕', '핸드메이드', '천연'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인기 검색어',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularKeywords.map((keyword) {
              return InkWell(
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(keyword),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '"${_searchController.text}" 검색 결과가 없습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어를 입력해보세요.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비에 따라 그리드 또는 리스트 뷰로 표시
        if (constraints.maxWidth > 600) {
          // 그리드 뷰 (태블릿, 웹)
          int crossAxisCount = constraints.maxWidth > 900 ? 4 : 3;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_searchResults[index]);
            },
          );
        } else {
          // 리스트 뷰 (모바일)
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return _buildProductListItem(_searchResults[index]);
            },
          );
        }
      },
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
                    // 상품명
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

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
                    ],

                    Text(
                      '${product.sellingPrice.toStringAsFixed(0)}원',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),

                    const Spacer(),

                    // 평점 정보
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
                        Text(
                          ' (${product.reviewCount})',
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

  Widget _buildProductListItem(ProductModel product) {
    return InkWell(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: product.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls[0],
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
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // 상품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리
                  Text(
                    product.categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 상품명
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // 가격 정보
                  if (product.discountPrice != null) ...[
                    Row(
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

                  Text(
                    '${product.sellingPrice.toStringAsFixed(0)}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 평점 정보
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      Text(
                        ' ${product.averageRating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' (${product.reviewCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const Spacer(),

                      // 친환경 라벨
                      if (product.isEco)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
