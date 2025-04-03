import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import '../product/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? title;
  // 이전 화면에서 카테고리 ID 등을 전달받을 수 있음
  final String? categoryId;
  final String? categoryName;

  const ProductListScreen({
    super.key,
    this.title,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final ScrollController _scrollController = ScrollController();
  // Get.lazyPut() 등으로 미리 등록해두는 것이 좋음
  final ProductController controller = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.title == null) {
      _productController.resetFilters();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchInitialProducts(categoryId: widget.categoryId);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _productController.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '상품 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Obx(() {
        if (_productController.isLoading.value &&
            _productController.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_productController.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '상품이 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _productController.resetFilters();
                  },
                  child: const Text('필터 초기화'),
                ),
              ],
            ),
          );
        }
        return Stack(
          children: [
            if (_productController.filterOrganic.value ||
                _productController.filterEcoFriendly.value ||
                _productController.selectedCategory.value.isNotEmpty ||
                _productController.searchQuery.value.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_productController
                                .selectedCategory.value.isNotEmpty)
                              _buildFilterChip('카테고리', () {
                                _productController.selectedCategory.value = '';
                                _productController.loadProducts(refresh: true);
                              }),
                            if (_productController.searchQuery.value.isNotEmpty)
                              _buildFilterChip(
                                  '검색: ${_productController.searchQuery.value}',
                                  () {
                                _productController.searchQuery.value = '';
                                _productController.loadProducts(refresh: true);
                              }),
                            if (_productController.filterOrganic.value)
                              _buildFilterChip('유기농', () {
                                _productController.filterOrganic.value = false;
                                _productController.loadProducts(refresh: true);
                              }),
                            if (_productController.filterEcoFriendly.value)
                              _buildFilterChip('친환경', () {
                                _productController.filterEcoFriendly.value =
                                    false;
                                _productController.loadProducts(refresh: true);
                              }),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _productController.resetFilters();
                      },
                      child: const Text('초기화'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: (_productController.filterOrganic.value ||
                        _productController.filterEcoFriendly.value ||
                        _productController.selectedCategory.value.isNotEmpty ||
                        _productController.searchQuery.value.isNotEmpty)
                    ? 50
                    : 0,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;
                  bool isWebLayout = constraints.maxWidth > 900;
                  int crossAxisCount = isSmallScreen
                      ? 2
                      : isWebLayout
                          ? 4
                          : 3;
                  double itemHeight = 300;
                  double itemWidth = constraints.maxWidth / crossAxisCount;
                  return RefreshIndicator(
                    onRefresh: () async {
                      await _productController.loadProducts(refresh: true);
                    },
                    child: Stack(
                      children: [
                        GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: itemWidth / itemHeight,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _productController.products.length,
                          itemBuilder: (context, index) {
                            final product = _productController.products[index];
                            return _buildProductItem(product);
                          },
                        ),
                        if (_productController.isLoading.value)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductModel product) {
    bool isFavorite =
        _productController.favoriteProductIds.contains(product.id);
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: product.id));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images[0],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.error),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image),
                          ),
                  ),
                ),
                if (product.discountRate > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountRate.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      _productController.toggleFavorite(product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (product.ecoLabels != null && product.ecoLabels!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '친환경',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (product.isOrganic)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '유기농',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (product.discountRate > 0) ...[
                    Text(
                      '${product.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원',
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    '${product.sellingPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원',
                    style: TextStyle(
                      fontSize: product.discountRate > 0 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color:
                          product.discountRate > 0 ? Colors.red : Colors.black,
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '필터',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    '상품 유형',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('유기농'),
                          value: _productController.filterOrganic.value,
                          onChanged: (value) {
                            setState(() {
                              _productController.filterOrganic.value =
                                  value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('친환경'),
                          value: _productController.filterEcoFriendly.value,
                          onChanged: (value) {
                            setState(() {
                              _productController.filterEcoFriendly.value =
                                  value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _productController.filterOrganic.value = false;
                              _productController.filterEcoFriendly.value =
                                  false;
                            });
                          },
                          child: const Text('초기화'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _productController.loadProducts(refresh: true);
                            Navigator.pop(context);
                          },
                          child: const Text('적용'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '정렬',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              _buildSortOption('최신순', 'createdAt', true),
              _buildSortOption('가격 낮은순', 'price', false),
              _buildSortOption('가격 높은순', 'price', true),
              _buildSortOption('할인율순', 'discountRate', true),
              _buildSortOption('인기순', 'rating', true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String field, bool descending) {
    bool isSelected = _productController.sortBy.value == field &&
        _productController.sortDescending.value == descending;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        _productController.sortBy.value = field;
        _productController.sortDescending.value = descending;
        _productController.loadProducts(refresh: true);
        Navigator.pop(context);
      },
    );
  }
}
