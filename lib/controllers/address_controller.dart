import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';
import '../controllers/auth_controller.dart';

class AddressController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxList<AddressModel> addressList = <AddressModel>[].obs;
  RxBool isLoading = false.obs;

  // 사용자 ID 가져오기
  String? get userId => _authController.userModel.value?.uid;

  @override
  void onInit() {
    super.onInit();
    _listenToAddresses();
  }

  // 배송지 컬렉션 참조 가져오기
  CollectionReference _getAddressesRef() {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }

  // 실시간으로 배송지 목록 감시
  void _listenToAddresses() {
    if (userId == null) return;

    isLoading.value = true;

    _getAddressesRef().snapshots().listen((snapshot) {
      final List<AddressModel> addresses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AddressModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();

      addressList.assignAll(addresses);
      isLoading.value = false;
    }, onError: (error) {
      print('배송지 목록 조회 실패: $error');
      isLoading.value = false;
    });
  }

  // 주소 추가
  Future<void> addAddress(AddressModel address) async {
    if (userId == null) return;

    try {
      // 첫 번째 주소를 추가하는 경우 기본 배송지로 설정
      final bool isFirstAddress = addressList.isEmpty;
      final Map<String, dynamic> addressData = address.toJson();

      // ID는 Firebase에서 자동 생성하므로 제외
      addressData.remove('id');

      if (isFirstAddress) {
        addressData['isDefault'] = true;
      }

      // 기본 배송지로 설정하는 경우 기존 기본 배송지 해제
      if (address.isDefault && !isFirstAddress) {
        await _updateDefaultAddressStatus(false);
      }

      // 새 주소 추가
      await _getAddressesRef().add(addressData);
    } catch (e) {
      print('배송지 추가 실패: $e');
    }
  }

  // 주소 수정
  Future<void> updateAddress(AddressModel updatedAddress) async {
    if (userId == null) return;

    try {
      final Map<String, dynamic> addressData = updatedAddress.toJson();
      // ID는 문서 ID로 사용되므로 데이터에서 제외
      addressData.remove('id');

      // 기본 배송지로 변경하는 경우 다른 주소의 기본 배송지 상태 해제
      final bool wasDefault = addressList
          .firstWhere((addr) => addr.id == updatedAddress.id)
          .isDefault;

      if (updatedAddress.isDefault && !wasDefault) {
        await _updateDefaultAddressStatus(false);
      }

      // 기존 기본 배송지의 상태가 해제되는 것 방지
      if (wasDefault && !updatedAddress.isDefault) {
        addressData['isDefault'] = true;
      }

      await _getAddressesRef().doc(updatedAddress.id).update(addressData);
    } catch (e) {
      print('배송지 수정 실패: $e');
    }
  }

  // 주소 삭제
  Future<void> deleteAddress(String id) async {
    if (userId == null) return;

    try {
      // 삭제할 주소가 기본 배송지인지 확인
      final bool isDefault =
          addressList.firstWhere((addr) => addr.id == id).isDefault;

      // 기본 배송지를 삭제하는 경우 다른 주소를 기본 배송지로 설정
      if (isDefault && addressList.length > 1) {
        // 삭제될 주소 외의 첫 번째 주소 ID 찾기
        final String newDefaultId =
            addressList.firstWhere((addr) => addr.id != id).id;

        // 새로운 기본 배송지 설정
        await _getAddressesRef().doc(newDefaultId).update({'isDefault': true});
      }

      // 주소 삭제
      await _getAddressesRef().doc(id).delete();
    } catch (e) {
      print('배송지 삭제 실패: $e');
    }
  }

  // 기본 배송지 설정
  Future<void> setDefaultAddress(String id) async {
    if (userId == null) return;

    try {
      // 모든 주소의 기본 배송지 상태 해제
      await _updateDefaultAddressStatus(false);

      // 선택한 주소를 기본 배송지로 설정
      await _getAddressesRef().doc(id).update({'isDefault': true});
    } catch (e) {
      print('기본 배송지 설정 실패: $e');
    }
  }

  // 모든 기본 배송지 상태 업데이트
  Future<void> _updateDefaultAddressStatus(bool status) async {
    // 기본 배송지인 주소 모두 찾기
    final defaultAddresses =
        addressList.where((addr) => addr.isDefault).toList();

    // 각 주소의 기본 배송지 상태 변경
    final batch = _firestore.batch();
    for (var addr in defaultAddresses) {
      batch.update(_getAddressesRef().doc(addr.id), {'isDefault': status});
    }

    await batch.commit();
  }

  // 기본 배송지 조회
  AddressModel? getDefaultAddress() {
    try {
      return addressList.firstWhere((address) => address.isDefault);
    } catch (e) {
      return addressList.isNotEmpty ? addressList.first : null;
    }
  }
}
