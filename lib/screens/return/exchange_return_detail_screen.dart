import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';
import '../product/product_detail_screen.dart';

class ExchangeReturnDetailScreen extends StatefulWidget {
  final String requestId;

  const ExchangeReturnDetailScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<ExchangeReturnDetailScreen> createState() =>
      _ExchangeReturnDetailScreenState();
}

class _ExchangeReturnDetailScreenState
    extends State<ExchangeReturnDetailScreen> {
  final OrderService _orderService = OrderService();

  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestData =
          await _orderService.getExchangeReturnRequestById(widget.requestId);

      if (requestData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '요청 정보를 찾을 수 없습니다';
        });
        return;
      }

      setState(() {
        _requestData = requestData.toJson();
        _isLoading = false;
      });
    } catch (e) {
      print('교환/반품 요청 상세 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '요청 정보를 불러오는 중 오류가 발생했습니다';
      });
    }
  }

  Future<void> _cancelRequest() async {
    // 취소 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('요청 취소'),
        content: const Text('정말 교환/반품 요청을 취소하시겠습니까?\n취소 후에는 다시 요청해야 합니다.'),
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
      _isSubmitting = true;
    });

    try {
      final success =
          await _orderService.cancelExchangeReturnRequest(widget.requestId);

      if (success) {
        Get.snackbar(
          '요청 취소',
          '교환/반품 요청이 취소되었습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );

        await _loadRequestDetails();
      } else {
        Get.snackbar(
          '오류',
          '요청 취소 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('요청 취소 중 오류: $e');
      Get.snackbar(
        '오류',
        '요청 취소 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '교환/반품 상세',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _errorMessage != null
              ? _buildErrorMessage()
              : _requestData == null
                  ? _buildRequestNotFound()
                  : _buildRequestDetails(),
      bottomNavigationBar: _isLoading ||
              _errorMessage != null ||
              _requestData == null ||
              _requestData!['status'] != 'pending'
          ? null
          : _buildBottomBar(),
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
              onPressed: _loadRequestDetails,
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

  Widget _buildRequestNotFound() {
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
              '요청을 찾을 수 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '요청 정보가 존재하지 않거나 삭제되었습니다.',
              style: GoogleFonts.notoSans(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                '이전 페이지로 돌아가기',
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

  Widget _buildRequestDetails() {
    String type = _requestData!['type']; // 'exchange' or 'return'
    String status = _requestData![
        'status']; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
    List<dynamic> items = _requestData!['items'] as List<dynamic>;
    DateTime requestDate = (_requestData!['requestDate'] as dynamic).toDate();

    // 요청 타입에 따른 텍스트 및 색상 설정
    String requestTypeText = type == 'exchange' ? '교환' : '반품';
    Color requestTypeColor =
        type == 'exchange' ? AppTheme.primaryColor : Colors.red.shade600;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 요청 상태 헤더
        _buildStatusHeader(requestTypeText, status, requestDate),
        const SizedBox(height: 24),

        // 주문 정보
        if (_requestData!.containsKey('orderInfo'))
          _buildOrderInfo(_requestData!['orderInfo'] as Map<dynamic, dynamic>),
        const SizedBox(height: 24),

        // 요청 사유
        _buildReasonInfo(),
        const SizedBox(height: 24),

        // 요청 상품 목록
        _buildRequestedItems(items),
        const SizedBox(height: 24),

        // 요청 처리 진행 상태
        _buildRequestProgress(),
        const SizedBox(height: 24),

        // 안내사항
        _buildInfoNote(requestTypeText),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatusHeader(
      String typeText, String status, DateTime requestDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$typeText 요청',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.5)),
                ),
                child: Text(
                  _getStatusText(status),
                  style: GoogleFonts.notoSans(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '요청일시: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(requestDate)}',
                style: GoogleFonts.notoSans(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '요청번호: ${_requestData!['id']}',
                style: GoogleFonts.notoSans(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(Map<dynamic, dynamic> orderInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Icons.receipt_long_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '주문 정보',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            '주문번호',
            orderInfo['id'].toString().length > 10
                ? '${orderInfo['id'].toString().substring(0, 10)}...'
                : orderInfo['id'].toString(),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            '주문일자',
            DateFormat('yyyy년 MM월 dd일')
                .format((orderInfo['orderDate'] as dynamic).toDate()),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            '결제금액',
            '${NumberFormat('#,###').format(orderInfo['total'])}원',
          ),
        ],
      ),
    );
  }

  Widget _buildReasonInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Icons.help_outline,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '요청 사유',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            '사유',
            _requestData!['reason'],
          ),
          if (_requestData!.containsKey('detailedReason') &&
              _requestData!['detailedReason'] != null &&
              _requestData!['detailedReason'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상세 사유',
                  style: GoogleFonts.notoSans(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _requestData!['detailedReason'],
                    style: GoogleFonts.notoSans(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestedItems(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Icons.shopping_bag_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '요청 상품',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items.map((item) => _buildItemCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Get.to(() => ProductDetailScreen(productId: item['productId']));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: item['productImage'] != null &&
                          item['productImage'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item['productImage'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                    Text(
                      item['productName'],
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.containsKey('selectedOptions') &&
                        item['selectedOptions'] != null &&
                        item['selectedOptions'] is Map &&
                        (item['selectedOptions'] as Map).isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _formatSelectedOptions(item['selectedOptions']),
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      '${NumberFormat('#,###').format(item['price'])}원 | ${item['quantity']}개',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: Colors.grey.shade800,
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

  Widget _buildRequestProgress() {
    String status = _requestData!['status'];
    String type = _requestData!['type']; // 'exchange' or 'return'
    String typeText = type == 'exchange' ? '교환' : '반품';

    // 요청 처리 단계
    List<String> stages = [];

    // 처리 단계 설정 (교환과 반품에 따라 다르게)
    if (type == 'exchange') {
      stages = ['요청 접수', '신청 확인', '회수 진행', '교환품 발송', '교환 완료'];
    } else {
      stages = ['요청 접수', '신청 확인', '회수 진행', '검수 완료', '환불 완료'];
    }

    // 현재 진행 단계 인덱스 (상태에 따라 다름)
    int currentStageIndex = 0;

    switch (status) {
      case 'pending':
        currentStageIndex = 0;
        break;
      case 'approved':
        currentStageIndex = 1;
        break;
      case 'processing':
        currentStageIndex = 2;
        break;
      case 'shipped': // 교환품 발송 상태
        currentStageIndex = 3;
        break;
      case 'completed':
        currentStageIndex = 4;
        break;
      case 'rejected': // 거부된 경우
      case 'cancelled': // 취소된 경우
        currentStageIndex = -1; // 진행 중지
        break;
      default:
        currentStageIndex = 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Icons.schedule,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '처리 진행 상태',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 진행 불가 상태일 경우 표시
          if (currentStageIndex < 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: status == 'rejected'
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: status == 'rejected'
                      ? Colors.red.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == 'rejected'
                        ? '$typeText 요청이 거부되었습니다'
                        : '$typeText 요청이 취소되었습니다',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      color: status == 'rejected'
                          ? Colors.red
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (_requestData!.containsKey('statusMessage') &&
                      _requestData!['statusMessage'] != null &&
                      _requestData!['statusMessage'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _requestData!['statusMessage'],
                      style: GoogleFonts.notoSans(
                        color: status == 'rejected'
                            ? Colors.red
                            : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // 진행 상태 표시줄
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
            const SizedBox(height: 16),

            // 상태 설명
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                bool isCurrent = index == currentStageIndex;
                bool isPast = index < currentStageIndex;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isPast || isCurrent
                              ? AppTheme.primaryColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPast || isCurrent
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isPast
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stages[index],
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: isCurrent
                              ? AppTheme.primaryColor
                              : isPast
                                  ? Colors.black
                                  : Colors.grey.shade600,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoNote(String typeText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                '$typeText 안내사항',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _requestData!['type'] == 'exchange'
                ? '• 교환 신청 후 배송된 상품을 먼저 반품해야 합니다.\n• 상품 불량/오배송의 경우 택배비를 부담하지 않습니다.\n• 단순 변심의 경우 왕복 택배비를 부담해야 합니다.\n• 교환 상품은 반품 확인 후 발송됩니다.'
                : '• 반품 신청 후 배송된 상품을 먼저 반품해야 합니다.\n• 상품 불량/오배송의 경우 택배비를 부담하지 않습니다.\n• 단순 변심의 경우 왕복 택배비를 부담해야 합니다.\n• 환불은 반품 상품 확인 후 처리됩니다.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: Colors.blue.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    String type = _requestData!['type']; // 'exchange' or 'return'
    Color typeColor =
        type == 'exchange' ? AppTheme.primaryColor : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _cancelRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '요청 취소하기',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatSelectedOptions(Map<dynamic, dynamic> options) {
    List<String> formattedOptions = [];
    options.forEach((key, value) {
      formattedOptions.add('$key: $value');
    });
    return formattedOptions.join(', ');
  }

  // 상태 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '처리 대기';
      case 'approved':
        return '승인됨';
      case 'processing':
        return '처리 중';
      case 'shipped':
        return '교환품 발송';
      case 'rejected':
        return '거부됨';
      case 'completed':
        return '완료됨';
      case 'cancelled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }

  // 상태 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'rejected':
        return Colors.red.shade700;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }
}
