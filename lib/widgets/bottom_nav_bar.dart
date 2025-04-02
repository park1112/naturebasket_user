// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';

class BottomNavController extends GetxController {
  RxInt selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final List<BottomNavItem> items;
  final BottomNavController controller;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changePage,
            items: items.map((item) => _buildNavItem(item)).toList(),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
          ),
        ));
  }

  BottomNavigationBarItem _buildNavItem(BottomNavItem item) {
    return BottomNavigationBarItem(
      icon: Icon(item.icon),
      activeIcon: Icon(item.activeIcon ?? item.icon),
      label: item.label,
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

// 네이처바스켓 앱의 바텀 네비게이션
class AppBottomNavBar extends StatelessWidget {
  final BottomNavController controller;

  const AppBottomNavBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavBar(
      controller: controller,
      items: [
        BottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: '홈',
        ),
        BottomNavItem(
          icon: Icons.category_outlined,
          activeIcon: Icons.category,
          label: '카테고리',
        ),
        BottomNavItem(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart,
          label: '장바구니',
        ),
        BottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: '마이페이지',
        ),
      ],
    );
  }
}
