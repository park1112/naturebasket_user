import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/category/category_screen.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../product/search_screen.dart';
import '../order/order_history_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BottomNavController _bottomNavController =
      Get.put(BottomNavController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // 현재 선택된 탭 인덱스
        final int currentIndex = _bottomNavController.selectedIndex.value;

        // 홈 탭(0)일 때만 네스티드 스크롤 뷰와 앱바를 표시
        if (currentIndex == 0) {
          return _buildHomeTab();
        } else {
          // 다른 탭에서는 각 페이지를 그대로 표시 (자체 앱바 사용)
          return _buildOtherTab(currentIndex);
        }
      }),
      bottomNavigationBar: AppBottomNavBar(controller: _bottomNavController),
    );
  }

  // 홈 탭 UI (AppBar 포함)
  Widget _buildHomeTab() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            title: const Text(
              '네이처바스켓',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Get.to(() => const SearchScreen());
                },
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Get.to(() => const OrderHistoryScreen());
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Get.to(() => CartScreen());
                },
              ),
            ],
          ),
        ];
      },
      body: const HomeContent(),
    );
  }

  // 다른 탭들의 UI (각 탭의 페이지 직접 표시)
  Widget _buildOtherTab(int index) {
    switch (index) {
      case 1: // 카테고리 탭
        return const CategoryScreen();
      case 2: // 주문 내역 탭
        return const OrderHistoryScreen();
      case 3: // 장바구니 탭
        return CartScreen();
      case 4: // 프로필 탭
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
