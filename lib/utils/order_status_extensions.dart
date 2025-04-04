import 'package:flutter/material.dart';
import '../models/order_model.dart';

// Add this extension to your project (e.g., in utils/order_status_extensions.dart)
extension OrderStatusExtension on OrderStatus {
  String get text {
    switch (this) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '결제 완료';
      case OrderStatus.processing:
        return '처리 중';
      case OrderStatus.shipping:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
      default:
        return '문앞 전달';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.receipt_outlined;
      case OrderStatus.confirmed:
        return Icons.payment_outlined;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipping:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.refunded:
        return Icons.replay_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipping:
        return Colors.orange;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.pending:
        return Colors.blue.shade400;
      case OrderStatus.confirmed:
        return Colors.green.shade400;
      case OrderStatus.processing:
        return Colors.purple.shade400;
      case OrderStatus.shipping:
        return Colors.orange.shade400;
      case OrderStatus.delivered:
        return Colors.green.shade400;
      case OrderStatus.cancelled:
        return Colors.red.shade400;
      case OrderStatus.refunded:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // 교환/반품 가능 여부 확인
  bool get isEligibleForExchangeReturn {
    // 배송 중이거나 배송 완료된 상품만 교환/반품 가능
    return this == OrderStatus.shipping || this == OrderStatus.delivered;
  }

  // 교환/반품 불가 메시지
  String get ineligibleExchangeReturnMessage {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return '배송 전 상품은 교환/반품이 불가능합니다. 주문 취소를 이용하세요.';
      case OrderStatus.cancelled:
        return '취소된 주문은 교환/반품이 불가능합니다.';
      case OrderStatus.refunded:
        return '환불된 주문은 교환/반품이 불가능합니다.';
      default:
        return '현재 주문 상태에서는 교환/반품이 불가능합니다.';
    }
  }
}

// Add this extension for ExchangeReturnStatus handling
enum ExchangeReturnStatus {
  pending, // 처리 대기
  approved, // 승인됨
  processing, // 처리 중
  shipped, // 교환품 발송 (교환의 경우)
  completed, // 완료됨
  rejected, // 거부됨
  cancelled, // 취소됨
}

extension ExchangeReturnStatusExtension on ExchangeReturnStatus {
  String get text {
    switch (this) {
      case ExchangeReturnStatus.pending:
        return '처리 대기';
      case ExchangeReturnStatus.approved:
        return '승인됨';
      case ExchangeReturnStatus.processing:
        return '처리 중';
      case ExchangeReturnStatus.shipped:
        return '교환품 발송';
      case ExchangeReturnStatus.completed:
        return '완료됨';
      case ExchangeReturnStatus.rejected:
        return '거부됨';
      case ExchangeReturnStatus.cancelled:
        return '취소됨';
    }
  }

  IconData get icon {
    switch (this) {
      case ExchangeReturnStatus.pending:
        return Icons.hourglass_empty;
      case ExchangeReturnStatus.approved:
        return Icons.thumb_up_outlined;
      case ExchangeReturnStatus.processing:
        return Icons.sync;
      case ExchangeReturnStatus.shipped:
        return Icons.local_shipping_outlined;
      case ExchangeReturnStatus.completed:
        return Icons.check_circle_outline;
      case ExchangeReturnStatus.rejected:
        return Icons.thumb_down_outlined;
      case ExchangeReturnStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ExchangeReturnStatus.pending:
        return Colors.orange;
      case ExchangeReturnStatus.approved:
        return Colors.blue;
      case ExchangeReturnStatus.processing:
        return Colors.purple;
      case ExchangeReturnStatus.shipped:
        return Colors.indigo;
      case ExchangeReturnStatus.completed:
        return Colors.green;
      case ExchangeReturnStatus.rejected:
        return Colors.red;
      case ExchangeReturnStatus.cancelled:
        return Colors.grey;
    }
  }

  bool get canCancel {
    // 처리 대기 상태일 때만 취소 가능
    return this == ExchangeReturnStatus.pending;
  }
}
