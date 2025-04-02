// lib/screens/checkout/order_complete_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class OrderCompleteScreen extends StatelessWidget {
  const OrderCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 완료'),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;
          bool isWebLayout = constraints.maxWidth > 900;

          return Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: isWebLayout ? 800 : double.infinity,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 24.0 : 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 성공 아이콘
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 타이틀
                  const Text(
                    '주문이 완료되었습니다!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 주문번호
                  Text(
                    '주문번호: NATBSK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 주문 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('주문 일시', _formatDateTime(DateTime.now())),
                        const SizedBox(height: 12),
                        _buildInfoRow('결제 방법', '신용카드'),
                        const SizedBox(height: 12),
                        _buildInfoRow('주문 상태', '결제 완료'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '주문 내역은 마이페이지에서 확인할 수 있습니다.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '배송이 시작되면 알림을 통해 안내해 드립니다.',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // 주문 내역 페이지로 이동 (미구현)
                            Get.snackbar(
                              '알림',
                              '주문 내역 기능은 아직 구현되지 않았습니다.',
                              snackPosition: SnackPosition.TOP,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('주문 내역 보기'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: '쇼핑 계속하기',
                          onPressed: () {
                            Get.offAll(() => const HomeScreen());
                          },
                          backgroundColor: AppTheme.primaryColor,
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
