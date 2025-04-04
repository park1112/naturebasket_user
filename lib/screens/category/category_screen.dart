import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/category/category_detail_screen.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../widgets/scrollable_app_bar.dart';
import '../product/search_screen.dart';

class CategoryScreen extends StatefulWidget {
  final ProductCategory? category;

  const CategoryScreen({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<CategoryItem> _categories = [
    CategoryItem(
      icon: Icons.restaurant,
      title: '식품',
      category: ProductCategory.food,
      backgroundColor: Colors.green.shade100,
      iconColor: Colors.green.shade700,
    ),
    CategoryItem(
      icon: Icons.cleaning_services,
      title: '생활용품',
      category: ProductCategory.living,
      backgroundColor: Colors.blue.shade100,
      iconColor: Colors.blue.shade700,
    ),
    CategoryItem(
      icon: Icons.face,
      title: '뷰티',
      category: ProductCategory.beauty,
      backgroundColor: Colors.purple.shade100,
      iconColor: Colors.purple.shade700,
    ),
    CategoryItem(
      icon: Icons.checkroom,
      title: '패션',
      category: ProductCategory.fashion,
      backgroundColor: Colors.orange.shade100,
      iconColor: Colors.orange.shade700,
    ),
    CategoryItem(
      icon: Icons.chair,
      title: '가정용품',
      category: ProductCategory.home,
      backgroundColor: Colors.brown.shade100,
      iconColor: Colors.brown.shade700,
    ),
    CategoryItem(
      icon: Icons.eco,
      title: '친환경/자연',
      category: ProductCategory.eco,
      backgroundColor: Colors.teal.shade100,
      iconColor: Colors.teal.shade700,
    ),
  ];

  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // 시작할 때 특정 카테고리를 전달받았다면, 바로 해당 카테고리 상세 페이지로 이동
    if (widget.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCategoryDetail(widget.category!);
      });
    }
  }

  void _navigateToCategoryDetail(ProductCategory category) {
    // 현재 카테고리 화면에서 상세화면으로 이동할 때는 뒤로가기가 가능하도록 to() 사용
    Get.to(
      () => CategoryDetailScreen(category: category),
      transition: Transition.rightToLeft,
    );
  }

  // 화면 새로고침
  Future<void> _refreshCategories() async {
    _isLoading.value = true;

    // 실제 데이터 로딩 시뮬레이션 (딜레이)
    await Future.delayed(const Duration(milliseconds: 800));

    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableAppBar(
      title: '카테고리',
      showBackButton: false,
      onRefresh: _refreshCategories,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            Get.to(() => const SearchScreen());
          },
        ),
      ],
      child: _buildCategoryContent(context),
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    // 화면 크기 체크
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isWebLayout = screenSize.width > 900;

    // 그리드 열 개수 설정 (화면 크기에 따라 다름)
    final int crossAxisCount = isWebLayout ? 4 : (isSmallScreen ? 2 : 3);

    return Obx(() {
      if (_isLoading.value) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 텍스트
            Text(
              '원하시는 카테고리를 선택해주세요',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),

            // 카테고리 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                return _buildCategoryCard(item);
              },
            ),

            // 충분한 스크롤 영역 확보
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryCard(CategoryItem item) {
    return GestureDetector(
      onTap: () => _navigateToCategoryDetail(item.category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 컨테이너
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // 카테고리 이름
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // 둘러보기 버튼
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: item.backgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '둘러보기',
                style: TextStyle(
                  color: item.iconColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 카테고리 아이템 클래스
class CategoryItem {
  final IconData icon;
  final String title;
  final ProductCategory category;
  final Color backgroundColor;
  final Color iconColor;

  CategoryItem({
    required this.icon,
    required this.title,
    required this.category,
    required this.backgroundColor,
    required this.iconColor,
  });
}
