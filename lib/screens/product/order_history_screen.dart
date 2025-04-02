import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final AuthController _authController = Get.find<AuthController>();

  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
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
      final orders = await _orderService.getUserOrders(
        _authController.firebaseUser.value!.uid,
      );
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 내역'),
      ),
      body:
          _isLoading ? const Center(child: CustomLoading()) : _buildOrderList(),
    );
  }

  Widget _buildOrderList() {
    if (_orders.isEmpty) {
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
            const Text(
              '주문 내역이 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '아직 주문한 상품이 없습니다.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        return ListView.separated(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          itemCount: _orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildOrderItem(_orders[index], isSmallScreen);
          },
        );
      },
    );
  }

  Widget _buildOrderItem(OrderModel order, bool isSmallScreen) {
    return InkWell(
      onTap: () {
        Get.to(() => OrderDetailScreen(orderId: order.id));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주문 정보 헤더
            Row(
              children: [
                Text(
                  '주문번호: ${order.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: order.status.color.withOpacity(0.5)),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: order.status.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '주문일자: ${DateFormat('yyyy년 MM월 dd일').format(order.orderDate)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            const Divider(height: 24),
            // 주문 상품 목록 (최대 2개)
            ...order.items
                .take(2)
                .map((item) => _buildOrderItemRow(order, isSmallScreen))
                .toList(),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '외 ${order.items.length - 2}개 상품',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('결제 금액'),
                    Text(
                      '${NumberFormat('#,###').format(order.total.toInt())}원',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {
                    Get.to(() => OrderDetailScreen(orderId: order.id));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('상세보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderModel item, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (item.items[0].product?.imageUrl != null) // null 체크 추가
            Container(
              width: isSmallScreen ? 40 : 60,
              height: isSmallScreen ? 40 : 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: item.items[0].product?.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            )
          else
            Container(
              width: isSmallScreen ? 40 : 60,
              height: isSmallScreen ? 40 : 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey.shade400,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.items[0].product?.name ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${NumberFormat('#,###').format(item.items[0].product?.sellingPrice.toInt() ?? 0)}원 · ${item.items[0].quantity}개',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(item.items[0].product?.sellingPrice.toInt() ?? 0)}원',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
