import 'package:flutter_login_template/models/user_model.dart'
    show AddressModel;

class AddressService {
  Future<List<AddressModel>> getUserAddresses(String userId) async {
    // TODO: 실제 데이터베이스 연동 구현
    return [];
  }

  Future<void> addAddress(String userId, AddressModel address) async {
    // TODO: 실제 데이터베이스 연동 구현
  }
}
