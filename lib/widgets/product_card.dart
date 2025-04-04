import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';
import '../models/product_model.dart';
import '../screens/product/product_detail_screen.dart';
import '../utils/format_helper.dart';
import '../widgets/product_image.dart' as product_widget;

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;
  final bool showBorder;
  final double? imageHeight;

  const ProductCard({
    Key? key,
    required this.product,
    this.width,
    this.showBorder = true,
    this.imageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 스크린 분기
    final isXSmallScreen = screenWidth < 340;
    final isSmallScreen = screenWidth < 600;

    // 카드 폭
    final cardWidth = width ?? (isSmallScreen ? 160.0 : 180.0);

    // 패딩 및 간격
    final cardPadding = isXSmallScreen ? 6.0 : 8.0;
    final itemSpacing = isXSmallScreen ? 3.0 : 5.0;

    // 폰트 크기
    final titleFontSize = isXSmallScreen ? 12.0 : 14.0;
    final priceFontSize = isXSmallScreen ? 14.0 : 16.0;
    final smallFontSize = isXSmallScreen ? 10.0 : 12.0;
    final tinyFontSize = isXSmallScreen ? 8.0 : 10.0;

    // 이미지 비율 (가로 : 세로) - 비율 개선
    // 세로가 더 길게 설정 (1:1) -> (1:0.95) 비율로 변경
    final imageRatio = 1.0;

    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailScreen(productId: product.id));
      },
      child: Container(
        width: cardWidth - 10,
        // 최소 높이 지정 (오버플로우 방지)
        // constraints: const BoxConstraints(minHeight: 310),
        margin: EdgeInsets.only(right: isXSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: showBorder ? Border.all(color: Colors.grey.shade200) : null,
          borderRadius: BorderRadius.circular(12), // 더 둥글게 수정
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 이미지 영역
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: imageRatio,
                child: Stack(
                  children: [
                    // 이미지
                    product.images.isNotEmpty
                        ? product_widget.ProductImage(
                            imageUrl: product.images.first,
                            isCard: true,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey.shade400,
                            ),
                          ),

                    // 할인 배지 (오른쪽 상단)
                    if (product.discountPrice != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.discountPercentage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            /// 정보 영역 - Expanded로 감싸서 남은 공간 활용
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 친환경 태그
                    if (product.isEco)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        margin: EdgeInsets.only(bottom: itemSpacing),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          '친환경',
                          style: TextStyle(
                            fontSize: tinyFontSize,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // 상품명 (최대 2줄 표시)
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: titleFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: itemSpacing),

                    // 빈 공간을 Spacer로 채우기
                    const Spacer(),

                    // 할인 전 가격 / 할인율
                    if (product.discountPrice != null) ...[
                      Text(
                        FormatHelper.formatPrice(product.price),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                          fontSize: smallFontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: itemSpacing),
                    ],

                    // 실제 판매 가격
                    Text(
                      FormatHelper.formatPrice(product.sellingPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: priceFontSize,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: itemSpacing + 2),

                    // 평점 + 리뷰수
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade600,
                          size: smallFontSize,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: smallFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey.shade600,
                          ),
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
