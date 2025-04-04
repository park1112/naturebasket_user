import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/address_controller.dart';
import '../../utils/custom_loading.dart';

// 분리한 탭 위젯 import
import 'profile_tab.dart';
import 'address_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.put(UserController());
  final AddressController _addressController = Get.put(AddressController());

  /// 현재 선택된 탭 인덱스 (0: 프로필, 1: 배송지)
  final RxInt _selectedTab = 0.obs;

  bool get isLoading => _userController.isLoading.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Obx(() {
        if (isLoading) {
          return const Center(child: CustomLoading());
        }
        return Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: Obx(() {
                // 탭 인덱스에 따라 다른 위젯 보여주기
                if (_selectedTab.value == 0) {
                  return const ProfileTab();
                } else {
                  return const AddressTab();
                }
              }),
            ),
          ],
        );
      }),
    );
  }

  /// 탭(프로필 정보, 배송지 관리) 버튼 UI
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('프로필 정보', 0),
          _buildTabButton('배송지 관리', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _selectedTab.value == index
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab.value == index
                  ? AppTheme.primaryColor
                  : Colors.grey,
              fontWeight: _selectedTab.value == index
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
