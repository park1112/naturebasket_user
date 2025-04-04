import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';
import '../screens/product/search_screen.dart';
import '../screens/order/order_history_screen.dart';
import '../screens/cart/cart_screen.dart';

/// 특정 화면에서는 앱바를 숨기고, 다른 화면에서는 표시하는 위젯
class ConditionalAppBar extends StatelessWidget {
  /// 자식 위젯 (메인 콘텐츠)
  final Widget child;

  /// 앱바 제목
  final String title;

  /// 현재 화면의 라우트 이름 (화면 식별용)
  final String currentRoute;

  /// 앱바를 숨길 라우트 이름 목록
  final List<String> hideAppBarRoutes;

  /// 배경색
  final Color? backgroundColor;

  /// 커스텀 액션 버튼들
  final List<Widget>? actions;

  /// 앱바 표시 여부를 직접 제어 (특정 라우트 외에도 추가 조건 필요할 때)
  final bool? forceHideAppBar;

  const ConditionalAppBar({
    Key? key,
    required this.child,
    this.title = '네이처바스켓',
    required this.currentRoute,
    this.hideAppBarRoutes = const ['CategoryScreen', 'ProductDetailScreen'],
    this.backgroundColor,
    this.actions,
    this.forceHideAppBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 앱바 숨김 여부 확인
    final bool shouldHideAppBar = forceHideAppBar ??
        hideAppBarRoutes.any((route) => currentRoute.contains(route));

    // 앱바 숨김 조건에 따라 다른 위젯 반환
    if (shouldHideAppBar) {
      // 앱바 없이 자식 위젯만 표시
      return child;
    } else {
      // 앱바가 있는 NestedScrollView 반환
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: backgroundColor ?? AppTheme.primaryColor,
              floating: true,
              snap: true,
              actions: actions ?? _buildDefaultActions(),
            ),
          ];
        },
        body: child,
      );
    }
  }

  // 기본 액션 버튼들
  List<Widget> _buildDefaultActions() {
    return [
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
    ];
  }
}
