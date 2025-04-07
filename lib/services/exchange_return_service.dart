import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/order_status_extensions.dart';

enum ExchangeReturnEligibilityStatus {
  eligible,
  ineligible,
}

class ExchangeReturnEligibility {
  final ExchangeReturnEligibilityStatus exchangeStatus;
  final ExchangeReturnEligibilityStatus returnStatus;
  final String? message;

  ExchangeReturnEligibility({
    required this.exchangeStatus,
    required this.returnStatus,
    this.message,
  });

  bool get canExchange =>
      exchangeStatus == ExchangeReturnEligibilityStatus.eligible;
  bool get canReturn =>
      returnStatus == ExchangeReturnEligibilityStatus.eligible;
  bool get isEligible => canExchange || canReturn;
}

class ExchangeReturnService {
  /// Check if order is eligible for exchange and/or return
  ExchangeReturnEligibility checkEligibility(OrderModel order) {
    // Case 1: Orders that are always ineligible for both exchange and return
    if ([
      OrderStatus.cancelled,
      OrderStatus.refunded,
      OrderStatus.returnCompleted,
      OrderStatus.exchangeCompleted,
      OrderStatus.shipping, // Not eligible during shipping
      OrderStatus.exchangeRequested, // Already has an exchange request
      OrderStatus.returnRequested, // Already has a return request
    ].contains(order.status)) {
      return ExchangeReturnEligibility(
        exchangeStatus: ExchangeReturnEligibilityStatus.ineligible,
        returnStatus: ExchangeReturnEligibilityStatus.ineligible,
        message: order.status == OrderStatus.shipping
            ? '배송 중인 상품은 교환/반품이 불가능합니다. 배송 완료 후 이용해주세요.'
            : order.status == OrderStatus.exchangeRequested ||
                    order.status == OrderStatus.returnRequested
                ? '이미 교환/반품 요청이 진행 중입니다.'
                : '취소, 환불, 반품 또는 교환이 완료된 주문은 교환/반품이 불가능합니다.',
      );
    }

    // Case 2: Payment completed (confirmed) - only return is possible, exchange is not
    if (order.status == OrderStatus.confirmed) {
      return ExchangeReturnEligibility(
        exchangeStatus: ExchangeReturnEligibilityStatus.ineligible,
        returnStatus: ExchangeReturnEligibilityStatus.eligible,
        message: '결제 완료 상태에서는 반품만 가능하고 교환은 불가능합니다.',
      );
    }

    // Case 3: Orders that are eligible for both exchange and return
    if ([
      OrderStatus.pending, // Order received
      OrderStatus.delivered, // Delivery completed
    ].contains(order.status)) {
      // For delivered orders, check if within return/exchange period (7 days)
      if (order.status == OrderStatus.delivered &&
          order.deliveryInfo.deliveredAt != null) {
        final deliveredDate = order.deliveryInfo.deliveredAt!;
        final now = DateTime.now();
        final difference = now.difference(deliveredDate).inDays;

        if (difference > 7) {
          return ExchangeReturnEligibility(
            exchangeStatus: ExchangeReturnEligibilityStatus.ineligible,
            returnStatus: ExchangeReturnEligibilityStatus.ineligible,
            message: '배송 완료 후 7일이 지난 상품은 교환/반품이 불가능합니다.',
          );
        }
      }

      return ExchangeReturnEligibility(
        exchangeStatus: ExchangeReturnEligibilityStatus.eligible,
        returnStatus: ExchangeReturnEligibilityStatus.eligible,
        message: null,
      );
    }

    // Case 4: Processing orders - may be eligible depending on business rules
    if (order.status == OrderStatus.processing) {
      return ExchangeReturnEligibility(
        exchangeStatus: ExchangeReturnEligibilityStatus.ineligible,
        returnStatus: ExchangeReturnEligibilityStatus.eligible,
        message: '처리 중인 주문은 반품만 가능합니다.',
      );
    }

    // Default: Not eligible
    return ExchangeReturnEligibility(
      exchangeStatus: ExchangeReturnEligibilityStatus.ineligible,
      returnStatus: ExchangeReturnEligibilityStatus.ineligible,
      message: '현재 주문 상태에서는 교환/반품이 불가능합니다.',
    );
  }

  /// Get eligibility message for UI display
  String getEligibilityMessage(
      ExchangeReturnEligibility eligibility, String selectedType) {
    if (eligibility.message != null) {
      return eligibility.message!;
    }

    bool isExchange = selectedType == 'exchange';
    if (isExchange && !eligibility.canExchange) {
      return '현재 주문 상태에서는 교환이 불가능합니다.';
    }
    if (!isExchange && !eligibility.canReturn) {
      return '현재 주문 상태에서는 반품이 불가능합니다.';
    }

    return '';
  }

  /// Check if the selected type is currently valid
  bool isValidRequestType(
      ExchangeReturnEligibility eligibility, String selectedType) {
    return selectedType == 'exchange'
        ? eligibility.canExchange
        : eligibility.canReturn;
  }

  /// Returns a user-friendly summary of when exchange and return are possible for each order status
  static String getEligibilityRulesSummary() {
    return '''
• 주문접수(pending): 교환/반품 가능
• 결제완료(confirmed): 반품만 가능, 교환 불가능
• 처리중(processing): 반품만 가능, 교환 불가능
• 배송중(shipping): 교환/반품 불가능
• 배송완료(delivered): 교환/반품 가능 (배송 완료 후 7일 이내)
• 주문취소(cancelled): 교환/반품 불가능
• 환불완료(refunded): 교환/반품 불가능
• 반품요청(returnRequested): 교환/반품 불가능
• 교환요청(exchangeRequested): 교환/반품 불가능
• 반품완료(returnCompleted): 교환/반품 불가능
• 교환완료(exchangeCompleted): 교환/반품 불가능
''';
  }
}
