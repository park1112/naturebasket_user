import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_template/utils/format_helper.dart';
import 'package:get/get.dart';
import 'package:kpostal/kpostal.dart';
import '../../config/theme.dart';
import '../../controllers/address_controller.dart';
import '../../models/address_model.dart';
import '../../widgets/custom_button.dart';

class AddressTab extends StatefulWidget {
  const AddressTab({Key? key}) : super(key: key);

  @override
  State<AddressTab> createState() => _AddressTabState();
}

class _AddressTabState extends State<AddressTab> {
  final AddressController _addressController = Get.find<AddressController>();

  // 주소 폼 관련 컨트롤러
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();
  final TextEditingController _detailAddressController =
      TextEditingController();
  final TextEditingController _deliveryMessageController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 현재 편집 중인 주소 ID (null이면 신규 주소)
  String? _editingAddressId;

  // 새 주소 추가 모드 여부
  bool _isAddingNew = false;

  @override
  void dispose() {
    _addressNameController.dispose();
    _recipientController.dispose();
    _contactController.dispose();
    _addressTextController.dispose();
    _detailAddressController.dispose();
    _deliveryMessageController.dispose();
    super.dispose();
  }

  // 모든 입력 필드 초기화
  void _resetForm() {
    _addressNameController.clear();
    _recipientController.clear();
    _contactController.clear();
    _addressTextController.clear();
    _detailAddressController.clear();
    _deliveryMessageController.clear();
    _editingAddressId = null;
  }

  // 주소 편집 모드 시작
  void _startEditing(AddressModel address) {
    setState(() {
      _isAddingNew = true;
      _editingAddressId = address.id;

      _addressNameController.text = address.name;
      _recipientController.text = address.recipient;
      _contactController.text = address.contact;
      _addressTextController.text = address.address;
      _detailAddressController.text = address.detailAddress;
      _deliveryMessageController.text = address.deliveryMessage ?? '';
    });
  }

  // 주소 저장 (신규 또는 수정)
  void _saveAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      final newAddress = AddressModel(
          id: _editingAddressId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _addressNameController.text.trim(),
          recipient: _recipientController.text.trim(),
          contact: _contactController.text.trim(),
          address: _addressTextController.text.trim(),
          detailAddress: _detailAddressController.text.trim(),
          deliveryMessage: _deliveryMessageController.text.trim(),
          isDefault: _editingAddressId == null &&
              _addressController.addressList.isEmpty);

      if (_editingAddressId != null) {
        _addressController.updateAddress(newAddress);
      } else {
        _addressController.addAddress(newAddress);
      }

      setState(() {
        _isAddingNew = false;
        _resetForm();
      });
    }
  }

  // 주소 검색 다이얼로그 실행
  Future<void> _searchAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          useLocalServer: false,
          callback: (Kpostal result) {
            setState(() {
              _addressTextController.text =
                  '${result.address} (${result.postCode})';
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            // appBar: AppBar(
            //   title: const Text('주소록 관리'),
            //   centerTitle: true,
            //   actions: [
            //     if (!_isAddingNew)
            //       IconButton(
            //         icon: const Icon(Icons.add),
            //         onPressed: () {
            //           setState(() {
            //             _isAddingNew = true;
            //             _resetForm();
            //           });
            //         },
            //       ),
            //   ],
            // ),
            body: _isAddingNew
                ? _buildAddressForm(isSmallScreen)
                : _buildAddressList(isSmallScreen),
          ),
        );
      },
    );
  }

  // 주소 목록 화면
  Widget _buildAddressList(bool isSmallScreen) {
    return Obx(() {
      // 로딩 상태 확인
      if (_addressController.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('배송지 정보를 불러오는 중...'),
            ],
          ),
        );
      }

      final addresses = _addressController.addressList;

      if (addresses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('등록된 배송지가 없습니다', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              CustomButton(
                text: '배송지 추가',
                onPressed: () {
                  setState(() {
                    _isAddingNew = true;
                    _resetForm();
                  });
                },
                icon: Icons.add_location_alt,
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          ListView.separated(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            itemCount: addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(address);
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isAddingNew = true;
                  _resetForm();
                });
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    });
  }

  // 개별 주소 카드 위젯
  Widget _buildAddressCard(AddressModel address) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배송지명과 기본 배송지 표시를 Wrap으로 변경
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      address.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _startEditing(address);
                    } else if (value == 'setDefault') {
                      _addressController.setDefaultAddress(address.id);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(address.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 추가: 최소 크기로 설정
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'setDefault',
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 추가: 최소 크기로 설정
                          children: [
                            Icon(Icons.check_circle, size: 18),
                            SizedBox(width: 8),
                            Text('기본 배송지로 설정'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 추가: 최소 크기로 설정
                        children: [
                          Icon(Icons.delete,
                              size: 18, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('삭제',
                              style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // 주소 정보 표시
            _infoRow(Icons.person, '수령인', address.recipient),
            _infoRow(Icons.phone, '연락처', address.contact),
            _infoRow(Icons.location_on, '주소', address.address),
            _infoRow(Icons.house, '상세주소', address.detailAddress),
            if (address.deliveryMessage != null &&
                address.deliveryMessage!.isNotEmpty)
              _infoRow(Icons.message, '배송 메시지', address.deliveryMessage!),
            const SizedBox(height: 8),
            // 수정 및 선택 버튼을 Wrap으로 변경
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8, // 버튼 사이 간격
              runSpacing: 8, // 줄 사이 간격
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('수정'),
                  onPressed: () => _startEditing(address),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('선택'),
                  onPressed: () => _selectAddress(address),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 주소 선택
  void _selectAddress(AddressModel address) {
    // TODO: 주문 페이지로 선택된 주소 전달
    Get.back(result: address);
  }

  // 정보 표시 행 위젯 - Wrap으로 변경하여 오버플로우 방지
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 주소 삭제 확인 다이얼로그
  void _showDeleteConfirmation(String addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배송지 삭제'),
        content: const Text('이 배송지를 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _addressController.deleteAddress(addressId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 주소 추가/수정 폼
  Widget _buildAddressForm(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingAddressId != null ? '배송지 수정' : '새 배송지 추가',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 배송지명
            _buildFormField(
              controller: _addressNameController,
              label: '배송지명',
              hintText: '예: 집, 회사, 학교',
              prefixIcon: Icons.bookmark,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '배송지명을 입력해주세요';
                }
                return null;
              },
            ),

            // 수령인
            _buildFormField(
              controller: _recipientController,
              label: '수령인',
              hintText: '받는 분 성함',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '수령인을 입력해주세요';
                }
                return null;
              },
            ),

            // 연락처
            _buildFormField(
              controller: _contactController,
              label: '연락처',
              hintText: '010-0000-0000',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.number,
              inputFormatter: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneNumberFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '연락처를 입력해주세요';
                }
                if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(value)) {
                  return '올바른 연락처를 입력해주세요';
                }
                return null;
              },
            ),

            // 주소 검색
            _buildAddressSearchField(),

            // 상세 주소
            _buildFormField(
              controller: _detailAddressController,
              label: '상세주소',
              hintText: '상세주소를 입력해주세요',
              prefixIcon: Icons.house,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상세주소를 입력해주세요';
                }
                return null;
              },
            ),

            // 배송 메시지
            _buildFormField(
              controller: _deliveryMessageController,
              label: '배송 메시지 (선택)',
              hintText: '예: 부재시 경비실에 맡겨주세요',
              prefixIcon: Icons.message,
              maxLines: 2,
            ),

            // 폼 하단 버튼 - Wrap으로 변경
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: isSmallScreen ? double.infinity : 150,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingNew = false;
                        _resetForm();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                SizedBox(
                  width: isSmallScreen ? double.infinity : 150,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 주소 검색 필드
  Widget _buildAddressSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주소',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _searchAddress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // 세로 정렬 수정
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _addressTextController.text.isEmpty
                        ? '주소 검색'
                        : _addressTextController.text,
                    style: TextStyle(
                      color: _addressTextController.text.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                    overflow: TextOverflow.visible, // 텍스트 오버플로우 허용
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_addressTextController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              '주소를 검색해주세요',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 공통 폼 필드 위젯
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatter,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(prefixIcon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatter,
          ),
        ],
      ),
    );
  }
}
