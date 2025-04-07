import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../utils/format_helper.dart';
import '../../widgets/custom_button.dart';

class OrderFailureScreen extends StatelessWidget {
  final double totalAmount;
  final String errorMessage;

  const OrderFailureScreen({
    Key? key,
    required this.totalAmount,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 실패'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              '결제에 실패하였습니다.',
              style: GoogleFonts.notoSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '총 결제 금액: ${FormatHelper.formatPrice(totalAmount)}',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: '홈으로 돌아가기',
              onPressed: () => Get.offAllNamed('/main'),
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
