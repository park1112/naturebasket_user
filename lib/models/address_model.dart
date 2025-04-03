class AddressModel {
  final String id;
  final String name; // 배송지명 (예: 집, 회사)
  final String recipient; // 수령인
  final String contact; // 연락처 (010-0000-0000 형식)
  final String address; // 기본 주소 (우편번호 포함)
  final String detailAddress; // 상세 주소
  final String? deliveryMessage; // 배송 메시지 (선택사항)
  final bool isDefault; // 기본 배송지 여부

  AddressModel({
    required this.id,
    required this.name,
    required this.recipient,
    required this.contact,
    required this.address,
    required this.detailAddress,
    this.deliveryMessage,
    this.isDefault = false,
  });

  // JSON에서 모델 객체로 변환
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      name: json['name'],
      recipient: json['recipient'],
      contact: json['contact'],
      address: json['address'],
      detailAddress: json['detailAddress'],
      deliveryMessage: json['deliveryMessage'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  // 모델 객체에서 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'recipient': recipient,
      'contact': contact,
      'address': address,
      'detailAddress': detailAddress,
      'deliveryMessage': deliveryMessage,
      'isDefault': isDefault,
    };
  }

  // 복사본 생성 (수정 시 사용)
  AddressModel copyWith({
    String? id,
    String? name,
    String? recipient,
    String? contact,
    String? address,
    String? detailAddress,
    String? deliveryMessage,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      recipient: recipient ?? this.recipient,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      detailAddress: detailAddress ?? this.detailAddress,
      deliveryMessage: deliveryMessage ?? this.deliveryMessage,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
