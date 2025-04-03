// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/cart_controller.dart';
import 'package:flutter_login_template/screens/product/product_detail_screen.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../checkout/checkout_screen.dart';
import '../../utils/format_helper.dart';
import '../../widgets/product_image.dart' as product_widget;

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 열릴 때 장바구니 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cartController.loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('장바구니'),
      // ),
      body: Obx(() {
        // 로딩 상태 표시
        if (cartController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          );
        }

        // 장바구니가 비어있는 경우
        if (cartController.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        // 장바구니 아이템 표시
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: cartController.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartController.cartItems[index];
                return _buildCartItem(item, cartController);
              },
            ),
            // 하단 결제 버튼
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCheckoutSection(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                const Text(
                  '총 결제금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(() => Text(
                      FormatHelper.formatPrice(cartController.totalPrice.value),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: cartController.cartItems.isNotEmpty
                    ? () => Get.to(() => CheckoutScreen(
                          cartItems: cartController.cartItems,
                        ))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '주문하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지 - 반응형으로 수정
            Expanded(
              flex: 2, // 이미지 영역 비율
              child: AspectRatio(
                aspectRatio: 1, // 1:1 비율 유지
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.productImage != null
                      ? product_widget.ProductImage(
                          imageUrl: item.productImage!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 상품 정보
            Expanded(
              flex: 5, // 정보 영역 비율
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // 삭제 버튼
                      IconButton(
                        onPressed: () => controller.removeFromCart(item.id),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FormatHelper.formatPrice(item.price),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 수량 조절
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () {
                                if (item.quantity > 1) {
                                  controller.updateItemQuantity(
                                      item, item.quantity - 1);
                                }
                              },
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () {
                                controller.updateItemQuantity(
                                    item, item.quantity + 1);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        FormatHelper.formatPrice(item.price * item.quantity),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '장바구니가 비어있습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '상품을 장바구니에 담아보세요!',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
