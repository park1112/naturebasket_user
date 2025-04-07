import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 시간 비교를 위해 추가

import '../config/theme.dart';
import '../models/product_model.dart';
import '../screens/product/product_detail_screen.dart';
import '../utils/format_helper.dart';
import '../widgets/product_image.dart' as product_widget;

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;
  final bool showBorder;
  final double? imageHeight; // 이 파라미터는 현재 코드에서 직접 사용되지 않음

  const ProductCard({
    Key? key,
    required this.product,
    this.width,
    this.showBorder = true,
    this.imageHeight,
  }) : super(key: key);

  // --- Helper Functions (이전과 동일) ---

  Widget _buildShippingInfo(BuildContext context) {
    final shippingInfo = product.shippingInfo;
    final now = DateTime.now();
    bool canShipToday = false;
    String shippingText = '';
    IconData shippingIcon = Icons.local_shipping_outlined;
    Color shippingColor = Colors.grey.shade600;

    if (shippingInfo.type == ShippingType.sameDay &&
        shippingInfo.sameDaySettings != null &&
        product.stockQuantity > 0) {
      final cutoffTimeString =
          shippingInfo.sameDaySettings!['cutoffTime'] ?? '00:00';
      try {
        final timeParts = cutoffTimeString.split(':');
        if (timeParts.length == 2) {
          final cutoffHour = int.parse(timeParts[0]);
          final cutoffMinute = int.parse(timeParts[1]);
          final cutoffTimeToday =
              DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);

          if (now.isBefore(cutoffTimeToday) &&
              !shippingInfo.holidayDays.contains(now.weekday)) {
            canShipToday = true;
            shippingText = '$cutoffTimeString 전 주문시 오늘 출발';
            shippingIcon = Icons.rocket_launch_outlined;
            shippingColor = AppTheme.primaryColor;
          } else {
            shippingText = '내일 출발 예정';
            shippingIcon = Icons.update;
            shippingColor = Colors.orange.shade700;
          }
        }
      } catch (e) {
        print("Error parsing cutoff time: $e");
        shippingText = '일반 배송';
      }
    } else {
      shippingText = '일반 배송';
    }

    final bool isFreeShipping = shippingInfo.feeType == ShippingFeeType.free;
    List<Widget> shippingWidgets = [];

    if (shippingInfo.type == ShippingType.sameDay &&
        product.stockQuantity > 0) {
      shippingWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(shippingIcon, size: 14, color: shippingColor),
            const SizedBox(width: 3),
            Flexible(
              // 텍스트가 길어질 경우 대비
              child: Text(
                shippingText,
                style: TextStyle(
                  fontSize: 11,
                  color: shippingColor,
                  fontWeight:
                      canShipToday ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis, // 넘칠 경우 ...
              ),
            ),
          ],
        ),
      );
    }

    if (isFreeShipping) {
      if (shippingWidgets.isNotEmpty) {
        shippingWidgets.add(const SizedBox(width: 6));
      }
      shippingWidgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.blue.shade200, width: 0.8),
        ),
        child: Text(
          '무료배송',
          style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500),
        ),
      ));
    }

    if (shippingWidgets.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: shippingWidgets,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildProductTags(double tinyFontSize) {
    List<Widget> tags = [];
    if (product.isEco) {
      tags.add(_buildTagChip('친환경', Colors.green, tinyFontSize));
    }
    if (product.isOrganic) {
      tags.add(_buildTagChip('유기농', Colors.teal, tinyFontSize));
    }
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Wrap(spacing: 4.0, runSpacing: 4.0, children: tags),
    );
  }

  Widget _buildTagChip(String label, Color color, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  // --- Helper Functions End ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isXSmallScreen = screenWidth < 340;
    final isSmallScreen = screenWidth < 600;
    final cardWidth = width ?? (isSmallScreen ? 160.0 : 180.0);
    final cardPadding = isXSmallScreen ? 8.0 : 10.0;
    final itemSpacing = isXSmallScreen ? 4.0 : 6.0;
    final titleFontSize = isXSmallScreen ? 13.0 : 15.0;
    final priceFontSize = isXSmallScreen ? 15.0 : 17.0;
    final smallFontSize = isXSmallScreen ? 11.0 : 13.0;
    final tinyFontSize = isXSmallScreen ? 9.0 : 11.0;
    final imageRatio = 1.0;
    final bool isOutOfStock = product.stockQuantity <= 0;

    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: product.id));
      },
      child: Container(
        width: cardWidth,
        // height: 350, // 필요하다면 고정 높이 지정 또는 GridView/ListView에서 높이 조절
        margin: EdgeInsets.only(right: isXSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: showBorder
              ? Border.all(color: Colors.grey.shade200, width: 0.8)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: showBorder
              ? [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.min, // Column이 최소 크기만 차지하도록 (Expanded와 함께 사용 시 주의)
          children: [
            /// 이미지 영역
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: imageRatio,
                child: Stack(
                  children: [
                    // 이미지
                    product.images.isNotEmpty
                        ? product_widget.ProductImage(
                            imageUrl: product.images.first,
                            isCard: true,
                            fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade100,
                            child: Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    size: 40, color: Colors.grey.shade400))),
                    // 할인 배지
                    if (product.discountPrice != null &&
                        product.discountPrice! < product.price)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1))
                              ]),
                          child: Text(product.discountPercentage,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    // 품절 표시
                    if (isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16))),
                          child: const Center(
                              child: Text('품절',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18))),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            /// 정보 영역 - Expanded 추가하여 남은 공간 채우기
            Expanded(
              // <-- Expanded 추가
              child: Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, cardPadding,
                    cardPadding, cardPadding), // 패딩 조정 (하단 포함)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Expanded 내부 Column 정렬 시작점
                  children: [
                    // --- 상단 그룹 ---
                    _buildProductTags(tinyFontSize),
                    Text(
                      product.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: titleFontSize,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: itemSpacing / 2), // 이름과 Spacer 사이 간격

                    const Spacer(), // <-- Spacer 추가: 아래 요소들을 하단으로 밀어냄

                    // --- 하단 그룹 ---
                    Column(
                      // 가격 영역
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.discountPrice != null &&
                            product.discountPrice! < product.price)
                          Text(
                            FormatHelper.formatPrice(product.price),
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade500,
                                fontSize: smallFontSize),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          FormatHelper.formatPrice(product.sellingPrice),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: priceFontSize,
                              color: isOutOfStock
                                  ? Colors.grey.shade500
                                  : AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    _buildShippingInfo(context), // 배송 정보
                    SizedBox(height: itemSpacing), // 배송 정보와 평점 사이 간격
                    Row(
                      // 평점 + 리뷰수
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber.shade600,
                            size: smallFontSize + 2),
                        const SizedBox(width: 3),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${FormatHelper.formatNumber(product.reviewCount)})', // 리뷰 수 포맷 함수 사용
                          style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
