import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginType { naver, facebook, phone, google, email, unknown }

class AddressModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String? addressDetail;
  final String zipCode;
  final bool isDefault;
  final String? notes;

  AddressModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.addressDetail,
    required this.zipCode,
    this.isDefault = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'addressDetail': addressDetail,
      'zipCode': zipCode,
      'isDefault': isDefault,
      'notes': notes,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      addressDetail: map['addressDetail'],
      zipCode: map['zipCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel.fromMap(json);
  }

  AddressModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? addressDetail,
    String? zipCode,
    bool? isDefault,
    String? notes,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
      notes: notes ?? this.notes,
    );
  }
}

class UserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final LoginType loginType;
  final DateTime lastLogin;
  final List<Map<String, dynamic>> loginHistory;
  final List<Map<String, dynamic>> signInHistory;
  final List<AddressModel> addresses;
  final int point;
  final String? grade;
  final List<String>? favoriteProducts;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoURL,
    required this.loginType,
    required this.lastLogin,
    this.loginHistory = const [],
    this.signInHistory = const [],
    this.addresses = const [],
    this.point = 0,
    this.grade,
    this.favoriteProducts,
    this.preferences,
  });

  // 기본 배송지 조회 (addresses 중 isDefault가 true인 항목, 없으면 첫번째 항목)
  AddressModel? get defaultAddress {
    return addresses.isEmpty
        ? null
        : addresses.firstWhere((addr) => addr.isDefault,
            orElse: () => addresses.first);
  }

  // 로그인 타입에 따른 표시 텍스트
  String get loginTypeText {
    switch (loginType) {
      case LoginType.naver:
        return '네이버';
      case LoginType.facebook:
        return '페이스북';
      case LoginType.phone:
        return '전화번호';
      case LoginType.google:
        return '구글';
      case LoginType.email:
        return '이메일';
      default:
        return '일반';
    }
  }

  // Firestore 데이터 디버그 출력 (loginHistory의 상세 항목도 함께 출력)
  static void debugPrintFirestoreData(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print('===== Firestore User Data =====');
    print('ID: ${doc.id}');
    data.forEach((key, value) {
      print('$key: $value (${value.runtimeType})');
      if (key == 'loginHistory' && value is List) {
        print('--- Login History Details ---');
        int index = 0;
        for (var item in value) {
          print('Item $index:');
          if (item is Map) {
            item.forEach((k, v) {
              print('  $k: $v (${v.runtimeType})');
            });
          } else {
            print('  Item format: ${item.runtimeType}');
          }
          index++;
        }
      }
    });
    print('===============================');
  }

  // Firestore에서 데이터 로드
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    debugPrintFirestoreData(doc);
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // lastLogin 필드 처리
    DateTime lastLogin;
    if (data['lastLogin'] == null) {
      lastLogin = DateTime.now();
    } else if (data['lastLogin'] is Timestamp) {
      lastLogin = (data['lastLogin'] as Timestamp).toDate();
    } else if (data['lastLogin'] is String) {
      try {
        lastLogin = DateTime.parse(data['lastLogin'] as String);
      } catch (e) {
        lastLogin = DateTime.now();
      }
    } else {
      lastLogin = DateTime.now();
    }

    // loginHistory 필드 처리
    List<Map<String, dynamic>> loginHistory = [];
    if (data['loginHistory'] != null && data['loginHistory'] is List) {
      try {
        List<dynamic> rawHistory = data['loginHistory'] as List;
        for (var item in rawHistory) {
          if (item is Map) {
            dynamic rawTimestamp = item['timestamp'];
            DateTime timestamp;
            if (rawTimestamp is Timestamp) {
              timestamp = rawTimestamp.toDate();
            } else if (rawTimestamp is String) {
              try {
                timestamp = DateTime.parse(rawTimestamp);
              } catch (e) {
                timestamp = DateTime.now();
              }
            } else {
              timestamp = DateTime.now();
            }
            String loginTypeStr = 'unknown';
            if (item['loginType'] is String) {
              loginTypeStr = item['loginType'];
            }
            loginHistory.add({
              'timestamp': timestamp,
              'loginType': loginTypeStr,
            });
          }
        }
      } catch (e) {
        print('Error parsing loginHistory: $e');
        loginHistory = [];
      }
    }

    // signInHistory 필드 처리 (존재할 경우)
    List<Map<String, dynamic>> signInHistory = [];
    if (data['signInHistory'] != null && data['signInHistory'] is List) {
      try {
        List<dynamic> rawHistory = data['signInHistory'] as List;
        for (var item in rawHistory) {
          if (item is Map) {
            dynamic rawTimestamp = item['timestamp'];
            DateTime timestamp;
            if (rawTimestamp is Timestamp) {
              timestamp = rawTimestamp.toDate();
            } else if (rawTimestamp is String) {
              try {
                timestamp = DateTime.parse(rawTimestamp);
              } catch (e) {
                timestamp = DateTime.now();
              }
            } else {
              timestamp = DateTime.now();
            }
            String loginTypeStr = 'unknown';
            if (item['loginType'] is String) {
              loginTypeStr = item['loginType'];
            }
            signInHistory.add({
              'timestamp': timestamp,
              'loginType': loginTypeStr,
            });
          }
        }
      } catch (e) {
        print('Error parsing signInHistory: $e');
        signInHistory = [];
      }
    }

    // 주소 목록 처리
    List<AddressModel> addresses = [];
    if (data['addresses'] != null && data['addresses'] is List) {
      try {
        addresses = (data['addresses'] as List)
            .map((addr) => AddressModel.fromMap(addr))
            .toList();
      } catch (e) {
        print('Error parsing addresses: $e');
        addresses = [];
      }
    }

    // 즐겨찾기 상품 목록 처리
    List<String>? favoriteProducts;
    if (data['favoriteProducts'] != null && data['favoriteProducts'] is List) {
      favoriteProducts = List<String>.from(data['favoriteProducts']);
    }

    return UserModel(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      loginType: LoginType.values.firstWhere(
        (type) => type.toString().split('.').last == data['loginType'],
        orElse: () => LoginType.unknown,
      ),
      lastLogin: lastLogin,
      loginHistory: loginHistory,
      signInHistory: signInHistory,
      addresses: addresses,
      point: data['point'] ?? 0,
      grade: data['grade'],
      favoriteProducts: favoriteProducts,
      preferences: data['preferences'],
    );
  }

  // Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': FieldValue.serverTimestamp(),
      'loginHistory': loginHistory
          .map((log) => {
                'timestamp': log['timestamp'],
                'loginType': log['loginType'],
              })
          .toList(),
      'signInHistory': signInHistory
          .map((log) => {
                'timestamp': log['timestamp'],
                'loginType': log['loginType'],
              })
          .toList(),
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'point': point,
      'grade': grade,
      'favoriteProducts': favoriteProducts,
      'preferences': preferences,
    };
  }

  // JSON으로 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': lastLogin.toIso8601String(),
      'loginHistory': loginHistory
          .map((log) => {
                'timestamp': log['timestamp'].toIso8601String(),
                'loginType': log['loginType'],
              })
          .toList(),
      'signInHistory': signInHistory
          .map((log) => {
                'timestamp': log['timestamp'].toIso8601String(),
                'loginType': log['loginType'],
              })
          .toList(),
      'addresses': addresses.map((addr) => addr.toJson()).toList(),
      'point': point,
      'grade': grade,
      'favoriteProducts': favoriteProducts,
      'preferences': preferences,
    };
  }

  // JSON에서 객체 생성 (SharedPreferences 로드용)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> loginHistory = [];
    if (json['loginHistory'] != null) {
      loginHistory = List<Map<String, dynamic>>.from(
          (json['loginHistory'] as List).map((item) => {
                'timestamp': DateTime.parse(item['timestamp']),
                'loginType': item['loginType'],
              }));
    }

    List<Map<String, dynamic>> signInHistory = [];
    if (json['signInHistory'] != null) {
      signInHistory = List<Map<String, dynamic>>.from(
          (json['signInHistory'] as List).map((item) => {
                'timestamp': DateTime.parse(item['timestamp']),
                'loginType': item['loginType'],
              }));
    }

    List<AddressModel> addresses = [];
    if (json['addresses'] != null) {
      addresses = (json['addresses'] as List)
          .map((addr) => AddressModel.fromJson(addr))
          .toList();
    }

    List<String>? favoriteProducts;
    if (json['favoriteProducts'] != null) {
      favoriteProducts = List<String>.from(json['favoriteProducts']);
    }

    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      loginType: LoginType.values.firstWhere(
        (type) => type.toString().split('.').last == json['loginType'],
        orElse: () => LoginType.unknown,
      ),
      lastLogin: DateTime.parse(json['lastLogin']),
      loginHistory: loginHistory,
      signInHistory: signInHistory,
      addresses: addresses,
      point: json['point'] ?? 0,
      grade: json['grade'],
      favoriteProducts: favoriteProducts,
      preferences: json['preferences'],
    );
  }

  // 객체 복사 및 업데이트
  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? photoURL,
    LoginType? loginType,
    DateTime? lastLogin,
    List<Map<String, dynamic>>? loginHistory,
    List<Map<String, dynamic>>? signInHistory,
    List<AddressModel>? addresses,
    int? point,
    String? grade,
    List<String>? favoriteProducts,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      loginType: loginType ?? this.loginType,
      lastLogin: lastLogin ?? this.lastLogin,
      loginHistory: loginHistory ?? this.loginHistory,
      signInHistory: signInHistory ?? this.signInHistory,
      addresses: addresses ?? this.addresses,
      point: point ?? this.point,
      grade: grade ?? this.grade,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      preferences: preferences ?? this.preferences,
    );
  }
}
