// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../utils/custom_loading.dart';
import '../../widgets/custom_button.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final AuthController _authController = Get.find<AuthController>();

  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (_authController.firebaseUser.value == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _cartService.getUserCart(
        _authController.firebaseUser.value!.uid,
      );

      setState(() {
        _cartItems = items;
        // 기본적으로 모든 항목 선택
        _selectedItems = items.map((item) => item.id).toSet();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCartItemQuantity(CartItemModel item, int quantity) async {
    if (_authController.firebaseUser.value == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _cartService.updateCartItemQuantity(
        _authController.firebaseUser.value!.uid,
        item.id,
        quantity,
      );

      if (success) {
        await _loadCartItems();
      } else {
        Get.snackbar(
          '오류',
          '수량 업데이트에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      Get.snackbar(
        '오류',
        '수량 업데이트 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeCartItem(String itemId) async {
    if (_authController.firebaseUser.value == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _cartService.removeCartItem(
        _authController.firebaseUser.value!.uid,
        itemId,
      );

      if (success) {
        _selectedItems.remove(itemId);
        await _loadCartItems();
      } else {
        Get.snackbar(
          '오류',
          '상품 삭제에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('Error removing cart item: $e');
      Get.snackbar(
        '오류',
        '상품 삭제 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _toggleAllSelection() {
    setState(() {
      if (_selectedItems.length == _cartItems.length) {
        // 모두 선택되어 있으면 모두 선택 해제
        _selectedItems.clear();
      } else {
        // 일부만 선택되어 있으면 모두 선택
        _selectedItems = _cartItems.map((item) => item.id).toSet();
      }
    });
  }

  double _calculateTotalPrice() {
    return _cartItems
        .where((item) => _selectedItems.contains(item.id))
        .fold(0, (sum, item) => sum + item.totalPrice);
  }

  void _navigateToCheckout() {
    if (_selectedItems.isEmpty) {
      Get.snackbar(
        '알림',
        '구매할 상품을 선택해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    List<CartItemModel> selectedCartItems =
        _cartItems.where((item) => _selectedItems.contains(item.id)).toList();

    Get.to(() => CheckoutScreen(cartItems: selectedCartItems));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _buildCartContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCartContent() {
    if (_authController.firebaseUser.value == null) {
      return _buildLoginRequired();
    }

    if (_cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isWebLayout = constraints.maxWidth > 900;

        if (isWebLayout) {
          // 웹 레이아웃 (테이블 형식)
          return _buildWebCartLayout();
        } else {
          // 모바일 레이아웃 (리스트 형식)
          return _buildMobileCartLayout(isSmallScreen);
        }
      },
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '로그인이 필요합니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '장바구니를 이용하려면 로그인해주세요.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: '로그인하기',
            onPressed: () {
              // 로그인 화면으로 이동
              _authController.signOut();
            },
          ),
        ],
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
            color: Colors.grey.shade400,
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
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: '쇼핑 계속하기',
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebCartLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 선택 영역
              Row(
                children: [
                  Checkbox(
                    value: _selectedItems.length == _cartItems.length,
                    onChanged: (_) => _toggleAllSelection(),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Text(
                    '전체 선택',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // 선택 상품 삭제 기능
                      for (String itemId in _selectedItems.toList()) {
                        _removeCartItem(itemId);
                      }
                    },
                    child: const Text('선택 상품 삭제'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 장바구니 목록 (테이블 형식)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 테이블 헤더
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: const [
                          SizedBox(width: 24), // 체크박스 영역
                          Expanded(
                            flex: 5,
                            child: Text(
                              '상품정보',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '수량',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '주문금액',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          SizedBox(width: 24), // 삭제 버튼 영역
                        ],
                      ),
                    ),

                    // 장바구니 아이템 목록
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cartItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        return _buildWebCartItem(_cartItems[index]);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 주문 정보 요약
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '결제 정보',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('상품 금액'),
                              const Spacer(),
                              Text(
                                '${_calculateTotalPrice().toStringAsFixed(0)}원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Text('배송비'),
                              Spacer(),
                              Text(
                                '무료',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                '결제 예정 금액',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_calculateTotalPrice().toStringAsFixed(0)}원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 200,
                      child: CustomButton(
                        text: '주문하기',
                        onPressed: _navigateToCheckout,
                        height: 56,
                        backgroundColor: AppTheme.primaryColor,
                      ),
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

  Widget _buildWebCartItem(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 24,
      ),
      child: Row(
        children: [
          // 체크박스
          Checkbox(
            value: _selectedItems.contains(item.id),
            onChanged: (_) => _toggleItemSelection(item.id),
            activeColor: AppTheme.primaryColor,
          ),

          // 상품 정보
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // 상품 이미지
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: item.productImage != null
                        ? CachedNetworkImage(
                            imageUrl: item.productImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // 상품명 및 가격
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.price.toStringAsFixed(0)}원',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 수량 조절
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (item.quantity > 1) {
                      _updateCartItemQuantity(item, item.quantity - 1);
                    }
                  },
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _updateCartItemQuantity(item, item.quantity + 1);
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // 주문 금액
          Expanded(
            flex: 2,
            child: Text(
              '${item.totalPrice.toStringAsFixed(0)}원',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),

          // 삭제 버튼
          IconButton(
            onPressed: () => _removeCartItem(item.id),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartLayout(bool isSmallScreen) {
    return Column(
      children: [
        // 상품 선택 영역
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Row(
            children: [
              Checkbox(
                value: _selectedItems.length == _cartItems.length,
                onChanged: (_) => _toggleAllSelection(),
                activeColor: AppTheme.primaryColor,
              ),
              const Text(
                '전체 선택',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // 선택 상품 삭제 기능
                  for (String itemId in _selectedItems.toList()) {
                    _removeCartItem(itemId);
                  }
                },
                child: const Text('선택 상품 삭제'),
              ),
            ],
          ),
        ),

        // 장바구니 목록
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 24.0,
            ),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              return _buildMobileCartItem(_cartItems[index], isSmallScreen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCartItem(CartItemModel item, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12.0 : 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스
          Checkbox(
            value: _selectedItems.contains(item.id),
            onChanged: (_) => _toggleItemSelection(item.id),
            activeColor: AppTheme.primaryColor,
          ),

          // 상품 이미지
          Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item.productImage != null
                  ? CachedNetworkImage(
                      imageUrl: item.productImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade400,
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
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeCartItem(item.id),
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 가격
                Text(
                  '${item.price.toStringAsFixed(0)}원',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),

                const SizedBox(height: 8),

                // 수량 조절
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (item.quantity > 1) {
                                _updateCartItemQuantity(
                                    item, item.quantity - 1);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 24,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _updateCartItemQuantity(item, item.quantity + 1);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // 합계 금액
                    Text(
                      '합계: ${item.totalPrice.toStringAsFixed(0)}원',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    // 로그인하지 않았거나 장바구니가 비어있으면 바텀바 표시하지 않음
    if (_authController.firebaseUser.value == null || _cartItems.isEmpty) {
      return null;
    }

    // 장바구니에 상품이 있는 경우 결제 정보 및 주문하기 버튼 표시
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
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
                  '총 상품금액',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_calculateTotalPrice().toStringAsFixed(0)}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '주문하기',
              onPressed: _navigateToCheckout,
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
