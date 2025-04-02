import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 반응형 크기 조정을 위해 (선택 사항)

class AppConstants {
  // SharedPreferences 키
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyUserData = 'user_data';
  static const String keyCartItems = 'cart_items';
  static const String keyFavoriteItems = 'favorite_items';

  // Firestore 컬렉션
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'carts';

  // 오류 메시지
  static const String errorNetworkConnection = '네트워크 연결을 확인해주세요.';
  static const String errorLoginFailed = '로그인에 실패했습니다. 다시 시도해주세요.';
  static const String errorInvalidPhoneNumber = '유효하지 않은 전화번호입니다.';
  static const String errorInvalidVerificationCode = '유효하지 않은 인증 코드입니다.';
  static const String errorProductNotFound = '상품 정보를 찾을 수 없습니다.';
  static const String errorCartUpdate = '장바구니 업데이트에 실패했습니다.';
  static const String errorOrderFailed = '주문 처리 중 오류가 발생했습니다.';

  // 성공 메시지
  static const String successLogin = '로그인에 성공했습니다.';
  static const String successAddToCart = '상품이 장바구니에 추가되었습니다.';
  static const String successOrder = '주문이 완료되었습니다.';
  static const String successProfileUpdate = '프로필이 업데이트되었습니다.';

// --- 색상 (앱의 브랜드 색상으로 정의) ---
  static const kPrimaryColor = Color(0xFF6B8E23); // 예시: 올리브 그린
  static const kSecondaryColor = Color(0xFFF5F5DC); // 예시: 베이지
  static const kAccentColor = Color(0xFF8FBC8F); // 예시: 다크 씨 그린
  static const kTextColor = Color(0xFF2F4F4F); // 예시: 다크 슬레이트 그레이
  static const kLightTextColor = Color(0xFF778899); // 예시: 라이트 슬레이트 그레이
  static const kBackgroundColor = Colors.white;
  static const kSurfaceColor = Color(0xFFF8F8F8); // 카드 등의 배경색
  static const kErrorColor = Color(0xFFB00020);
  static const kSuccessColor = Color(0xFF4CAF50);
  static const kWarningColor = Color(0xFFFFC107);

// --- 반응형 패딩/마진 (flutter_screenutil 사용 예시) ---
// ScreenUtilInit을 MaterialApp 위에서 초기화해야 함
  final double kDefaultPadding = 16.w; // 너비 기준 반응형 패딩
  final double kSmallPadding = 8.w;
  final double kLargePadding = 24.w;
  final double kVerticalPadding = 12.h; // 높이 기준 반응형 패딩

// --- 반응형 폰트 크기 (flutter_screenutil 사용 예시) ---
  final double kFontSizeSmall = 12.sp;
  final double kFontSizeMedium = 14.sp;
  final double kFontSizeLarge = 16.sp;
  final double kFontSizeTitle = 18.sp;

// --- Border Radius ---
  final double kDefaultBorderRadius = 12.r; // 반응형 Radius
  final double kSmallBorderRadius = 8.r;

// --- 아이콘 크기 ---
  final double kIconSizeSmall = 18.w;
  final double kIconSizeMedium = 24.w;
  final double kIconSizeLarge = 32.w;

// --- 문자열 상수 (다국어 지원 시에는 별도 관리 필요 - GetX Localization 등) ---
  static const String kAppName = "네이처바스켓";
  static const String kApiBaseUrl = "YOUR_API_ENDPOINT"; // 실제 엔드포인트로 교체
  static const String kMsgLoading = "로딩 중...";
  static const String kMsgErrorNetwork = "네트워크 연결을 확인해주세요.";
  static const String kMsgErrorUnknown = "알 수 없는 오류가 발생했습니다.";

// --- Firestore 컬렉션 이름 ---
  static const String kUsersCollection = 'users';
  static const String kProductsCollection = 'products';
  static const String kOrdersCollection = 'orders';
  static const String kCategoriesCollection = 'categories';
  static const String kReviewsSubcollection = 'reviews'; // 상품의 하위 컬렉션
  static const String kWishlistSubcollection = 'wishlist'; // 유저의 하위 컬렉션
  static const String kCartSubcollection = 'cart'; // 유저의 하위 컬렉션
  static const String kDeliveryInfoSubcollection =
      'delivery_info'; // 유저의 하위 컬렉션

  // 인트로 슬라이더 텍스트
  static const List<Map<String, String>> introSlides = [
    {
      'title': '다양한 로그인 방식',
      'description': '네이버, 페이스북, 전화번호를 통해 간편하게 로그인하세요.',
    },
    {
      'title': '개인 프로필 관리',
      'description': '프로필 정보를 쉽게 조회하고 수정할 수 있습니다.',
    },
    {
      'title': '간편한 인증',
      'description': '한 번 로그인하면 자동으로 로그인 상태가 유지됩니다.',
    },
    {
      'title': '자연 친화적 제품',
      'description': '건강하고 친환경적인 제품을 만나보세요.',
    },
    {
      'title': '편리한 쇼핑',
      'description': '원하는 제품을 쉽고 빠르게 검색하고 구매하세요.',
    },
    {
      'title': '안전한 배송',
      'description': '신선한 상품을 안전하게 배송해 드립니다.',
    },
  ];
  // 카테고리 목록
  static const List<Map<String, dynamic>> categories = [
    {'id': 'food', 'name': '식품', 'icon': 'assets/icons/food.png'},
    {'id': 'living', 'name': '생활용품', 'icon': 'assets/icons/living.png'},
    {'id': 'beauty', 'name': '뷰티', 'icon': 'assets/icons/beauty.png'},
    {'id': 'fashion', 'name': '패션', 'icon': 'assets/icons/fashion.png'},
    {'id': 'home', 'name': '가정용품', 'icon': 'assets/icons/home.png'},
  ];

  // 배송 옵션
  static const List<Map<String, dynamic>> deliveryOptions = [
    {'id': 'standard', 'name': '일반 배송', 'price': 3000, 'days': '2-3일'},
    {'id': 'express', 'name': '빠른 배송', 'price': 5000, 'days': '1-2일'},
    {'id': 'morning', 'name': '새벽 배송', 'price': 7000, 'days': '다음날 아침'},
  ];
}
