import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/format_helper.dart';
import '../checkout/checkout_screen.dart';
import 'cart_item_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 렌더링된 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cartController.loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '내 장바구니',
          style:
              GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<CartController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '장바구니 불러오는 중...',
                    style: GoogleFonts.notoSans(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // 장바구니가 비어있는 경우
          if (controller.itemStates.isEmpty) {
            return _buildEmptyCart();
          }

          return Stack(
            children: [
              Column(
                children: [
                  _buildSelectAllControl(),
                  _buildCartSummary(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => controller.loadCart(),
                      color: AppTheme.primaryColor,
                      child: _buildCartItemList(),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildCheckoutSection(),
              ),
            ],
          );
        },
      ),
    );
  }

  // 전체 선택 컨트롤
  Widget _buildSelectAllControl() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: cartController.isAllSelected,
                onChanged: (value) {
                  if (value != null) cartController.toggleAllSelection();
                },
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                '전체 선택',
                style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => cartController.keepSelectedItemsOnly(),
                child: Text(
                  '선택 항목만 남기기',
                  style: GoogleFonts.notoSans(
                      fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ));
  }

  // 장바구니 요약 정보
  Widget _buildCartSummary() {
    return GetBuilder<CartController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '총 ${controller.cartItemCount}개 상품 중 ${controller.selectedItemCount}개 선택',
                  style: GoogleFonts.notoSans(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              '선택: ${FormatHelper.formatPrice(controller.totalPrice)}',
              style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // 장바구니 아이템 목록
  Widget _buildCartItemList() {
    return GetBuilder<CartController>(
      builder: (controller) {
        // 아이템 ID 목록
        final itemIds = controller.itemStates.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 8),
          itemCount: itemIds.length,
          itemBuilder: (context, index) {
            final itemId = itemIds[index];

            // 각 아이템은 독립적인 CartItemWidget으로 구성
            return CartItemWidget(
              key: ValueKey(itemId), // 유니크 키로 리렌더링 최적화
              itemId: itemId,
              cartController: controller,
            );
          },
        );
      },
    );
  }

  // 체크아웃 섹션
  Widget _buildCheckoutSection() {
    return GetBuilder<CartController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택 상품 결제금액',
                        style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatHelper.formatPrice(controller.totalPrice),
                        style: GoogleFonts.notoSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.selectedItemCount > 0
                          ? () => Get.to(() => CheckoutScreen(
                              cartItems: controller.selectedCartItems))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        '${controller.selectedItemCount}개 주문하기',
                        style: GoogleFonts.notoSans(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 20, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '3만원 이상 주문 시 무료배송!',
                      style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 빈 장바구니 UI
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            '장바구니가 비어있습니다',
            style:
                GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '원하는 상품을 담아보세요!',
            style:
                GoogleFonts.notoSans(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                '쇼핑하러 가기',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
