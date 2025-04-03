import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';
import '../product/product_detail_screen.dart';
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await _orderService.getOrderById(widget.orderId);

      if (order == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '주문 정보를 찾을 수 없습니다';
        });
        return;
      }

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      print('주문 상세 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '주문 정보를 불러오는 중 오류가 발생했습니다';
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
      print('주문 취소 오류: $e');
      Get.snackbar(
        '오류',
        '주문 취소 중 오류가 발생했습니다.',
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
          : _errorMessage != null
              ? _buildErrorMessage()
              : _order == null
                  ? _buildOrderNotFound()
                  : _buildOrderDetails(),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '주문 정보를 불러오는 중 문제가 발생했습니다.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotFound() {
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
            const Text(
              '주문을 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '주문 정보가 존재하지 않거나 삭제되었습니다.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('이전 페이지로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600 ? 16.0 : 24.0;
        final isWebLayout = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: isWebLayout
              ? _buildWebLayout(constraints.maxWidth)
              : _buildMobileLayout(),
        );
      },
    );
  }

  Widget _buildWebLayout(double screenWidth) {
    // 웹 레이아웃 너비 제한
    final contentWidth = screenWidth > 1200 ? 1200.0 : screenWidth * 0.9;

    return Center(
      child: SizedBox(
        width: contentWidth,
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
            const SizedBox(width: 24),
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
                  _buildStatusHistory(),
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

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrderStatusHeader(),
        const SizedBox(height: 24),
        _buildOrderInfoCard(),
        const SizedBox(height: 24),
        _buildShippingInfoCard(),
        const SizedBox(height: 24),
        _buildStatusHistory(),
        const SizedBox(height: 24),
        _buildOrderItems(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildOrderStatusHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주문 번호 및 상태 - 오버플로우 방지를 위해 Wrap 사용
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '주문번호: ${_order!.id.length > 8 ? _order!.id.substring(0, 8) : _order!.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
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
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.shipping,
      OrderStatus.delivered,
    ];

    // 현재 상태가 목록에 없으면 기본값으로 설정
    int currentStageIndex = stages.indexOf(_order!.status);
    if (currentStageIndex == -1) currentStageIndex = 0;

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
        // 상태 텍스트 - 모바일에서 오버플로우 방지를 위해 크기 조절
        LayoutBuilder(builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 500;
          final textSize = isSmall ? 10.0 : 12.0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '주문 접수',
                style: TextStyle(
                  fontSize: textSize,
                  color: currentStageIndex >= 0
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: currentStageIndex == 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                '결제 완료',
                style: TextStyle(
                  fontSize: textSize,
                  color: currentStageIndex >= 1
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: currentStageIndex == 1
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                '처리 중',
                style: TextStyle(
                  fontSize: textSize,
                  color: currentStageIndex >= 2
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: currentStageIndex == 2
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                '배송 중',
                style: TextStyle(
                  fontSize: textSize,
                  color: currentStageIndex >= 3
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: currentStageIndex == 3
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                '배송 완료',
                style: TextStyle(
                  fontSize: textSize,
                  color: currentStageIndex >= 4
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: currentStageIndex == 4
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildOrderItems() {
    if (_order!.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '주문 상품 정보가 없습니다',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 너비에 따라 그리드 열 수 동적 조정
              int crossAxisCount =
                  _calculateCrossAxisCount(constraints.maxWidth);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _order!.items.length,
                itemBuilder: (context, index) {
                  final item = _order!.items[index];
                  return _buildOrderItemCard(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 화면 너비에 따라 그리드 열 수 계산
  int _calculateCrossAxisCount(double width) {
    if (width < 300) return 1;
    if (width < 500) return 2;
    if (width < 700) return 3;
    return 4;
  }

  Widget _buildOrderItemCard(CartItemModel item) {
    return InkWell(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: item.productId));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상품 이미지 (더 큰 비중으로)
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: _buildProductImageSimple(item),
              ),
            ),

            // 상품 정보
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상품명
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 옵션 정보 (있을 경우)
                    if (item.selectedOptions != null &&
                        item.selectedOptions!.isNotEmpty)
                      Text(
                        _formatSelectedOptions(item.selectedOptions!),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // 가격 및 수량 정보
                    Column(
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(item.price.toInt())}원',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '수량: ${item.quantity}개',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 간소화된 이미지 위젯 (그리드 전용)
  Widget _buildProductImageSimple(CartItemModel item) {
    return item.productImage != null && item.productImage!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: item.productImage!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              alignment: Alignment.center,
              color: Colors.grey.shade100,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              alignment: Alignment.center,
              color: Colors.grey.shade100,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
              ),
            ),
          )
        : Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey.shade400,
            ),
          );
  }

  // 상품 이미지 위젯
  Widget _buildProductImage(CartItemModel item, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.productImage != null && item.productImage!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.productImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey.shade400,
                    size: size * 0.3,
                  ),
                ),
              )
            : Container(
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                  size: size * 0.3,
                ),
              ),
      ),
    );
  }

  // 상품 옵션 표시
  Widget _buildProductOptions(CartItemModel item) {
    if (item.selectedOptions == null || item.selectedOptions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      _formatSelectedOptions(item.selectedOptions!),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '결제 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('결제 방법', _order!.paymentMethod ?? '미지정'),
          const SizedBox(height: 12),
          _buildInfoRow('주문 상태', _order!.statusText),
          const SizedBox(height: 12),
          _buildInfoRow('상품 금액',
              '${NumberFormat('#,###').format(_order!.subtotal.toInt())}원'),
          const SizedBox(height: 12),
          _buildInfoRow(
              '배송비',
              _order!.shippingFee > 0
                  ? '${NumberFormat('#,###').format(_order!.shippingFee.toInt())}원'
                  : '무료'),
          if (_order!.tax > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
                '부가세', '${NumberFormat('#,###').format(_order!.tax.toInt())}원'),
          ],
          const Divider(height: 24),
          _buildInfoRow('총 결제 금액',
              '${NumberFormat('#,###').format(_order!.total.toInt())}원',
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    Map<String, dynamic>? deliveryInfo = _order?.deliveryInfo.toMap();

    if (deliveryInfo == null || deliveryInfo.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text('배송 정보가 없습니다'),
      );
    }

    String addressDetail = '';
    if (deliveryInfo['addressDetail'] != null &&
        deliveryInfo['addressDetail'].toString().isNotEmpty) {
      addressDetail = deliveryInfo['addressDetail'].toString();
    }

    String fullAddress = deliveryInfo['address']?.toString() ?? '';
    if (addressDetail.isNotEmpty) {
      fullAddress += ' $addressDetail';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '배송 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('받는 사람', deliveryInfo['name']?.toString() ?? ''),
          const SizedBox(height: 12),
          _buildInfoRow('연락처', deliveryInfo['phoneNumber']?.toString() ?? ''),
          const SizedBox(height: 12),
          _buildInfoRow('배송지', fullAddress),
          if (deliveryInfo['request'] != null &&
              deliveryInfo['request'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('배송 요청사항', deliveryInfo['request'].toString()),
          ],
        ],
      ),
    );
  }

  // 주문 상태 변경 기록 보기
  Widget _buildStatusHistory() {
    if (_order!.statusUpdates == null || _order!.statusUpdates!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '주문 처리 내역',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          ...List.generate(_order!.statusUpdates!.length, (index) {
            final update = _order!.statusUpdates![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(update.statusEnum),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy년 MM월 dd일 HH:mm').format(update.date),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (update.message != null &&
                            update.message!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              update.message!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).reversed.toList(), // 최신 기록이 위에 오도록 역순 정렬
        ],
      ),
    );
  }

  // 정보 행 위젯 - Row 대신 Wrap 사용 (Flexible 제거)
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
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
                  child: ElevatedButton.icon(
                    onPressed: _cancelOrder,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('주문 취소하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
        else
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '취소 불가능 안내',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '처리가 시작된 주문은 취소가 불가능합니다. 고객센터로 문의해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('주문 목록으로 돌아가기'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatSelectedOptions(Map<String, dynamic> options) {
    List<String> formattedOptions = [];
    options.forEach((key, value) {
      formattedOptions.add('$key: $value');
    });
    return formattedOptions.join(', ');
  }

  // 주문 상태 텍스트 반환
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '결제 완료';
      case OrderStatus.processing:
        return '상품 준비 중';
      case OrderStatus.shipping:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
      default:
        return '알 수 없음';
    }
  }
}
