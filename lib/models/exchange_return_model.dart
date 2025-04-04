import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../utils/order_status_extensions.dart'; // Import the extensions

enum ExchangeReturnType {
  exchange,
  return_,
}

class ExchangeReturnModel {
  final String id;
  final String orderId;
  final ExchangeReturnType type;
  final ExchangeReturnStatus status;
  final String reason;
  final String? detailedReason;
  final List<CartItemModel> items;
  final DateTime requestDate;
  final DateTime updatedAt;
  final String? statusMessage;
  final Map<String, dynamic>? orderInfo;

  ExchangeReturnModel({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.reason,
    this.detailedReason,
    required this.items,
    required this.requestDate,
    required this.updatedAt,
    this.statusMessage,
    this.orderInfo,
  });

  factory ExchangeReturnModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse the type
    ExchangeReturnType type = data['type'] == 'exchange'
        ? ExchangeReturnType.exchange
        : ExchangeReturnType.return_;

    // Parse the status
    ExchangeReturnStatus status;
    switch (data['status']) {
      case 'pending':
        status = ExchangeReturnStatus.pending;
        break;
      case 'approved':
        status = ExchangeReturnStatus.approved;
        break;
      case 'processing':
        status = ExchangeReturnStatus.processing;
        break;
      case 'shipped':
        status = ExchangeReturnStatus.shipped;
        break;
      case 'completed':
        status = ExchangeReturnStatus.completed;
        break;
      case 'rejected':
        status = ExchangeReturnStatus.rejected;
        break;
      case 'cancelled':
        status = ExchangeReturnStatus.cancelled;
        break;
      default:
        status = ExchangeReturnStatus.pending;
    }

    // Parse items
    List<CartItemModel> items = [];
    for (var item in data['items']) {
      items.add(CartItemModel.fromMap(item));
    }

    return ExchangeReturnModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      type: type,
      status: status,
      reason: data['reason'] ?? '',
      detailedReason: data['detailedReason'],
      items: items,
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      statusMessage: data['statusMessage'],
      orderInfo: data['orderInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'type': type == ExchangeReturnType.exchange ? 'exchange' : 'return',
      'status': status.toString().split('.').last,
      'reason': reason,
      'detailedReason': detailedReason,
      'items': items.map((item) => item.toMap()).toList(),
      'requestDate': Timestamp.fromDate(requestDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusMessage': statusMessage,
      'orderInfo': orderInfo,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'type': type == ExchangeReturnType.exchange ? 'exchange' : 'return',
      'status': status.toString().split('.').last,
      'reason': reason,
      'detailedReason': detailedReason,
      'items': items.map((item) => item.toJson()).toList(),
      'requestDate': requestDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'statusMessage': statusMessage,
      'orderInfo': orderInfo,
    };
  }

  // Helper getter for type text
  String get typeText => type == ExchangeReturnType.exchange ? '교환' : '반품';

  // Helper getter for UI color
  Color get typeColor =>
      type == ExchangeReturnType.exchange ? Colors.blue : Colors.red.shade600;

  // Helper to check if request can be cancelled
  bool get canCancel => status == ExchangeReturnStatus.pending;
}
