import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kpostal/kpostal.dart';
import 'package:flutter_login_template/models/user_model.dart'
    show AddressModel;

/// 재사용 가능한 배송지 입력 폼 위젯
class AddressSelectorWidget extends StatefulWidget {
  /// 주소가 입력되었을 때 호출되는 콜백
  final Function(AddressModel)? onAddressSelected;

  const AddressSelectorWidget({
    Key? key,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSelectorWidget> createState() => _AddressSelectorWidgetState();
}

class _AddressSelectorWidgetState extends State<AddressSelectorWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  /// 주소 검색을 위한 함수: KpostalView를 실행하고 결과를 텍스트 필드에 업데이트합니다.
  Future<void> _searchAddress() async {
    try {
      final Kpostal? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KpostalView(
            useLocalServer: false, // 원격 서버 사용. 필요시 true로 변경 후 설정
            kakaoKey: dotenv.env['KAKAO_JS_KEY'] ?? '',
          ),
        ),
      );
      if (result != null) {
        setState(() {
          _addressController.text = '[${result.postCode}] ${result.address}';
        });
      }
    } catch (e) {
      Get.snackbar(
        '주소 검색 오류',
        '주소 검색 중 문제가 발생했습니다. 다시 시도해주세요.',
        backgroundColor: Colors.red.shade50,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// 폼 검증 후 AddressModel 생성 및 콜백 호출
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final String addressText = _addressController.text;
      if (!addressText.contains(']')) {
        Get.snackbar('입력 오류', '주소를 올바르게 검색해주세요.');
        return;
      }
      final zipCode = addressText.substring(1, addressText.indexOf(']'));
      final mainAddress = addressText.substring(addressText.indexOf(']') + 2);
      final newAddress = AddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        zipCode: zipCode,
        address: mainAddress,
        addressDetail: _detailController.text.trim(),
        isDefault: false, // 필요에 따라 기본 배송지 여부 설정
      );
      if (widget.onAddressSelected != null) {
        widget.onAddressSelected!(newAddress);
      }
      // 폼 초기화(선택 사항)
      _formKey.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '배송지명',
              hintText: '예: 집, 회사',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '배송지명을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(
              labelText: '수령인',
              hintText: '받으실 분의 이름',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '수령인을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '연락처',
              hintText: '- 없이 숫자만 입력',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '연락처를 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _searchAddress,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '주소 검색',
                  suffixIcon: Icon(Icons.search),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주소를 검색해주세요';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _detailController,
            decoration: const InputDecoration(
              labelText: '상세주소',
              hintText: '나머지 주소를 입력해주세요',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '상세주소를 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
