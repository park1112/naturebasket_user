import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../utils/format_helper.dart';
import '../../controllers/cart_controller.dart';
import '../product/product_detail_screen.dart';

/// 개별 장바구니 아이템 위젯 - 각 아이템이 독립적으로 리렌더링
class CartItemWidget extends StatefulWidget {
  final String itemId;
  final CartController cartController;

  const CartItemWidget({
    Key? key,
    required this.itemId,
    required this.cartController,
  }) : super(key: key);

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool _isUpdating = false;

  // 포맷팅: 옵션 텍스트
  String _formatSelectedOptions(Map<String, dynamic>? options) {
    if (options == null || options.isEmpty) return '';

    List<String> parts = [];
    options.forEach((key, value) {
      parts.add('$key: $value');
    });
    return parts.join(', ');
  }

  // 수량 변경 시 로컬에서만 로딩 상태 관리
  Future<void> _updateQuantity(int newQuantity) async {
    if (_isUpdating) return; // 이미 업데이트 중이면 중복 요청 방지

    // 로컬 로딩 상태 시작
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.cartController
          .updateItemQuantityById(widget.itemId, newQuantity);
    } finally {
      // 무조건 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 아이템 상태 가져오기 (존재하지 않으면 빈 위젯 반환)
    final itemState = widget.cartController.itemStates[widget.itemId];
    if (itemState == null) return const SizedBox.shrink();

    final item = itemState.item;

    // Obx로 감싸서 이 위젯만 리렌더링되도록 함
    return Obx(() {
      final quantity = itemState.quantity.value;
      final isSelected = itemState.isSelected.value;
      final isUpdating = itemState.isUpdating.value;

      return SizedBox(
        height: 145, // 고정 높이로 레이아웃 안정화
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () =>
                Get.to(() => ProductDetailScreen(productId: item.productId)),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 체크박스
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        if (value != null) {
                          widget.cartController
                              .toggleItemSelection(widget.itemId);
                        }
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),

                  // 이미지
                  _buildProductImage(item.productImage),

                  const SizedBox(width: 12),

                  // 상품 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 상품명
                        Text(
                          item.productName,
                          style: GoogleFonts.notoSans(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // 옵션 정보
                        if (item.selectedOptions != null &&
                            item.selectedOptions!.isNotEmpty)
                          Text(
                            _formatSelectedOptions(item.selectedOptions),
                            style: GoogleFonts.notoSans(
                                fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),

                        // 가격
                        Text(
                          FormatHelper.formatPrice(item.price),
                          style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),

                        // 수량 컨트롤 및 배송 정보
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 배송 정보
                            Text(
                              "무료배송",
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            // 수량 컨트롤
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // 수량 컨트롤 UI
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      // 감소 버튼
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: _isUpdating
                                            ? null
                                            : () =>
                                                _updateQuantity(quantity - 1),
                                      ),
                                      // 수량 표시
                                      Text('${quantity}'),
                                      // 증가 버튼
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: _isUpdating
                                            ? null
                                            : () =>
                                                _updateQuantity(quantity + 1),
                                      ),
                                    ],
                                  ),
                                ),

                                // 로딩 인디케이터 (업데이트 중일 때만 표시)
                                if (_isUpdating)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 삭제 버튼
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        widget.cartController.removeItem(widget.itemId),
                    color: Colors.grey.shade600,
                    constraints: const BoxConstraints(), // 여백 최소화
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // 이미지 위젯
  Widget _buildProductImage(String? imageUrl) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade100,
          ),
          child: (imageUrl == null || imageUrl.isEmpty)
              ? Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // 수량 조절 버튼
  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: 14,
            color: onPressed == null
                ? Colors.grey.shade400 // 비활성화 색상
                : Colors.grey.shade700 // 활성화 색상
            ),
      ),
    );
  }
}
