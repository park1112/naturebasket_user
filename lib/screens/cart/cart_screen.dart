// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/cart_controller.dart';
import 'package:flutter_login_template/screens/product/product_detail_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // 상품 선택 상태를 관리하는 맵
  final RxMap<String, bool> _selectedItems = <String, bool>{}.obs;
  // 전체 선택 상태
  final RxBool _selectAll = true.obs;

  // 선택된 상품들의 총 가격
  final RxDouble _selectedTotalPrice = 0.0.obs;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 열릴 때 장바구니 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cartController.loadCart();

      // 장바구니 로드 후 모든 아이템을 기본적으로 선택 상태로 설정
      ever(cartController.cartItems, (_) {
        _initSelectedItems();
      });
    });
  }

  // 모든 아이템을 초기에 선택 상태로 설정
  void _initSelectedItems() {
    _selectedItems.clear();
    for (var item in cartController.cartItems) {
      _selectedItems[item.id] = true;
    }
    _updateSelectedTotalPrice();
  }

  // 모든 아이템 선택/해제
  void _toggleSelectAll(bool value) {
    _selectAll.value = value;
    for (var item in cartController.cartItems) {
      _selectedItems[item.id] = value;
    }
    _updateSelectedTotalPrice();
  }

  // 개별 아이템 선택/해제
  void _toggleSelectItem(String itemId, bool value) {
    _selectedItems[itemId] = value;

    // 모든 아이템이 선택되었는지 확인
    bool allSelected = true;
    for (var item in cartController.cartItems) {
      if (_selectedItems[item.id] != true) {
        allSelected = false;
        break;
      }
    }
    _selectAll.value = allSelected;

    _updateSelectedTotalPrice();
  }

  // 선택된 상품들의 총 가격 계산
  void _updateSelectedTotalPrice() {
    double total = 0.0;
    for (var item in cartController.cartItems) {
      if (_selectedItems[item.id] == true) {
        total += item.price * item.quantity;
      }
    }
    _selectedTotalPrice.value = total;
  }

  // 선택된 상품들만 반환
  List<CartItemModel> get _getSelectedItems {
    return cartController.cartItems
        .where((item) => _selectedItems[item.id] == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '내 장바구니',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => cartController.loadCart(),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              '새로고침',
              style: GoogleFonts.notoSans(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      body: Obx(() {
        // 로딩 상태 표시
        if (cartController.isLoading.value) {
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
        if (cartController.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        // 장바구니 아이템 표시
        return Stack(
          children: [
            Column(
              children: [
                // 전체 선택 컨트롤
                _buildSelectAllControl(),

                // 장바구니 상단 요약 정보
                _buildCartSummary(),

                // 장바구니 아이템 목록
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120, top: 8),
                    itemCount: cartController.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartController.cartItems[index];
                      return _buildCartItem(item, cartController);
                    },
                  ),
                ),
              ],
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
                value: _selectAll.value,
                onChanged: (value) {
                  if (value != null) {
                    _toggleSelectAll(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                '전체 선택',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // 선택된 상품들만 남기고 나머지 삭제
                  for (var item in cartController.cartItems.toList()) {
                    if (_selectedItems[item.id] != true) {
                      cartController.removeFromCart(item.id);
                    }
                  }
                },
                child: Text(
                  '선택 항목만 남기기',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // 장바구니 상단 요약 정보
  Widget _buildCartSummary() {
    return Obx(() => Container(
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
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '총 ${cartController.cartItems.length}개 상품 중 ${_getSelectedItems.length}개 선택',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '선택: ${FormatHelper.formatPrice(_selectedTotalPrice.value)}',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildCheckoutSection() {
    return Obx(() => Container(
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
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FormatHelper.formatPrice(_selectedTotalPrice.value),
                          style: GoogleFonts.notoSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _getSelectedItems.isNotEmpty
                            ? () => Get.to(() => CheckoutScreen(
                                  cartItems: _getSelectedItems,
                                ))
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
                          '${_getSelectedItems.length}개 주문하기',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 20,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '3만원 이상 주문 시 무료배송!',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildCartItem(CartItemModel item, CartController controller) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedItems[item.id] == true
                ? Colors.white
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedItems[item.id] == true
                  ? Colors.white
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedItems[item.id] == true
                    ? Colors.grey.shade100
                    : Colors.transparent,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 체크박스
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Checkbox(
                  value: _selectedItems[item.id] ?? false,
                  onChanged: (value) {
                    if (value != null) {
                      _toggleSelectItem(item.id, value);
                    }
                  },
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // 상품 정보
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Get.to(
                        () => ProductDetailScreen(productId: item.productId)),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: Column(
                        children: [
                          // 상품 정보 부분
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 상품 이미지
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: item.productImage != null
                                      ? product_widget.ProductImage(
                                          imageUrl: item.productImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[100],
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 상품 정보
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName,
                                            style: GoogleFonts.notoSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // 삭제 버튼
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: () => controller
                                                .removeFromCart(item.id),
                                            icon: const Icon(Icons.close,
                                                size: 16),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // 상품 옵션 (있을 경우)
                                    if (item.selectedOptions != null &&
                                        item.selectedOptions!.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 4, bottom: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _formatSelectedOptions(
                                              item.selectedOptions!),
                                          style: GoogleFonts.notoSans(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                    // 가격
                                    Text(
                                      FormatHelper.formatPrice(item.price),
                                      style: GoogleFonts.notoSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 하단 수량 및 금액 부분
                          Row(
                            children: [
                              // 수량 조절 버튼
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          controller.updateItemQuantity(
                                              item, item.quantity - 1);
                                          _updateSelectedTotalPrice();
                                        }
                                      },
                                    ),
                                    Container(
                                      width: 36,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      icon: Icons.add,
                                      onPressed: () {
                                        controller.updateItemQuantity(
                                            item, item.quantity + 1);
                                        _updateSelectedTotalPrice();
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // 총 가격
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '총 금액',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    FormatHelper.formatPrice(
                                        item.price * item.quantity),
                                    style: GoogleFonts.notoSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

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
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '장바구니가 비어있습니다',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '원하는 상품을 담아보세요!',
            style: GoogleFonts.notoSans(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
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
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상품 옵션 포맷팅
  String _formatSelectedOptions(Map<String, dynamic> options) {
    List<String> formattedOptions = [];
    options.forEach((key, value) {
      formattedOptions.add('$key: $value');
    });
    return formattedOptions.join(', ');
  }
}
