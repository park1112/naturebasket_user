// lib/screens/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/models/user_model.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/cart_item_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/custom_loading.dart';
import 'order_complete_screen.dart';
import '../../utils/format_helper.dart';
import 'package:kpostal/kpostal.dart';
import '../../widgets/address_selector_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AuthController _authController = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();
  final _requestController = TextEditingController();
  final _addressDetailFocusNode = FocusNode();

  bool _isLoading = false;
  String _selectedPaymentMethod = '신용카드';
  bool _saveShippingInfo = true;
  AddressModel selectedAddress = AddressModel(
    id: '',
    name: '',
    phoneNumber: '',
    zipCode: '',
    address: '',
    addressDetail: '',
  );

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    if (_authController.userModel.value != null) {
      final user = _authController.userModel.value!;

      _nameController.text = user.name ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _requestController.dispose();
    _addressDetailFocusNode.dispose();
    super.dispose();
  }

  double _calculateTotalPrice() {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        '알림',
        '배송 정보를 모두 입력해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 주문 처리 로직을 구현할 수 있습니다.
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      Get.off(
        () => const OrderCompleteScreen(),
        arguments: {
          'totalAmount': _calculateTotalPrice(), // 총 결제 금액 전달
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문/결제'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _buildCheckoutContent(),
    );
  }

  Widget _buildCheckoutContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isWebLayout = constraints.maxWidth > 900;

        if (isWebLayout) {
          return _buildWebCheckoutLayout();
        } else {
          return _buildMobileCheckoutLayout(isSmallScreen);
        }
      },
    );
  }

  Widget _buildWebCheckoutLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 배송 정보 폼
                Expanded(
                  flex: 7,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDeliveryInfoSection(),
                        const SizedBox(height: 32),
                        _buildPaymentMethodSection(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // 오른쪽: 주문 요약
                Expanded(
                  flex: 5,
                  child: _buildOrderSummary(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCheckoutLayout(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryInfoSection(),
            const SizedBox(height: 32),
            _buildPaymentMethodSection(),
            const SizedBox(height: 32),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            CustomButton(
              text: '결제하기',
              onPressed: _placeOrder,
              backgroundColor: AppTheme.primaryColor,
              height: 56,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '배송 정보',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // 수령인
        CustomTextField(
          label: '수령인',
          hint: '받으시는 분의 이름을 입력해주세요',
          controller: _nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '수령인 이름을 입력해주세요';
            }
            return null;
          },
        ),

        // 연락처
        PhoneTextField(
          controller: _phoneController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '연락처를 입력해주세요';
            }
            if (value.length < 10) {
              return '올바른 연락처를 입력해주세요';
            }
            return null;
          },
        ),

        // 배송지 주소 (우편번호 + 기본주소)
        _buildAddressInput(),

        // 상세 주소
        CustomTextField(
          label: '상세 주소',
          hint: '나머지 주소를 입력해주세요',
          controller: _addressDetailController,
          focusNode: _addressDetailFocusNode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '상세 주소를 입력해주세요';
            }
            return null;
          },
        ),

        // 배송 요청사항
        CustomTextField(
          label: '배송 요청사항 (선택)',
          hint: '배송 시 요청사항을 입력해주세요',
          controller: _requestController,
          maxLines: 2,
        ),

        // 배송지 정보 저장
        Row(
          children: [
            Checkbox(
              value: _saveShippingInfo,
              onChanged: (value) {
                setState(() {
                  _saveShippingInfo = value ?? true;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            const Text('이 배송지 정보 저장하기'),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressInput() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 예시로 400px 이하인 경우 Column으로 변경합니다.
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: '주소',
                hint: '우편번호 검색',
                controller: _addressController,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주소를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await _searchAddress();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('주소 검색'),
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: '주소',
                  hint: '우편번호 검색',
                  controller: _addressController,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '주소를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: () async {
                    await _searchAddress();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('주소 검색'),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 수단',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 결제 수단 라디오 버튼
        _buildPaymentMethodRadio('신용카드', '신용/체크카드로 결제합니다'),
        _buildPaymentMethodRadio('계좌이체', '계좌이체로 결제합니다'),
        _buildPaymentMethodRadio('휴대폰결제', '휴대폰 소액결제로 결제합니다'),
        _buildPaymentMethodRadio('무통장입금', '안내된 계좌로 입금합니다'),

        const SizedBox(height: 16),

        // 결제 동의
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Text(
                    '주문 내용을 확인하였으며, 결제에 동의합니다.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '주문 내용 및 배송 정보를 확인하였으며, 구매 조건 및 결제에 동의합니다. 결제 시 네이처바스켓 이용약관 및 개인정보 처리방침에 동의한 것으로 간주됩니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRadio(String value, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == value
              ? AppTheme.primaryColor
              : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        title: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (newValue) {
          setState(() {
            _selectedPaymentMethod = newValue!;
          });
        },
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주문 요약',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 주문 상품 목록
          ...widget.cartItems.map((item) => _buildOrderItem(item)).toList(),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // 결제 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('상품 금액'),
              Text(
                FormatHelper.formatPrice(_calculateTotalPrice()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('배송비'),
              Text(
                '무료',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 결제 금액',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                FormatHelper.formatPrice(_calculateTotalPrice()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 데스크톱 화면에서만 결제 버튼 표시
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWebLayout = MediaQuery.of(context).size.width > 900;

              if (isWebLayout) {
                return CustomButton(
                  text: '결제하기',
                  onPressed: _placeOrder,
                  backgroundColor: AppTheme.primaryColor,
                  height: 56,
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item.productImage != null
                  ? CachedNetworkImage(
                      imageUrl: item.productImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade400,
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
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${FormatHelper.formatPrice(item.price)} • ${item.quantity}개',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 주문 금액
          Text(
            FormatHelper.formatPrice(item.totalPrice),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAddress() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KpostalView(
            useLocalServer: false,
            callback: (Kpostal result) {
              setState(() {
                _addressController.text =
                    '[${result.postCode}] ${result.address}';
                FocusScope.of(context).requestFocus(_addressDetailFocusNode);
              });
            },
          ),
        ),
      );
    } catch (e) {
      print('Error searching address: $e');
      Get.snackbar(
        '오류',
        '주소 검색 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '배송지 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AddressSelectorWidget(
          onAddressSelected: (address) {
            // 선택된 주소 처리
            setState(() {
              selectedAddress = address;
            });
          },
        ),
      ],
    );
  }
}
