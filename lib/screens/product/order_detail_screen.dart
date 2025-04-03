import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';
import '../product/product_detail_screen.dart';
import '../../controllers/order_controller.dart';
import '../../models/cart_item_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();

  OrderModel? _order;
  bool _isLoading = true;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final order = await _orderService.getOrderDetails(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    // 취소 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: const Text('정말 주문을 취소하시겠습니까?\n취소 후에는 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('예, 취소합니다'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCanceling = true;
    });

    try {
      final success = await _orderService.cancelOrder(widget.orderId);

      if (success) {
        Get.snackbar(
          '주문 취소',
          '주문이 성공적으로 취소되었습니다.',
          snackPosition: SnackPosition.TOP,
        );
        await _loadOrderDetails();
      } else {
        Get.snackbar(
          '오류',
          '주문 취소 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('Error canceling order: $e');
      Get.snackbar(
        '오류',
        '주문 취소 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isCanceling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _order == null
              ? _buildOrderNotFound()
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '주문을 찾을 수 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '주문 정보가 존재하지 않거나 삭제되었습니다.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('이전 페이지로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isWebLayout = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: isWebLayout
              ? _buildWebLayout()
              : _buildMobileLayout(isSmallScreen),
        );
      },
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 주문 상품 목록
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderStatusHeader(),
                  const SizedBox(height: 24),
                  _buildOrderItems(),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // 오른쪽: 주문 정보 및 배송지 정보
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfoCard(),
                  const SizedBox(height: 24),
                  _buildShippingInfoCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrderStatusHeader(),
        const SizedBox(height: 24),
        _buildOrderItems(),
        const SizedBox(height: 24),
        _buildOrderInfoCard(),
        const SizedBox(height: 24),
        _buildShippingInfoCard(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildOrderStatusHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주문 번호 및 상태
        Row(
          children: [
            Text(
              '주문번호: ${_order!.id.substring(0, min(_order!.id.length, 8))}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _order!.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _order!.status.color.withOpacity(0.5),
                ),
              ),
              child: Text(
                _order!.statusText,
                style: TextStyle(
                  color: _order!.status.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 주문일 / 배송일 / 배송완료일
        Text(
          '주문일: ${DateFormat('yyyy년 MM월 dd일').format(_order!.orderDate)}',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        if (_order!.deliveryInfo.shippedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '배송시작일: ${DateFormat('yyyy년 MM월 dd일').format(_order!.deliveryInfo.shippedAt!)}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        if (_order!.deliveryInfo.deliveredAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '배송완료일: ${DateFormat('yyyy년 MM월 dd일').format(_order!.deliveryInfo.deliveredAt!)}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        const SizedBox(height: 16),
        // 진행 상태 표시줄 (취소가 아닌 경우)
        if (_order!.status != OrderStatus.cancelled) _buildOrderProgress(),
      ],
    );
  }

  Widget _buildOrderProgress() {
    const stages = [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.shipping,
      OrderStatus.delivered,
    ];

    int currentStageIndex = stages.indexOf(_order!.status);

    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (index) {
            bool isCompleted = index <= currentStageIndex;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '주문 접수',
              style: TextStyle(
                fontSize: 12,
                color: currentStageIndex >= 0
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
                fontWeight: currentStageIndex == 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              '처리 중',
              style: TextStyle(
                fontSize: 12,
                color: currentStageIndex >= 1
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
                fontWeight: currentStageIndex == 1
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              '배송 중',
              style: TextStyle(
                fontSize: 12,
                color: currentStageIndex >= 2
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
                fontWeight: currentStageIndex == 2
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              '배송 완료',
              style: TextStyle(
                fontSize: 12,
                color: currentStageIndex >= 3
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
                fontWeight: currentStageIndex == 3
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주문 상품',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                _order!.items.map((item) => _buildOrderItemCard(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지
          if (item.productImage != null)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.productImage ?? '',
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey.shade400,
              ),
            ),
          const SizedBox(width: 16),
          // 상품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.selectedOptions != null &&
                    item.selectedOptions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _formatSelectedOptions(item.selectedOptions!),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${NumberFormat('#,###').format(item.price.toInt())}원',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '수량: ${item.quantity}개',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.to(
                          () => ProductDetailScreen(productId: item.productId));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('상품 상세보기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedOptions(Map<String, dynamic> options) {
    List<String> formattedOptions = [];
    options.forEach((key, value) {
      formattedOptions.add('$key: $value');
    });
    return formattedOptions.join(', ');
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('결제 방법', _order!.paymentMethod ?? '미지정'),
          const SizedBox(height: 12),
          _buildInfoRow('주문 상태', _order!.statusText),
          const SizedBox(height: 12),
          _buildInfoRow('상품 금액',
              '${NumberFormat('#,###').format(_order!.total.toInt())}원'),
          const SizedBox(height: 12),
          _buildInfoRow('배송비', '무료'),
          const SizedBox(height: 12),
          _buildInfoRow('총 결제 금액',
              '${NumberFormat('#,###').format(_order!.total.toInt())}원',
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '배송 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('받는 사람', _order!.deliveryInfo.name),
          const SizedBox(height: 12),
          _buildInfoRow('연락처', _order!.deliveryInfo.phoneNumber),
          const SizedBox(height: 12),
          _buildInfoRow('배송지', _order!.deliveryInfo.address),
          if (_order!.deliveryInfo.request != null &&
              _order!.deliveryInfo.request!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('배송 요청사항', _order!.deliveryInfo.request!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // 주문 접수 상태일 때만 취소 가능
    bool canCancel = _order!.status == OrderStatus.pending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_order!.status == OrderStatus.cancelled)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '주문이 취소되었습니다',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                SizedBox(height: 4),
                Text(
                  '취소된 주문은 복구할 수 없습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          )
        else if (canCancel)
          _isCanceling
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('주문 취소하기'),
                  ),
                )
        else
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '취소 불가능 안내',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '처리가 시작된 주문은 취소가 불가능합니다. 고객센터로 문의해주세요.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('주문 목록으로 돌아가기'),
          ),
        ),
      ],
    );
  }

  // dart:math의 min 함수를 대체
  int min(int a, int b) => a < b ? a : b;
}
