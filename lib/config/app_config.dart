import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // 앱 기본 설정
  static const String appName = '쇼핑몰 앱';
  static const String appVersion = '1.0.0';
  static const String currencySymbol = '₩';

  // 포트원 설정
  static String get portOneImpKey => dotenv.env['PORTONE_API_KEY'] ?? '';
  static String get portOneApiKey => dotenv.env['PORTONE_REST_API_KEY'] ?? '';
  static String get portOneApiSecret =>
      dotenv.env['PORTONE_REST_API_SECRET'] ?? '';
  static const String portOneDefaultPg = 'html5_inicis'; // 기본 PG사 코드

  // 각 PG사별 상점 아이디 (실제 운영시 추가 필요)
  static const Map<String, String> pgMerchantIds = {
    'html5_inicis': 'INIpayTest', // 이니시스 테스트용 상점 아이디
    'kcp': 'T0000', // KCP 테스트용 상점 아이디
    'nice': 'nictest00m', // 나이스페이 테스트용 상점 아이디
    'kakaopay': 'TC0ONETIME', // 카카오페이 테스트용 상점 아이디
    'tosspay': 'tosspay', // 토스페이 테스트용 상점 아이디
    'naverpay': 'naverpay', // 네이버페이 테스트용 상점 아이디
  };

  // 개발 환경 설정
  static const bool isDevelopment = true; // 개발 환경 여부 (true: 개발, false: 운영)

  // 테스트 모드 설정
  static bool get isTestMode => isDevelopment;

  // 결제 테스트 모드용 카드 정보
  static Map<String, String> get testCardInfo => {
        'cardNumber': '4111-1111-1111-1111',
        'expiry': '12/25',
        'birth': '880101',
        'pwd2digit': '00',
      };

  // 앱스킴
  static const String appScheme = 'fluttershopapp'; // 앱으로 돌아오기 위한 스킴

  // 결제 완료 후 리다이렉트 URL (모바일 웹 결제 시 사용)
  static const String portOneRedirectUrl =
      'https://yourwebsite.com/payments/complete';
}
