import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';

class ExchangeReturnScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? order;

  const ExchangeReturnScreen({
    Key? key,
    required this.orderId,
    this.order,
  }) : super(key: key);

  @override
  State<ExchangeReturnScreen> createState() => _ExchangeReturnScreenState();
}

class _ExchangeReturnScreenState extends State<ExchangeReturnScreen> {
  final OrderService _orderService = OrderService();

  OrderModel? _order;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // 교환/반품 방식 선택
  String _selectedType = 'exchange'; // 'exchange' or 'return'

  // 교환/반품 사유
  String? _selectedReason;
  final TextEditingController _detailReasonController = TextEditingController();

  // 선택된 상품 목록
  final Map<String, bool> _selectedItems = {};

  // 반품/교환 가능 여부
  bool _isEligibleForReturnOrExchange = true;
  String? _eligibilityMessage;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      setState(() {
        _order = widget.order;
        _isLoading = false;
        _initializeSelectedItems();
        _checkEligibility();
      });
    } else {
      _loadOrderDetails();
    }
  }

  @override
  void dispose() {
    _detailReasonController.dispose();
    super.dispose();
  }

  // 교환/반품 가능 여부 확인
  void _checkEligibility() {
    if (_order == null) return;

    // 주문 상태가 취소됐거나 환불 처리된 경우 불가
    if (_order!.status == OrderStatus.cancelled ||
        _order!.status == OrderStatus.refunded) {
      _isEligibleForReturnOrExchange = false;
      _eligibilityMessage = '취소 또는 환불된 주문은 교환/반품이 불가능합니다.';
      return;
    }

    // 배송 완료 후 7일 이내만 교환/반품 가능 (예시 정책)
    if (_order!.deliveryInfo.deliveredAt != null) {
      final deliveredDate = _order!.deliveryInfo.deliveredAt!;
      final now = DateTime.now();
      final difference = now.difference(deliveredDate).inDays;

      if (difference > 7) {
        _isEligibleForReturnOrExchange = false;
        _eligibilityMessage = '배송 완료 후 7일이 지난 상품은 교환/반품이 불가능합니다.';
        return;
      }
    }

    // 배송중이거나 배송완료 상태만 교환/반품 가능
    if (_order!.status != OrderStatus.shipping &&
        _order!.status != OrderStatus.delivered) {
      _isEligibleForReturnOrExchange = false;
      _eligibilityMessage = '배송 중이거나 배송 완료된 상품만 교환/반품이 가능합니다.';
      return;
    }
  }

  // 선택된 상품 목록 초기화
  void _initializeSelectedItems() {
    if (_order == null) return;

    for (var item in _order!.items) {
      _selectedItems[item.id] = false;
    }
  }

  // 주문 상세 정보 로드
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
        _initializeSelectedItems();
        _checkEligibility();
      });
    } catch (e) {
      print('주문 상세 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '주문 정보를 불러오는 중 오류가 발생했습니다';
      });
    }
  }

  // 교환/반품 신청 처리
  Future<void> _submitRequest() async {
    // 선택된 상품이 없는 경우
    final selectedProductIds = _selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedProductIds.isEmpty) {
      Get.snackbar(
        '알림',
        '교환/반품할 상품을 선택해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // 사유 선택 확인
    if (_selectedReason == null) {
      Get.snackbar(
        '알림',
        '교환/반품 사유를 선택해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // 진행 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedType == 'exchange' ? '교환 신청' : '반품 신청'),
        content: Text(
            '선택한 상품의 ${_selectedType == 'exchange' ? '교환' : '반품'}을 진행하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 진행 중 로딩 다이얼로그 표시
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 20),
              Text('${_selectedType == 'exchange' ? '교환' : '반품'} 요청 처리 중...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // 선택된 상품 목록
      final selectedItems = _order!.items
          .where((item) => _selectedItems[item.id] == true)
          .toList();

      // 교환/반품 요청 생성

      final success = await _orderService.createExchangeReturnRequest(
        orderId: widget.orderId,
        type: _selectedType,
        reason: _selectedReason!,
        detailedReason: _detailReasonController.text,
        items: selectedItems,
      );
      print('교환/반품 신청 처리 결과: $success');

      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (success) {
        // 처리 성공
        Get.snackbar(
          '신청 완료',
          '${_selectedType == 'exchange' ? '교환' : '반품'} 신청이 완료되었습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );

        // 성공 다이얼로그 (선택 사항)
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text('신청 완료'),
              ],
            ),
            content: Text(
              '${_selectedType == 'exchange' ? '교환' : '반품'} 신청이 완료되었습니다.\n요청 처리 상태는 교환/반품 내역에서 확인할 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // 다이얼로그 닫기
                  Get.back(result: true); // 이전 화면으로 돌아가기
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        // 처리 실패
        Get.snackbar(
          '오류',
          '${_selectedType == 'exchange' ? '교환' : '반품'} 신청 중 문제가 발생했습니다. 다시 시도해주세요.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      print('교환/반품 신청 중 오류: $e');
      Get.snackbar(
        '오류',
        '${_selectedType == 'exchange' ? '교환' : '반품'} 신청 중 오류가 발생했습니다: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 5),
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
          '교환/반품 신청',
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
              : _order == null
                  ? _buildOrderNotFound()
                  : !_isEligibleForReturnOrExchange
                      ? _buildNotEligible()
                      : _buildExchangeReturnForm(),
      bottomNavigationBar: _isLoading ||
              _errorMessage != null ||
              _order == null ||
              !_isEligibleForReturnOrExchange
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
              onPressed: _loadOrderDetails,
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
            Text(
              '주문을 찾을 수 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '주문 정보가 존재하지 않거나 삭제되었습니다.',
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

  Widget _buildNotEligible() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '교환/반품 불가',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _eligibilityMessage ?? '현재 교환/반품이 불가능한 상품입니다.',
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

  Widget _buildExchangeReturnForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 주문 정보 요약
        _buildOrderSummary(),
        const SizedBox(height: 16),

        // 교환/반품 선택 토글
        _buildTypeSelector(),
        const SizedBox(height: 24),

        // 교환/반품할 상품 선택
        _buildProductSelection(),
        const SizedBox(height: 24),

        // 교환/반품 사유 선택
        _buildReasonSelector(),
        const SizedBox(height: 16),

        // 상세 사유 입력
        _buildDetailedReasonInput(),
        const SizedBox(height: 24),

        // 교환/반품 안내사항
        _buildInformationNote(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            _order!.id.length > 20
                ? '${_order!.id.substring(0, 20)}...'
                : _order!.id,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            '주문일자',
            DateFormat('yyyy년 MM월 dd일').format(_order!.orderDate),
          ),
          if (_order!.deliveryInfo.deliveredAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              '배송완료일',
              DateFormat('yyyy년 MM월 dd일')
                  .format(_order!.deliveryInfo.deliveredAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'exchange';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'exchange'
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '교환',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'exchange'
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'return';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'return'
                      ? Colors.red.shade600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '반품',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'return'
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedType == 'exchange' ? '교환' : '반품'}할 상품 선택',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                bool allSelected = !_selectedItems.values.contains(false);
                setState(() {
                  for (var key in _selectedItems.keys) {
                    _selectedItems[key] = !allSelected;
                  }
                });
              },
              child: Text(
                _selectedItems.values.contains(false) ? '전체 선택' : '전체 해제',
                style: GoogleFonts.notoSans(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._order!.items.map((item) => _buildProductItem(item)).toList(),
      ],
    );
  }

  Widget _buildProductItem(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 체크박스
          Checkbox(
            value: _selectedItems[item.id] ?? false,
            onChanged: (value) {
              setState(() {
                _selectedItems[item.id] = value ?? false;
              });
            },
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // 상품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: item.productImage != null && item.productImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.productImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.selectedOptions != null &&
                      item.selectedOptions!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _formatSelectedOptions(item.selectedOptions!),
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    '${NumberFormat('#,###').format(item.price.toInt())}원 | ${item.quantity}개',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelector() {
    final reasons = _selectedType == 'exchange'
        ? [
            '상품 불량/파손',
            '상품 오배송',
            '상품 정보와 상이',
            '단순 변심',
            '다른 상품으로 교환 원함',
            '기타',
          ]
        : [
            '상품 불량/파손',
            '상품 오배송',
            '상품 정보와 상이',
            '단순 변심',
            '배송 지연',
            '기타',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedType == 'exchange' ? '교환' : '반품'} 사유',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              hint: Text(
                '사유를 선택해주세요',
                style: GoogleFonts.notoSans(
                  color: Colors.grey.shade600,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
              style: GoogleFonts.notoSans(
                color: Colors.black,
                fontSize: 16,
              ),
              onChanged: (String? value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              items: reasons.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 사유 (선택사항)',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _detailReasonController,
            decoration: InputDecoration(
              hintText: '상세 사유를 입력해주세요',
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              hintStyle: GoogleFonts.notoSans(
                color: Colors.grey.shade500,
              ),
            ),
            style: GoogleFonts.notoSans(),
            maxLines: 4,
            minLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationNote() {
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
                '${_selectedType == 'exchange' ? '교환' : '반품'} 안내사항',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedType == 'exchange'
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
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'exchange'
                      ? AppTheme.primaryColor
                      : Colors.red.shade600,
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
                        '${_selectedType == 'exchange' ? '교환' : '반품'} 신청하기',
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

  String _formatSelectedOptions(Map<String, dynamic> options) {
    List<String> formattedOptions = [];
    options.forEach((key, value) {
      formattedOptions.add('$key: $value');
    });
    return formattedOptions.join(', ');
  }
}
