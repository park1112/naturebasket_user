import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/order/order_history_screen.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart'; // GoogleFonts 사용
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/review_controller.dart';
import '../../config/theme.dart'; // AppTheme 사용 가정 (없으면 색상 직접 지정)

class WriteReviewScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String? productImage;
  final String orderId;

  const WriteReviewScreen({
    Key? key,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.orderId,
  }) : super(key: key);

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewController _reviewController = Get.find<ReviewController>();
  final AuthController _authController = Get.find<AuthController>();

  bool _isDetailReviewExpanded = false; // 상세 리뷰 섹션 확장 여부

  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _rating = 5.0;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedTags = [];
  bool _serviceLiked = true; // 서비스 평가 기본값 '좋아요'

  bool _isSubmitting = false;

  // 리뷰 태그 옵션 (아이콘 변경 및 일관성)
  final List<Map<String, dynamic>> _reviewTags = [
    {'id': 'taste', 'label': '맛있어요', 'icon': Icons.restaurant_menu_outlined},
    {'id': 'quality', 'label': '품질이 좋아요', 'icon': Icons.thumb_up_alt_outlined},
    {
      'id': 'delivery',
      'label': '배송이 빨라요',
      'icon': Icons.local_shipping_outlined
    },
    {'id': 'price', 'label': '가격이 합리적', 'icon': Icons.sell_outlined},
    {
      'id': 'packaging',
      'label': '포장이 꼼꼼해요',
      'icon': Icons.inventory_2_outlined
    },
    {'id': 'freshness', 'label': '신선해요', 'icon': Icons.eco_outlined},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images =
          await _picker.pickMultiImage(imageQuality: 80); // 이미지 품질 조절
      if (images.isNotEmpty) {
        setState(() {
          if (_selectedImages.length + images.length > 5) {
            _selectedImages = [..._selectedImages, ...images].sublist(0, 5);
            Get.snackbar('알림', '최대 5개의 이미지만 첨부할 수 있습니다.',
                snackPosition: SnackPosition.TOP);
          } else {
            _selectedImages = [..._selectedImages, ...images];
          }
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      Get.snackbar('오류', '이미지를 선택하는 중 오류가 발생했습니다.',
          snackPosition: SnackPosition.TOP);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<bool> _confirmCancel() async {
    final hasContent = _contentController.text.isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _rating != 5.0;
    if (!hasContent) return true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // 모서리 둥글게
        title: const Text('리뷰 작성 취소'),
        content: const Text('작성 중인 내용을 저장하지 않고 나가시겠습니까?'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('계속 작성',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('나가기',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submitReview() async {
    if (_authController.firebaseUser.value == null) {
      Get.snackbar('로그인 필요', '리뷰 작성을 위해 로그인이 필요합니다.',
          snackPosition: SnackPosition.TOP);
      return;
    }

    // 상세 리뷰를 작성하려고 했는지 확인 (섹션이 열려있고, 내용이 있거나, 태그/이미지가 선택된 경우)
    // 또는 최소 글자 수 검증은 여기서 수행
    bool isAttemptingDetailReview =
        _isDetailReviewExpanded && _contentController.text.trim().isNotEmpty;
    bool isContentValid = true;

    if (isAttemptingDetailReview) {
      // 상세 리뷰 작성 시도 시에만 유효성 검사 수행
      if (!_formKey.currentState!.validate()) {
        // validate()는 TextFormField의 validator를 호출함.
        // validator가 null을 반환하면 유효함.
        // 현재 validator는 항상 null을 반환하므로, 실제 내용 검증은 여기서 해야 함.
        if (_contentController.text.trim().length < 10) {
          Get.snackbar('입력 오류', '상세 리뷰 내용은 10자 이상 입력해주세요.',
              snackPosition: SnackPosition.TOP);
          isContentValid = false;
        }
      }
      if (!isContentValid) return; // 유효하지 않으면 중단
    }

    setState(() => _isSubmitting = true);
    try {
      bool success = false;

      if (isAttemptingDetailReview) {
        // 상세 리뷰 제출 로직 호출
        success = await _reviewController.submitDetailReview(
          productId: widget.productId,
          productName: widget.productName,
          productImage: widget.productImage,
          orderId: widget.orderId,
          rating: _rating,
          content: _contentController.text.trim(), // trim() 추가
          tags: _selectedTags,
          images: _selectedImages,
        );
      } else {
        // 별점만 제출 로직 호출
        success = await _reviewController.submitRatingOnly(
          productId: widget.productId,
          productName: widget.productName,
          productImage: widget.productImage,
          orderId: widget.orderId,
          rating: _rating,
        );
      }

      if (success && mounted) {
        // Get.back(); // 성공 시 이전 페이지로
        Get.off(
            () => const OrderHistoryScreen()); // <-- 주문 내역 페이지로 이동 (현재 화면 제거)
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme; // 테마 텍스트 스타일 사용
    final colorScheme = Theme.of(context).colorScheme; // 테마 색상 사용

    return WillPopScope(
      onWillPop: _confirmCancel,
      child: Scaffold(
        backgroundColor: colorScheme.surface, // 배경색 변경
        appBar: AppBar(
          title: Text('리뷰 작성',
              style: GoogleFonts.getFont('Noto Sans KR',
                  fontWeight: FontWeight.w600)), // 폰트 적용
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onSurface,
          elevation: 1, // 약간의 그림자
          centerTitle: false, // 타이틀 왼쪽 정렬
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new), // 아이콘 변경
            onPressed: () async {
              if (await _confirmCancel()) Get.back();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: TextButton.styleFrom(
                  foregroundColor: _isSubmitting
                      ? Colors.grey
                      : colorScheme.onPrimary, // AppTheme.primaryColor
                  textStyle: GoogleFonts.getFont('Noto Sans KR',
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('등록'), // 텍스트 변경
              ),
            ),
          ],
        ),
        body: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0), // 전체 패딩
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 서비스 평가 섹션
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('판매자 서비스 평가',
                                Icons.storefront_outlined, colorScheme.primary),
                            const SizedBox(height: 12),
                            Text('배송, 포장, 응대 등 판매자의 서비스는 어떠셨나요?',
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly, // 간격 균등하게
                              children: [
                                _buildThumbButton(
                                  icon: Icons
                                      .sentiment_satisfied_alt_outlined, // 아이콘 변경
                                  label: '만족해요', // 텍스트 변경
                                  selected: _serviceLiked,
                                  onTap: () =>
                                      setState(() => _serviceLiked = true),
                                  color: colorScheme
                                      .primary, // AppTheme.primaryColor
                                ),
                                const SizedBox(width: 10),
                                _buildThumbButton(
                                  icon: Icons
                                      .sentiment_dissatisfied_outlined, // 아이콘 변경
                                  label: '별로예요',
                                  selected: !_serviceLiked,
                                  onTap: () =>
                                      setState(() => _serviceLiked = false),
                                  color: colorScheme.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20), // 섹션 간 간격

                      // 2. 상품 품질 평가 섹션
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                                '상품은 어떠셨어요?',
                                Icons.inventory_2_outlined,
                                Colors.orange.shade700),
                            const SizedBox(height: 4),
                            Text(widget.productName,
                                style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 20),

                            // 별점
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // 최소 크기 차지
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    onPressed: () =>
                                        setState(() => _rating = index + 1.0),
                                    icon: Icon(
                                      index < _rating
                                          ? Icons.star_rounded
                                          : Icons
                                              .star_outline_rounded, // 둥근 별 아이콘
                                      color: index < _rating
                                          ? Colors.amber.shade600
                                          : Colors.grey.shade400,
                                      size: 44, // 별 크기 조절
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4), // 별 간격 조절
                                    constraints: const BoxConstraints(),
                                    splashRadius: 24, // 클릭 효과 반경
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- 상세 리뷰 작성 토글 버튼 ---
                            Center(
                              // 버튼 중앙 정렬
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isDetailReviewExpanded =
                                        !_isDetailReviewExpanded;
                                  });
                                },
                                icon: Icon(
                                  _isDetailReviewExpanded
                                      ? Icons.keyboard_arrow_up // 위쪽 화살표
                                      : Icons.keyboard_arrow_down, // 아래쪽 화살표
                                  size: 20,
                                ),
                                label: Text(
                                    _isDetailReviewExpanded
                                        ? '상세 리뷰 접기'
                                        : '상세 리뷰 작성하기',
                                    style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w500)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(
                                      color:
                                          colorScheme.primary.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16), // 버튼과 상세내용 사이 간격

                            // --- 상세 리뷰 입력 섹션 ---
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Visibility(
                                visible: _isDetailReviewExpanded,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 16), // 구분선
                                    // 리뷰 태그 (ChoiceChip 사용)
                                    Text('어떤 점이 좋았나요? (선택)',
                                        style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _reviewTags.map((tag) {
                                        // ... 기존 ChoiceChip 코드 ...
                                        final bool isSelected =
                                            _selectedTags.contains(tag['id']);
                                        return ChoiceChip(
                                          label: Text(tag['label']),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          avatar: Icon(tag['icon'],
                                              size: 18,
                                              color: isSelected
                                                  ? colorScheme.onPrimary
                                                  : colorScheme
                                                      .onSurfaceVariant),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedTags.add(tag['id']);
                                              } else {
                                                _selectedTags.remove(tag['id']);
                                              }
                                            });
                                          },
                                          selectedColor: colorScheme.primary,
                                          backgroundColor: colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: BorderSide(
                                                  color: isSelected
                                                      ? colorScheme.primary
                                                      : Colors.grey.shade300)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          showCheckmark: false,
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 24),

                                    // 리뷰 내용 입력
                                    Text('상세한 후기를 알려주세요',
                                        style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      // ... 기존 TextFormField 코드 ...
                                      controller: _contentController,
                                      maxLines: 5,
                                      maxLength: 500,
                                      style: textTheme.bodyMedium,
                                      decoration: InputDecoration(
                                          hintText:
                                              '다른 분들이 참고할 수 있도록 상품에 대한 경험을 공유해주세요. (최소 10자 이상)',
                                          hintStyle: textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey.shade500),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300)),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1.5)),
                                          filled: true,
                                          fillColor: colorScheme.surfaceVariant
                                              .withOpacity(0.2),
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          counterStyle: textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey.shade500)),
                                      validator: (value) {
                                        // 유효성 검사는 _submitReview에서 상세 리뷰 작성 시에만 수행
                                        // if (value == null || value.trim().length < 10) {
                                        //   return '리뷰 내용을 10자 이상 입력해주세요.';
                                        // }
                                        return null; // 여기서는 항상 null 반환
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // 사진 첨부
                                    Text('사진을 첨부해주세요 (선택)',
                                        style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      // ... 기존 사진 첨부 Row 코드 ...
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (_selectedImages.length < 5)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10.0),
                                              child: InkWell(
                                                onTap: _pickImages,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  width: 90,
                                                  height: 90,
                                                  decoration: BoxDecoration(
                                                      color: colorScheme
                                                          .surfaceVariant
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .add_photo_alternate_outlined,
                                                          color: colorScheme
                                                              .primary,
                                                          size: 28),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                          '${_selectedImages.length}/5',
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: colorScheme
                                                                      .onSurfaceVariant)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ...List.generate(
                                              _selectedImages.length, (index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10.0),
                                              child: SizedBox(
                                                width: 90,
                                                height: 90,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.file(
                                                            File(
                                                                _selectedImages[
                                                                        index]
                                                                    .path),
                                                            width: 90,
                                                            height: 90,
                                                            fit: BoxFit.cover)),
                                                    Positioned(
                                                      top: -8,
                                                      right: -8,
                                                      child: InkWell(
                                                        onTap: () =>
                                                            _removeImage(index),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(3),
                                                          decoration: BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.7),
                                                              shape: BoxShape
                                                                  .circle),
                                                          child: const Icon(
                                                              Icons.close,
                                                              size: 16,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '상품과 관련 없거나 부적절한 사진은 삭제될 수 있습니다.',
                                      style: textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32), // 하단 여백
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 섹션 카드를 만드는 위젯
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // 카드 배경색
          borderRadius: BorderRadius.circular(16), // 둥근 모서리 증가
          // boxShadow: [ // 은은한 그림자 효과 (선택 사항)
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.1),
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   )
          // ],
          border: Border.all(color: Colors.grey.shade200, width: 0.8) // 테두리 추가
          ),
      child: child,
    );
  }

  // 섹션 헤더를 만드는 위젯
  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, // 폰트 두께 조정
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  // 좋아요/싫어요 버튼 위젯 (디자인 개선)
  Widget _buildThumbButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      // Row 내에서 공간 차지하도록
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.1)
                : theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? color : Colors.grey.shade500,
                size: 28, // 아이콘 크기 조정
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  // 테마 스타일 사용
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
