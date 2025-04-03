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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        // 카드의 실제 너비 계산
        final cardWidth = width ?? constraints.maxWidth;
        // 이미지 높이를 너비의 1:1 비율로 설정
        final actualImageHeight = imageHeight ?? cardWidth;

        return GestureDetector(
          onTap: () {
            Get.to(() => ProductDetailScreen(productId: product.id));
          },
          child: Container(
            width: cardWidth,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  showBorder ? Border.all(color: Colors.grey.shade200) : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: showBorder
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                AspectRatio(
                  aspectRatio: 1, // 1:1 비율 유지
                  child: product.images.isNotEmpty
                      ? product_widget.ProductImage(
                          imageUrl: product.images[0],
                          isCard: true,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            size: isSmallScreen ? 30 : 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
                // 상품 정보 영역
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 친환경 태그
                        if (product.isEco)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Text(
                              '친환경',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        // 상품명
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 가격 정보
                        if (product.discountPrice != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  product.discountPercentage,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 8 : 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                FormatHelper.formatPrice(product.price),
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500,
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          FormatHelper.formatPrice(product.sellingPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 평점 및 리뷰
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Colors.amber.shade600,
                                size: isSmallScreen ? 12 : 14),
                            const SizedBox(width: 2),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
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
      },
    );
  }
}
