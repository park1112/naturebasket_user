// lib/screens/home/home_screen.dart (수정)
import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/product/order_history_screen.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/product_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../product/category_screen.dart';
import '../profile/profile_screen.dart';
import '../product/search_screen.dart';
import 'home_content.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BottomNavController _bottomNavController =
      Get.put(BottomNavController());
  final AuthController _authController = Get.find<AuthController>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // 페이지 초기화
    _pages.addAll([
      const HomeContent(),
      const CategoryScreen(category: ProductCategory.food),
      const OrderHistoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '네이처바스켓',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
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
              Get.to(() => const CartScreen());
            },
          ),
        ],
      ),
      body: Obx(() => _pages[_bottomNavController.selectedIndex.value]),
      bottomNavigationBar: AppBottomNavBar(controller: _bottomNavController),
    );
  }
}
