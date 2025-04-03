import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/product/product_detail_screen.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../utils/custom_loading.dart';
import 'dart:convert';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final AuthController _authController = Get.find<AuthController>();
  late CartService _cartService;

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 검색 기능을 위한 변수
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cartService = CartService();
    _loadOrders();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (_authController.firebaseUser.value == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '로그인이 필요합니다';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getUserOrders(
        _authController.firebaseUser.value!.uid,
      );

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('사용자 주문 목록 조회 중 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '주문 정보를 불러오는 중 오류가 발생했습니다';
      });
    }
  }

  // 장바구니에 상품 추가하는 함수
  Future<void> _addToCart(CartItemModel item) async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar(
        '로그인 필요',
        '장바구니 이용을 위해 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // 임시 상품 모델 생성 (실제 구현시 상품 ID로 상품 정보를 조회해야 함)
      final productModel = ProductModel(
        id: item.productId,
        name: item.productName,
        description: '',
        images: item.productImage != null ? [item.productImage!] : [],
        imageUrls: item.productImage != null ? [item.productImage!] : [],
        price: item.price,
        sellingPrice: item.price,
        stock: 999, // 임시값
        category: ProductCategory.food,
        isEco: false,
        isOrganic: false,
        stockQuantity: 999, // 임시값
        averageRating: 0,
        reviewCount: 0,
        discountRate: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _cartService.addToCart(
        _authController.firebaseUser.value!.uid,
        productModel,
        1, // 기본 수량 1개
        item.selectedOptions != null ? json.encode(item.selectedOptions) : null,
      );

      if (success) {
        Get.snackbar(
          '장바구니 추가 완료',
          '${item.productName}을(를) 장바구니에 담았습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          '장바구니 추가 실패',
          '상품을 장바구니에 담는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('장바구니 추가 오류: $e');
      Get.snackbar(
        '오류',
        '장바구니에 상품을 추가하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // 필터링된 주문 목록 반환
  List<OrderModel> get _filteredOrders {
    if (_searchQuery.isEmpty) {
      return _orders;
    }

    return _orders.where((order) {
      // 주문 번호로 검색
      if (order.id.toLowerCase().contains(_searchQuery)) {
        return true;
      }

      // 제품명으로 검색
      for (var item in order.items) {
        if (item.productName.toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // appBar: AppBar(
      //   title: Text(
      //     '주문목록',
      //     style: GoogleFonts.notoSans(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 18,
      //     ),
      //   ),
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Get.back(),
      //   ),
      // ),
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '주문한 상품을 검색할 수 있어요!',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),

          // 주문 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(child: CustomLoading())
                  : _errorMessage != null
                      ? _buildErrorMessage()
                      : _buildOrderList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '다시 시도해주세요.',
              style: GoogleFonts.notoSans(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                '다시 시도',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        // 검색 결과가 없는 경우
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '검색 결과가 없습니다',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '다른 검색어로 다시 시도해보세요',
                style: GoogleFonts.notoSans(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // 주문 내역 자체가 없는 경우
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '주문 내역이 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '아직 주문한 상품이 없습니다.',
              style: GoogleFonts.notoSans(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.toNamed('/main'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                '쇼핑하러 가기',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 날짜별로 주문 그룹화
    Map<String, List<OrderModel>> ordersByDate = {};
    for (var order in filteredOrders) {
      final dateStr = DateFormat('yyyy. M. d').format(order.orderDate);
      if (!ordersByDate.containsKey(dateStr)) {
        ordersByDate[dateStr] = [];
      }
      ordersByDate[dateStr]!.add(order);
    }

    // 날짜 기준으로 정렬된 키 목록
    List<String> sortedDates = ordersByDate.keys.toList()
      ..sort((a, b) => DateFormat('yyyy. M. d').parse(b).compareTo(
            DateFormat('yyyy. M. d').parse(a),
          )); // 최신 날짜가 위로

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dateOrders = ordersByDate[dateStr]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더 (더 귀여운 스타일)
            Container(
              margin: const EdgeInsets.only(
                top: 20,
                bottom: 12,
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
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
            ),

            // 해당 날짜의 주문 목록
            ...dateOrders.map((order) => _buildOrderCard(order)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 배송 상태 헤더 (곡선형 디자인)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusBackgroundColor(order.status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(order.status),
                          size: 14,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(order.status),
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Get.to(() => OrderDetailScreen(orderId: order.id));
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '상세보기',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_right,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 주문 상품 리스트
          ...order.items.map((item) => _buildOrderItemCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade50,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // 상품 상세 페이지로 이동
          Get.to(() => ProductDetailScreen(productId: item.productId));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 정보 부분
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 이미지 (더 둥근 테두리)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: item.productImage != null
                          ? CachedNetworkImage(
                              imageUrl: item.productImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
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
                        // +2일 배지가 있을 경우 표시
                        if (item.productName.contains("글루텐"))
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.rocket_launch,
                                  size: 12,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+2일',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 상품명
                        Text(
                          item.productName,
                          style: GoogleFonts.notoSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 상품 옵션 (있을 경우 표시)
                        if (item.selectedOptions != null &&
                            item.selectedOptions!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatSelectedOptions(item.selectedOptions!),
                              style: GoogleFonts.notoSans(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        // 가격 및 수량
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${NumberFormat('#,###').format(item.price.toInt())}원',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1,
                              height: 10,
                              color: Colors.grey.shade300,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantity}개',
                                style: GoogleFonts.notoSans(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 액션 버튼 영역 (인라인)
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.sync_alt,
                    label: '교환/반품',
                    color: Colors.grey.shade700,
                    backgroundColor: Colors.grey.shade100,
                    onPressed: () {
                      Get.snackbar(
                        '교환/반품 신청',
                        '${item.productName}에 대한 교환/반품을 신청합니다.',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.local_shipping_outlined,
                    label: '배송조회',
                    color: Colors.blue,
                    backgroundColor: Colors.blue.shade50,
                    onPressed: () {
                      Get.snackbar(
                        '배송조회',
                        '${item.productName}에 대한 배송 정보를 조회합니다.',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.shopping_cart_outlined,
                    label: '장바구니',
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    onPressed: () => _addToCart(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아기자기한 액션 버튼 위젯
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 주문 상태 텍스트 반환
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '결제 완료';
      case OrderStatus.processing:
        return '처리 중';
      case OrderStatus.shipping:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
      default:
        return '문앞 전달';
    }
  }

  // 주문 상태 아이콘 반환
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.receipt_outlined;
      case OrderStatus.confirmed:
        return Icons.payment_outlined;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipping:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.refunded:
        return Icons.replay_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // 주문 상태 색상 반환
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipping:
        return Colors.orange;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 주문 상태 배경색 반환
  Color _getStatusBackgroundColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.blue.shade400;
      case OrderStatus.confirmed:
        return Colors.green.shade400;
      case OrderStatus.processing:
        return Colors.purple.shade400;
      case OrderStatus.shipping:
        return Colors.orange.shade400;
      case OrderStatus.delivered:
        return Colors.green.shade400;
      case OrderStatus.cancelled:
        return Colors.red.shade400;
      case OrderStatus.refunded:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
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
