import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/cart/cart_screen.dart';

import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../utils/custom_loading.dart';
import '../../utils/format_helper.dart';
import '../return/exchange_return_history_screen.dart';
import '../review/write_review_screen.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final AuthController _authController = Get.find<AuthController>();
  final CartController _cartController = Get.find<CartController>();
  final ProductController _productController = Get.find<ProductController>();

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 검색 기능을 위한 변수
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
        '장바구니에 추가하려면 로그인이 필요합니다.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final product = await _productService.getProduct(item.productId);
      if (product == null) {
        Get.snackbar(
          '오류',
          '상품 정보를 찾을 수 없습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }
      ProductOption? selectedOption;
      if (item.optionId != null &&
          item.optionId!.isNotEmpty &&
          product.options != null) {
        final optionData = product.options![item.optionId!];
        if (optionData != null) {
          selectedOption = ProductOption.fromMap(optionData, item.optionId!);
        }
      }
      await _cartController.addToCart(
          product, item.quantity, selectedOption?.id);
      // 다이얼로그에 쇼핑 계속하기와 장바구니 이동 버튼 추가
      Get.dialog(
        AlertDialog(
          title: const Text('장바구니에 상품이 담겼습니다'),
          content: const Text('장바구니로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // 다이얼로그 닫기 → 계속 쇼핑
              child: const Text('쇼핑 계속하기'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // 다이얼로그 닫기
                Get.to(() => CartScreen()); // 장바구니 페이지 이동
              },
              child: const Text('장바구니 이동'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('장바구니 추가 오류: $e');
      Get.snackbar(
        '오류',
        '장바구니에 상품을 추가하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 리뷰 작성 화면으로 이동하는 함수
  void _navigateToReviewScreen(CartItemModel item, OrderModel order) {
    Get.to(() => WriteReviewScreen(
          orderId: order.id,
          productId: item.productId,
          productName: item.productName,
          productImage: item.productImage,
        ));
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '주문목록',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Get.back(),
        // ),
        actions: [
          // 교환/반품 내역 버튼 추가
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: '교환/반품 내역',
            onPressed: () {
              Get.to(() => const ExchangeReturnHistoryScreen());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '주문한 상품을 검색할 수 있어요!',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 전체 상품 장바구니 담기 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: InkWell(
              onTap: () {
                Get.snackbar(
                  '알림',
                  '전체 상품을 장바구니에 담았습니다.',
                  snackPosition: SnackPosition.TOP,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    '전체 상품 장바구니 담기',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 주문 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: Colors.blue,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '다시 시도',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '주문 내역이 없습니다',
          style:
              GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  // 주문 카드: 주문 요약, 상태 표시, 주문한 전체 상품 목록 표시
  Widget _buildOrderCard(OrderModel order) {
    // 전체 주문에 대해, 만약 주문한 상품 중 일부만 교환/반품 신청되었으면 부분 신청으로 표시
    bool hasExchangeReturnRequest = order.exchangeReturnRequestIds != null &&
        order.exchangeReturnRequestIds!.isNotEmpty;
    bool isPartial = false;
    if (hasExchangeReturnRequest) {
      // 예시: 전체 주문 상품 수와 교환/반품 요청된 상품 수 비교
      // (실제 구현에서는 주문 문서에 ‘전체 신청’인지 부분 신청인지를 나타내는 필드를 추가할 수 있음)
      isPartial = order.items.length > order.exchangeReturnRequestIds!.length;
    }

    String statusText;
    if (hasExchangeReturnRequest && isPartial) {
      statusText = getStatusText(order) + ' (부분 신청중)';
    } else {
      statusText = getStatusText(order);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => OrderDetailScreen(orderId: order.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주문 요약 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '주문번호: ${order.id}',
                    style: GoogleFonts.notoSans(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 주문 상세 정보 (예: 주문일, 총액 등)
              Row(
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(order.orderDate),
                    style: GoogleFonts.notoSans(
                        fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    FormatHelper.formatPrice(order.total),
                    style: GoogleFonts.notoSans(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 20),
              // 주문한 상품 목록
              Column(
                children: order.items
                    .map((item) => _buildOrderItemCard(item, order))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 주문한 상품 카드 (기존 _buildOrderItemCard 수정)
  Widget _buildOrderItemCard(CartItemModel item, OrderModel order) {
    final optionText = (item.optionName != null && item.optionName!.isNotEmpty)
        ? item.optionName
        : '';
    final hasExtendedDelivery = item.productName.toLowerCase().contains("글루텐");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // 상품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: item.productImage != null && item.productImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.productImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
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
                if (hasExtendedDelivery)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch,
                            size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 2),
                        Text(
                          '+2일',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  item.productName,
                  style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w500, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (optionText != null && optionText.isNotEmpty)
                  Text(
                    optionText,
                    style: GoogleFonts.notoSans(
                        fontSize: 13, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      FormatHelper.formatPrice(item.price),
                      style: GoogleFonts.notoSans(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' · ${item.quantity}개',
                      style: GoogleFonts.notoSans(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 장바구니 버튼
          TextButton(
            onPressed: () => _addToCart(item),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              '장바구니 담기',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 액션 버튼 위젯
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // 주문 상태 텍스트 반환 (기존 _getStatusText 수정)
  String getStatusText(OrderModel order) {
    if (order.status == OrderStatus.pending) return '주문 접수';
    if (order.status == OrderStatus.confirmed) return '결제 완료';
    if (order.status == OrderStatus.processing) return '처리 중';
    if (order.status == OrderStatus.shipping) return '배송 중';
    if (order.status == OrderStatus.delivered) {
      // 배송완료 이후에 교환/반품 요청이 일부 있는 경우
      if (order.exchangeReturnRequestIds != null &&
          order.exchangeReturnRequestIds!.isNotEmpty &&
          order.items.length > order.exchangeReturnRequestIds!.length) {
        return '배송 완료 (부분 신청중)';
      }
      return '배송 완료';
    }
    if (order.status == OrderStatus.cancelled) return '주문 취소';
    if (order.status == OrderStatus.refunded) return '환불 완료';
    if (order.status == OrderStatus.exchangeRequested) return '교환 요청';
    if (order.status == OrderStatus.returnRequested) return '반품 요청';
    return '배송 완료';
  }

  // 주문 상태 색상 반환 (부분 신청 여부 고려)
  Color _getStatusColor(OrderModel order) {
    if (order.status == OrderStatus.pending) return Colors.blue;
    if (order.status == OrderStatus.confirmed) return Colors.green;
    if (order.status == OrderStatus.processing) return Colors.purple;
    if (order.status == OrderStatus.shipping) return Colors.orange;
    if (order.status == OrderStatus.delivered) {
      if (order.exchangeReturnRequestIds != null &&
          order.exchangeReturnRequestIds!.isNotEmpty &&
          order.items.length > order.exchangeReturnRequestIds!.length) {
        return Colors.amber; // 부분 신청 색상
      }
      return Colors.green;
    }
    if (order.status == OrderStatus.cancelled) return Colors.red;
    if (order.status == OrderStatus.refunded) return Colors.grey;
    if (order.status == OrderStatus.exchangeRequested) return Colors.purple;
    if (order.status == OrderStatus.returnRequested) return Colors.indigo;
    return Colors.green;
  }
}
