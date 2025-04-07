import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../services/order_service.dart';
import '../../utils/custom_loading.dart';
import 'exchange_return_detail_screen.dart';

class ExchangeReturnHistoryScreen extends StatefulWidget {
  const ExchangeReturnHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeReturnHistoryScreen> createState() =>
      _ExchangeReturnHistoryScreenState();
}

class _ExchangeReturnHistoryScreenState
    extends State<ExchangeReturnHistoryScreen> {
  final OrderService _orderService = OrderService();
  final AuthController _authController = Get.find<AuthController>();

  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 검색 기능을 위한 컨트롤러 및 변수
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
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

  Future<void> _loadRequests() async {
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
      final requests = await _orderService.getExchangeReturnRequests(
        _authController.firebaseUser.value!.uid,
      );
      setState(() {
        // 요청 객체를 JSON으로 변환해서 리스트에 저장
        _requests = requests
            .map((request) => (request as dynamic)?.toJson() ?? {})
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('교환/반품 요청 목록 조회 중 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '요청 정보를 불러오는 중 오류가 발생했습니다';
      });
    }
  }

  // 검색어에 따른 필터링된 요청 목록 반환
  List<dynamic> get _filteredRequests {
    if (_searchQuery.isEmpty) {
      return _requests;
    }
    return _requests.where((request) {
      if (request['id'].toString().toLowerCase().contains(_searchQuery))
        return true;
      if (request['orderId'].toString().toLowerCase().contains(_searchQuery))
        return true;
      // 요청 내 상품들에서 상품명 검색
      for (var item in (request['items'] as List<dynamic>)) {
        if (item['productName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  // 요청 취소 다이얼로그 표시 후 취소 처리
  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '요청 취소',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '교환/반품 요청을 취소하시겠습니까?\n취소 후에는 다시 요청해야 합니다.',
          style: GoogleFonts.notoSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '아니오',
              style: GoogleFonts.notoSans(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _cancelRequest(requestId);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text('예, 취소합니다', style: GoogleFonts.notoSans()),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      final success =
          await _orderService.cancelExchangeReturnRequest(requestId);
      if (success) {
        Get.snackbar(
          '요청 취소',
          '교환/반품 요청이 취소되었습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
        await _loadRequests();
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
    }
  }

  // 상태 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '처리 대기';
      case 'approved':
        return '승인됨';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '교환/반품 내역',
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
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '교환/반품 요청을 검색할 수 있어요!',
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
          // 요청 목록 (새로고침 지원)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRequests,
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(child: CustomLoading())
                  : _errorMessage != null
                      ? _buildErrorMessage()
                      : _buildRequestList(),
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다',
              style: GoogleFonts.notoSans(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '다시 시도해주세요.',
              style: GoogleFonts.notoSans(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                '다시 시도',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    final filteredRequests = _filteredRequests;
    if (filteredRequests.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '검색 결과가 없습니다',
                style: GoogleFonts.notoSans(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '다른 검색어로 다시 시도해보세요',
                style: GoogleFonts.notoSans(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sync_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '교환/반품 내역이 없습니다',
              style: GoogleFonts.notoSans(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '아직 교환/반품 신청한 내역이 없습니다.',
              style: GoogleFonts.notoSans(color: Colors.grey.shade600),
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
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                '쇼핑하러 가기',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    // 그룹화: 요청 날짜별로 묶기
    Map<String, List<Map<String, dynamic>>> requestsByDate = {};
    for (var request in filteredRequests) {
      DateTime reqDate = (request['requestDate'] as dynamic).toDate();
      final dateStr = DateFormat('yyyy. M. d').format(reqDate);
      if (!requestsByDate.containsKey(dateStr)) {
        requestsByDate[dateStr] = [];
      }
      requestsByDate[dateStr]!.add(request);
    }
    List<String> sortedDates = requestsByDate.keys.toList()
      ..sort((a, b) => DateFormat('yyyy. M. d')
          .parse(b)
          .compareTo(DateFormat('yyyy. M. d').parse(a)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dateRequests = requestsByDate[dateStr]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 12),
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
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppTheme.primaryColor),
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
            // 해당 날짜의 요청 카드 목록
            ...dateRequests
                .map((request) => _buildRequestCard(request))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    String type = request['type']; // 'exchange' or 'return'
    String status = request['status'];
    List<dynamic> items = request['items'] as List<dynamic>;
    DateTime reqDate = (request['requestDate'] as dynamic).toDate();

    String requestTypeText = type == 'exchange' ? '교환' : '반품';
    Color requestTypeColor =
        type == 'exchange' ? AppTheme.primaryColor : Colors.red.shade600;

    String statusText = _getStatusText(status);
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역: 요청 타입, 요청일시, 상태
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: requestTypeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border.all(color: requestTypeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: requestTypeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        requestTypeText,
                        style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '요청 ${DateFormat('MM/dd HH:mm').format(reqDate)}',
                      style: GoogleFonts.notoSans(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          // 주문 정보 (주문번호 요약)
          if (request.containsKey('orderInfo'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_outlined,
                      size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '주문번호: ${(request['orderInfo'] as Map)['id'].toString().substring(0, 8)}...',
                    style: GoogleFonts.notoSans(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          // 상품 요약 및 요청 사유 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 요약: 첫 상품명 + 추가 건수
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.notoSans(
                              fontSize: 14, color: Colors.black),
                          children: [
                            TextSpan(
                              text: items[0]['productName'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (items.length > 1)
                              TextSpan(
                                text: ' 외 ${items.length - 1}건',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 요청 사유
                if (request.containsKey('reason'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '요청 사유',
                          style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 4),
                        Text(request['reason'],
                            style: GoogleFonts.notoSans(fontSize: 14)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // 액션 버튼들
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => ExchangeReturnDetailScreen(
                              requestId: request['id']));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: requestTypeColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text('상세보기',
                            style: GoogleFonts.notoSans(
                                color: requestTypeColor,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: status == 'pending'
                            ? () => _showCancelDialog(request['id'])
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'pending'
                              ? requestTypeColor
                              : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text('요청 취소',
                            style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
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
}
