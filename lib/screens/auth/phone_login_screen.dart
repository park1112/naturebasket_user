import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/auth/verification_code_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../utils/custom_loading.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'KR');
  bool _isCodeSent = false;
  String? _phoneError;

  // 직접 입력 형식화를 위한 컨트롤러 및 변수
  final TextEditingController _formattedPhoneController =
      TextEditingController();
  String _rawPhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _formattedPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('전화번호 로그인', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          return Stack(
            children: [
              _buildPhoneLoginContent(),
              if (_authController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CustomLoading(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPhoneLoginContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;

        return SingleChildScrollView(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // 외부 탭시 키보드 닫기
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      '전화번호 인증',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isCodeSent
                          ? '인증 코드를 입력해주세요.'
                          : '전화번호를 입력하면 인증 코드를 보내드립니다.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isCodeSent
                        ? _buildVerificationCodeForm()
                        : _buildPhoneInputForm(),
                    // 키보드 공간 확보
                    SizedBox(height: isSmallScreen ? 100 : 150),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전화번호 입력 필드
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _phoneError != null ? Colors.red : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: _formattedPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.phone_android,
                color: AppTheme.primaryColor,
              ),
              hintText: '010-0000-0000',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              _KoreanPhoneNumberFormatter(),
            ],
            onChanged: (value) {
              _rawPhoneNumber = value.replaceAll('-', '');
              _phoneNumber = PhoneNumber(
                phoneNumber:
                    '+82${_rawPhoneNumber.startsWith('0') ? _rawPhoneNumber.substring(1) : _rawPhoneNumber}',
                isoCode: 'KR',
                dialCode: '+82',
              );
              _phoneController.text = _rawPhoneNumber;

              if (_phoneError != null) {
                setState(() {
                  _phoneError = null;
                });
              }
            },
          ),
        ),

        // 오류 메시지
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _phoneError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // 인증 코드 받기 버튼
        CustomButton(
          text: '인증 코드 받기',
          onPressed: _requestVerificationCode,
          isLoading: _authController.isLoading.value,
          backgroundColor: AppTheme.primaryColor,
          height: 56,
        ),
      ],
    );
  }

  Widget _buildVerificationCodeForm() {
    return Column(
      children: [
        const SizedBox(height: 10),
        // 인증 코드 안내 텍스트
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '입력하신 전화번호로 발송된 6자리 인증코드를 입력해주세요.',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // 6자리 인증 코드 입력 박스
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _smsCodeController,
            keyboardType: TextInputType.number,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              selectedFillColor: AppTheme.primaryColor.withOpacity(0.1),
              activeColor: AppTheme.primaryColor,
              inactiveColor: Colors.grey.shade300,
              selectedColor: AppTheme.primaryColor,
              borderWidth: 1.5,
            ),
            enableActiveFill: true,
            cursorColor: AppTheme.primaryColor,
            animationDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            onChanged: (value) {
              // 필요한 경우 인증 코드 변경 핸들링
            },
            beforeTextPaste: (text) {
              // 붙여넣기 검증 (숫자만 허용)
              return text?.contains(RegExp(r'^[0-9]{6}$')) ?? false;
            },
          ),
        ),

        const SizedBox(height: 30),

        // 시간 카운트다운 표시
        Text(
          '03:00',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 30),

        // 버튼 그룹
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: '다시 요청',
                onPressed: _requestVerificationCode,
                isOutlined: true,
                backgroundColor: AppTheme.primaryColor,
                height: 52,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: '인증하기',
                onPressed: _verifyCode,
                isLoading: _authController.isLoading.value,
                backgroundColor: AppTheme.primaryColor,
                height: 52,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // PhoneLoginScreen 클래스 내부의 _requestVerificationCode 메서드 수정
  void _requestVerificationCode() async {
    // 전화번호 검증 강화
    if (_rawPhoneNumber.isEmpty) {
      setState(() {
        _phoneError = '전화번호를 입력해주세요.';
      });
      return;
    }

    // 한국 전화번호 형식 검증
    if (!_rawPhoneNumber.startsWith('010') || _rawPhoneNumber.length != 11) {
      setState(() {
        _phoneError = '올바른 전화번호 형식이 아닙니다. (예: 010-1234-5678)';
      });
      return;
    }

    try {
      // 전화번호 검증
      String phoneNumber = _phoneNumber.phoneNumber ?? '';
      if (phoneNumber.isEmpty) {
        setState(() {
          _phoneError = AppConstants.errorInvalidPhoneNumber;
        });
        return;
      }

      // 인증 코드 요청
      await _authController.verifyPhoneNumber(phoneNumber);

      // 기존 코드: 상태 변경으로 같은 화면에서 인증 코드 입력 UI 표시
      // setState(() {
      //   _isCodeSent = true;
      //   _phoneError = null;
      // });

      // 새로운 코드: 별도 화면으로 이동
      Get.to(() => VerificationCodeScreen(
            phoneNumber: _formattedPhoneController.text, // 또는 phoneNumber 변수
          ));
    } catch (e) {
      Get.snackbar(
        '오류',
        '인증 코드 요청 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _verifyCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _authController.verifyPhoneCode(_smsCodeController.text);
      } catch (e) {
        Get.snackbar(
          '인증 오류',
          '인증 코드 확인 중 오류가 발생했습니다: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

// 한국 전화번호 형식 (010-1234-5678) 포맷터
class _KoreanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 전화번호 형식에 맞게 하이픈 추가
    final formattedValue = _formatKoreanPhoneNumber(digitsOnly);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: formattedValue.length,
      ),
    );
  }

  String _formatKoreanPhoneNumber(String digits) {
    // 최대 11자리까지만 유효하게 처리
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    // 번호 형식 지정 (010-xxxx-xxxx)
    if (digits.length <= 3) {
      // 3자리 이하: 그대로 표시
      return digits;
    } else if (digits.length <= 7) {
      // 4-7자리: 010-1234
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      // 8자리 이상: 010-1234-5678
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
  }
}
