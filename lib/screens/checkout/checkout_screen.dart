import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/address_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart' as address;
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/custom_loading.dart';
import 'order_complete_screen.dart';
import '../../utils/format_helper.dart';
import '../../screens/profile/address_tab.dart';
// 포트원 결제 서비스 임포트
import 'package:flutter_login_template/services/portone_payment_service.dart';
import 'order_failure_screen.dart'; // 아래에 생성할 주문 실패 페이지

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
  final AddressController _addressController = Get.find<AddressController>();
  final CartController _cartController = Get.find<CartController>();
  final OrderService _orderService = OrderService();
  // 포트원 결제 서비스 인스턴스 추가
  final PortOnePaymentService _portOnePaymentService = PortOnePaymentService();

  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();

  bool _isLoading = false;
  String _selectedPaymentMethod = '신용카드';
  String? _orderId;

  // 선택된 배송지 (주소 목록에서 선택)
  Rx<address.AddressModel?> selectedAddress = Rx<address.AddressModel?>(null);

  @override
  void initState() {
    super.initState();
    // 사용자 정보가 업데이트되면 기본 배송지를 로드
    ever(_authController.userModel, (_) {
      _loadDefaultAddress();
    });
    if (_authController.userModel.value != null) {
      _loadDefaultAddress();
    }
  }

  void _loadDefaultAddress() {
    if (_addressController.addressList.isEmpty) {
      final user = _authController.userModel.value;
      if (user != null) {
        selectedAddress.value = address.AddressModel(
          id: '',
          name: '기본 배송지',
          recipient: user.name ?? '',
          contact: user.phoneNumber ?? '',
          address: '',
          detailAddress: '',
          deliveryMessage: '',
          isDefault: true,
        );
      } else {
        selectedAddress.value = address.AddressModel.empty();
      }
      return;
    }
    final defaultAddress = _addressController.addressList.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => _addressController.addressList.first);
    selectedAddress.value = defaultAddress;
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  double _calculateTotalPrice() {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// 주문 생성 후 포트원 결제 처리 및 결제 실패 시 주문 실패 페이지로 이동
  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        '알림',
        '배송 정보를 모두 입력해주세요.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    _orderService.placeOrder(
      context: context,
      authController: _authController,
      cartController: _cartController,
      cartItems: widget.cartItems,
      selectedAddress: selectedAddress.value,
      requestText: _requestController.text,
      paymentMethod: _selectedPaymentMethod,
      setLoadingState: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
      onComplete: (orderId) async {
        if (orderId != null) {
          double amount = _calculateTotalPrice();
          String customerName = selectedAddress.value?.recipient ??
              _authController.userModel.value?.name ??
              '';
          String customerTel = selectedAddress.value?.contact ??
              _authController.userModel.value?.phoneNumber ??
              '';

          // 포트원 결제 처리 호출
          Map<String, dynamic>? paymentResult =
              await _portOnePaymentService.processPayment(
            context: context,
            orderId: orderId,
            amount: amount,
            orderName: '주문 #$orderId',
            customerName: customerName,
            customerTel: customerTel,
          );

          if (paymentResult != null && paymentResult['success'] == true) {
            // 결제 성공 시 주문 결제 상태 업데이트
            await _orderService.updatePaymentStatus(
              orderId,
              true,
              transactionId: paymentResult['imp_uid'] ??
                  'txn_${DateTime.now().millisecondsSinceEpoch}',
              paymentMethod:
                  paymentResult['payment_method'] ?? _selectedPaymentMethod,
              paymentDetails: paymentResult,
            );

            Get.snackbar(
              '결제 성공',
              '결제가 완료되었습니다.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );

            // 결제 성공 후 주문 완료 화면으로 이동
            Get.off(
              () => OrderCompleteScreen(orderId: orderId),
              arguments: {'totalAmount': amount},
            );
          } else {
            String errorMessage = paymentResult != null
                ? (paymentResult['message'] ?? '결제 처리 중 문제가 발생했습니다.')
                : '결제가 취소되었습니다.';
            // 결제 실패 시 주문 실패 페이지로 이동
            Get.off(
              () => OrderFailureScreen(
                  totalAmount: amount, errorMessage: errorMessage),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          Get.snackbar(
            '오류',
            '주문 처리 중 오류가 발생했습니다.',
            snackPosition: SnackPosition.TOP,
          );
        }
      },
    );
  }

  void _openAddressSelection() async {
    final result = await Get.to(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('배송지 변경'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: const AddressTab(),
      ),
    );
    if (result != null && result is address.AddressModel) {
      setState(() {
        selectedAddress.value = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주문/결제'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : isWebLayout
              ? _buildWebCheckoutLayout(screenWidth)
              : _buildMobileCheckoutLayout(screenWidth),
    );
  }

  Widget _buildWebCheckoutLayout(double screenWidth) {
    final contentWidth = screenWidth * 0.8;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: contentWidth * 0.6,
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
              SizedBox(
                width: contentWidth * 0.4 - 32,
                child: _buildOrderSummary(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCheckoutLayout(double screenWidth) {
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Obx(() => _buildSelectedAddressCard()),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('배송지 변경'),
            onPressed: _openAddressSelection,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: '배송 요청사항 (선택)',
          hint: '배송 시 요청사항을 입력해주세요',
          controller: _requestController,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSelectedAddressCard() {
    if (selectedAddress.value == null ||
        selectedAddress.value!.recipient.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            '배송지를 선택해주세요',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final addr = selectedAddress.value!;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                addr.name.isNotEmpty ? addr.name : '배송지',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (addr.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '기본',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          _infoRow('수령인', addr.recipient),
          _infoRow('연락처', addr.contact),
          _infoRow('주소', '${addr.address} ${addr.detailAddress}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 수단',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodRadio('신용카드', '신용/체크카드로 결제합니다'),
        _buildPaymentMethodRadio('계좌이체', '계좌이체로 결제합니다'),
        _buildPaymentMethodRadio('휴대폰결제', '휴대폰 소액결제로 결제합니다'),
        _buildPaymentMethodRadio('무통장입금', '안내된 계좌로 입금합니다'),
        const SizedBox(height: 16),
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
                  const Expanded(
                    child: Text(
                      '주문 내용을 확인하였으며, 결제에 동의합니다.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (newValue) {
          setState(() {
            _selectedPaymentMethod = newValue!;
          });
        },
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...widget.cartItems.map((item) => _buildOrderItem(item)).toList(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                FormatHelper.formatPrice(_calculateTotalPrice()),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (MediaQuery.of(context).size.width > 900)
            CustomButton(
              text: '결제하기',
              onPressed: _placeOrder,
              backgroundColor: AppTheme.primaryColor,
              height: 56,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${FormatHelper.formatPrice(item.price)} • ${item.quantity}개',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            FormatHelper.formatPrice(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

extension AddressModelExtension on address.AddressModel {
  static address.AddressModel empty() {
    return address.AddressModel(
      id: '',
      name: '',
      recipient: '',
      contact: '',
      address: '',
      detailAddress: '',
      isDefault: false,
    );
  }
}
