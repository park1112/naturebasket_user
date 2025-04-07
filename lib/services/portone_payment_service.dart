import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

class PortOnePaymentService {
  final Uuid _uuid = Uuid();

  // 결제 수단 정보 (PG사별 지원하는 결제 수단 맵핑)
  final Map<String, List<PaymentMethod>> _pgPaymentMethods = {
    'html5_inicis': [
      PaymentMethod('card', '신용카드'),
      PaymentMethod('trans', '실시간 계좌이체'),
      PaymentMethod('vbank', '가상계좌'),
      PaymentMethod('phone', '휴대폰 소액결제'),
      PaymentMethod('samsung', '삼성페이'),
      PaymentMethod('kakaopay', '카카오페이'),
      PaymentMethod('payco', '페이코'),
      PaymentMethod('naverpay', '네이버페이'),
    ],
    'kcp': [
      PaymentMethod('card', '신용카드'),
      PaymentMethod('trans', '실시간 계좌이체'),
      PaymentMethod('vbank', '가상계좌'),
      PaymentMethod('phone', '휴대폰 소액결제'),
    ],
    'nice': [
      PaymentMethod('card', '신용카드'),
      PaymentMethod('trans', '실시간 계좌이체'),
      PaymentMethod('vbank', '가상계좌'),
      PaymentMethod('phone', '휴대폰 소액결제'),
    ],
    'kakaopay': [
      PaymentMethod('kakaopay', '카카오페이'),
    ],
    'tosspay': [
      PaymentMethod('tosspay', '토스페이'),
    ],
    'naverpay': [
      PaymentMethod('naverpay', '네이버페이'),
    ],
  };

  // 사용 가능한 PG사 목록
  final List<PgProvider> _pgProviders = [
    PgProvider('html5_inicis', '이니시스 웹표준'),
    PgProvider('kcp', 'KCP'),
    PgProvider('nice', '나이스페이'),
    PgProvider('kakaopay', '카카오페이'),
    PgProvider('tosspay', '토스페이'),
    PgProvider('naverpay', '네이버페이'),
  ];

  // 결제 수단 선택 다이얼로그 표시
  Future<Map<String, String>?> showPaymentMethodSelector(
      BuildContext context, double amount) async {
    // 기본 PG 설정
    String selectedPg = 'html5_inicis';
    String selectedMethod = 'card'; // 기본값: 신용카드

    List<PaymentMethod> availableMethods = _pgPaymentMethods[selectedPg] ?? [];

    // 결제 수단 선택 다이얼로그
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('결제 수단 선택'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '결제 금액: ${amount.toStringAsFixed(0)}원',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 20),

                    Text('PG사 선택',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),

                    // PG사 선택 드롭다운
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: SizedBox(),
                        value: selectedPg,
                        items: _pgProviders.map((PgProvider pg) {
                          return DropdownMenuItem<String>(
                            value: pg.code,
                            child: Text(pg.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedPg = newValue;
                              availableMethods =
                                  _pgPaymentMethods[newValue] ?? [];
                              // 해당 PG사의 첫 번째 결제 수단으로 기본값 설정
                              if (availableMethods.isNotEmpty) {
                                selectedMethod = availableMethods[0].code;
                              }
                            });
                          }
                        },
                      ),
                    ),

                    SizedBox(height: 16),
                    Text('결제 수단',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),

                    // 결제 수단 라디오 버튼 그룹
                    Column(
                      children: availableMethods.map((method) {
                        return RadioListTile<String>(
                          title: Text(method.name),
                          value: method.code,
                          groupValue: selectedMethod,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                selectedMethod = value;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 10),

                    // 결제 동의 체크박스
                    CheckboxListTile(
                      title: Text(
                        '결제 진행 및 개인정보 제3자 제공에 동의합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: TextButton(
                        onPressed: () {
                          // 결제 약관 상세 보기
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('결제 약관'),
                              content: SingleChildScrollView(
                                child: Text(
                                  '1. 개인정보 수집 및 이용 동의\n\n'
                                  '- 수집항목: 결제 정보, 휴대폰 번호, 이메일 등 결제 및 결제 취소 시 필요한 정보\n'
                                  '- 수집목적: 결제 서비스 제공, 결제 승인 및 취소, 결제 결과 확인 및 통보\n'
                                  '- 보유기간: 관련 법령에 따른 보존기간\n\n'
                                  '2. 개인정보 제3자 제공 동의\n\n'
                                  '- 제공받는자: 결제 대행사(PG사), 카드사, 은행 등 결제 관련 기관\n'
                                  '- 목적: 결제 처리 및 결제 결과 확인\n'
                                  '- 항목: 결제 정보, 휴대폰 번호, 이메일 등\n'
                                  '- 보유기간: 관련 법령에 따른 보존기간\n\n'
                                  '3. 위 개인정보 수집 및 이용, 제3자 제공 동의는 거부할 수 있으며, 거부 시 결제 서비스 이용이 제한됩니다.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          '약관 보기',
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      value: true,
                      onChanged: (bool? value) {
                        // 동의는 필수이므로 해제 불가능
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null); // 취소
                  },
                  child: Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'pg': selectedPg,
                      'method': selectedMethod,
                    });
                  },
                  child: Text('결제하기'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  // 포트원 결제 처리 메인 메서드
  Future<Map<String, dynamic>?> processPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
    String? customerTel,
  }) async {
    try {
      // 1. 결제 수단 선택 다이얼로그 표시
      final paymentMethodResult =
          await showPaymentMethodSelector(context, amount);

      // 사용자가 취소한 경우
      if (paymentMethodResult == null) {
        return {'success': false, 'message': '결제가 취소되었습니다.'};
      }

      // 2. 결제 정보 준비
      final String merchantUid = 'order_${_uuid.v4()}';

      // 3. 결제 요청 웹뷰 실행
      final paymentResult = await _showPaymentWebView(
        pg: paymentMethodResult['pg'] ?? 'html5_inicis',
        payMethod: paymentMethodResult['method'] ?? 'card',
        merchantUid: merchantUid,
        orderName: orderName,
        amount: amount,
        customerName: customerName ?? '구매자',
        customerEmail: customerEmail,
        customerTel: customerTel ?? '',
        orderId: orderId,
      );

      if (paymentResult == null) {
        return {'success': false, 'message': '결제가 취소되었습니다.'};
      }

      // 4. 결제 성공 여부 확인
      if (paymentResult['success'] == true) {
        // 5. 결제 검증 (금액, 상태 확인)
        final bool verified = await _verifyPayment(
          impUid: paymentResult['imp_uid'],
          merchantUid: paymentResult['merchant_uid'],
          expectedAmount: amount,
        );

        if (verified) {
          // 결제 성공 및 검증 성공
          return {
            'success': true,
            'imp_uid': paymentResult['imp_uid'],
            'merchant_uid': paymentResult['merchant_uid'],
            'amount': paymentResult['paid_amount'] ?? amount,
            'payment_method': paymentResult['payment_method_type'] ??
                paymentMethodResult['method'],
            'pg_provider':
                paymentResult['pg_provider'] ?? paymentMethodResult['pg'],
            'pg_tid': paymentResult['pg_tid'] ?? '',
            'receipt_url': paymentResult['receipt_url'] ?? '',
          };
        } else {
          // 결제는 성공했으나 검증 실패 (금액 불일치 등)
          // 이 경우 자동으로 결제 취소가 이루어진다
          return {
            'success': false,
            'message': '결제 금액 검증에 실패했습니다. 결제가 자동으로 취소됩니다.',
          };
        }
      } else {
        // 결제 실패
        return {
          'success': false,
          'message': paymentResult['error_msg'] ?? '결제 처리 중 오류가 발생했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '결제 처리 중 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  // 포트원 결제 웹뷰 표시
  Future<Map<String, dynamic>?> _showPaymentWebView({
    required String pg,
    required String payMethod,
    required String merchantUid,
    required String orderName,
    required double amount,
    required String customerName,
    String? customerEmail,
    required String customerTel,
    required String orderId,
  }) async {
    final Completer<Map<String, dynamic>?> completer =
        Completer<Map<String, dynamic>?>();

    // 결제창 HTML 생성
    final String paymentHtml = _generatePaymentHtml(
      pg: pg,
      payMethod: payMethod,
      merchantUid: merchantUid,
      orderName: orderName,
      amount: amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerTel: customerTel,
    );

    // WebViewController 초기화
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(paymentHtml)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // 외부 앱 스킴 처리 (앱 결제 등)
            if (_isAppLink(request.url)) {
              debugPrint('외부 앱 호출: ${request.url}');
              // 여기에 외부 앱 실행 로직 추가
              // (실제 앱에서는 url_launcher 패키지 등을 사용하여 처리)
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaymentCallback',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (!completer.isCompleted) {
              completer.complete(data);
            }
            Get.back(); // 웹뷰 닫기
          } catch (e) {
            debugPrint('결제 콜백 처리 오류: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            Get.back(); // 웹뷰 닫기
          }
        },
      );

    // 웹뷰 다이얼로그 표시
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: Get.width,
          height: Get.height,
          color: Colors.white,
          child: Stack(
            children: [
              WebViewWidget(
                controller: webViewController,
              ),
              // 닫기 버튼
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black87, size: 30),
                  onPressed: () {
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                    Get.back(); // 웹뷰 닫기
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  // 외부 앱 링크 판별
  bool _isAppLink(String url) {
    return url.startsWith('intent://') ||
        url.startsWith('market://') ||
        url.startsWith('kakaotalk://') ||
        url.startsWith('ispmobile://') ||
        url.startsWith('tauthlink://') ||
        url.startsWith('https://play.google.com') ||
        url.startsWith('https://itunes.apple.com');
  }

  // 결제창 HTML 생성
  String _generatePaymentHtml({
    required String pg,
    required String payMethod,
    required String merchantUid,
    required String orderName,
    required double amount,
    required String customerName,
    String? customerEmail,
    required String customerTel,
  }) {
    final impKey = AppConfig.portOneImpKey;

    // 안드로이드/iOS 구분 (실제 앱에서는 Platform 클래스를 사용하여 확인)
    final isAndroid = true; // 예시: 기본값 안드로이드

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script type="text/javascript" src="https://cdn.iamport.kr/v1/iamport.js"></script>
      <style>
        body { margin: 0; padding: 0; font-family: 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif; }
        .container { display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; }
        .loading { text-align: center; margin-bottom: 30px; }
        .message { font-size: 16px; color: #333; margin-bottom: 15px; }
        .amount { font-size: 22px; font-weight: bold; color: #2c7be5; margin-bottom: 30px; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 2s linear infinite; margin: 0 auto 20px; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="loading">
          <div class="spinner"></div>
          <p class="message">결제창을 불러오는 중입니다...</p>
          <p class="amount">${amount.toStringAsFixed(0)}원</p>
        </div>
      </div>
      
      <script>
        var IMP = window.IMP;
        IMP.init("$impKey"); // 가맹점 식별코드
        
        // 결제 요청
        function requestPay() {
          // 결제 데이터 구성
          var paymentData = {
            pg: '$pg',
            pay_method: '$payMethod',
            merchant_uid: '$merchantUid',
            name: '$orderName',
            amount: $amount,
            buyer_name: '$customerName',
            buyer_tel: '$customerTel',
            app_scheme: 'fluttershopapp', // 앱 복귀를 위한 커스텀 스킴
          };
          
          // 이메일이 있는 경우만 추가
          ${customerEmail != null ? "paymentData.buyer_email = '$customerEmail';" : ""}
          
          // 앱 환경에 따른 추가 설정
          ${isAndroid ? "paymentData.popup = false;" : ""}
          
          // 결제 창 호출
          IMP.request_pay(paymentData, function(rsp) {
            if (rsp.success) {
              // 결제 성공 시
              window.PaymentCallback.postMessage(JSON.stringify({
                success: true,
                imp_uid: rsp.imp_uid,
                merchant_uid: rsp.merchant_uid,
                paid_amount: rsp.paid_amount,
                status: rsp.status,
                pg_provider: rsp.pg_provider,
                pg_tid: rsp.pg_tid,
                payment_method_type: rsp.payment_method_type,
                receipt_url: rsp.receipt_url,
              }));
            } else {
              // 결제 실패 시
              window.PaymentCallback.postMessage(JSON.stringify({
                success: false,
                error_code: rsp.error_code,
                error_msg: rsp.error_msg
              }));
            }
          });
        }
        
        // 페이지 로드 완료 후 결제창 호출
        window.onload = function() {
          setTimeout(function() {
            requestPay();
          }, 500);
        };
      </script>
    </body>
    </html>
    ''';
  }

  // 결제 검증
  Future<bool> _verifyPayment({
    required String impUid,
    required String merchantUid,
    required double expectedAmount,
  }) async {
    try {
      // 포트원 액세스 토큰 발급
      final tokenResponse = await http.post(
        Uri.parse('https://api.iamport.kr/users/getToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imp_key': AppConfig.portOneApiKey,
          'imp_secret': AppConfig.portOneApiSecret,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('토큰 발급 실패: ${tokenResponse.body}');
        return false;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['response']['access_token'];

      // 결제 정보 조회
      final paymentResponse = await http.get(
        Uri.parse('https://api.iamport.kr/payments/$impUid'),
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );

      if (paymentResponse.statusCode != 200) {
        debugPrint('결제 정보 조회 실패: ${paymentResponse.body}');
        return false;
      }

      final paymentData = jsonDecode(paymentResponse.body);

      if (paymentData['code'] != 0) {
        debugPrint('결제 정보 조회 오류: ${paymentData['message']}');
        return false;
      }

      final responseData = paymentData['response'];

      // 결제 금액 검증
      if (responseData['status'] == 'paid' &&
          responseData['amount'] == expectedAmount &&
          responseData['merchant_uid'] == merchantUid) {
        return true;
      }

      // 금액 불일치 시 결제 취소 진행
      if (responseData['status'] == 'paid' &&
          responseData['amount'] != expectedAmount) {
        debugPrint('결제 금액 불일치. 결제 취소 진행.');
        await _cancelPayment(
          impUid: impUid,
          reason: '결제 금액 불일치',
          accessToken: accessToken,
        );
      }

      return false;
    } catch (e) {
      debugPrint('결제 검증 중 오류: $e');
      return false;
    }
  }

  // 결제 취소
  Future<bool> _cancelPayment({
    required String impUid,
    required String reason,
    required String accessToken,
    double? cancelAmount,
  }) async {
    try {
      // 결제 취소 요청
      final Map<String, dynamic> cancelData = {
        'imp_uid': impUid,
        'reason': reason,
      };

      if (cancelAmount != null) {
        cancelData['amount'] = cancelAmount;
      }

      final cancelResponse = await http.post(
        Uri.parse('https://api.iamport.kr/payments/cancel'),
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cancelData),
      );

      if (cancelResponse.statusCode != 200) {
        debugPrint('결제 취소 실패: ${cancelResponse.body}');
        return false;
      }

      final responseData = jsonDecode(cancelResponse.body);
      return responseData['code'] == 0;
    } catch (e) {
      debugPrint('결제 취소 중 오류: $e');
      return false;
    }
  }

  // 결제 취소 (외부 호출용)
  Future<bool> cancelPayment({
    required String impUid,
    String reason = '사용자 요청',
    double? cancelAmount,
  }) async {
    try {
      // 포트원 액세스 토큰 발급
      final tokenResponse = await http.post(
        Uri.parse('https://api.iamport.kr/users/getToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imp_key': AppConfig.portOneApiKey,
          'imp_secret': AppConfig.portOneApiSecret,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        return false;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['response']['access_token'];

      return await _cancelPayment(
        impUid: impUid,
        reason: reason,
        accessToken: accessToken,
        cancelAmount: cancelAmount,
      );
    } catch (e) {
      debugPrint('결제 취소 중 오류: $e');
      return false;
    }
  }
}

// 결제 수단 클래스
class PaymentMethod {
  final String code;
  final String name;

  PaymentMethod(this.code, this.name);
}

// PG사 정보 클래스
class PgProvider {
  final String code;
  final String name;

  PgProvider(this.code, this.name);
}
