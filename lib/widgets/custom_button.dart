import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config/theme.dart';
import '../config/constants.dart';

/// 소셜 로그인 버튼 종류
enum SocialButtonType {
  naver,
  facebook,
  phone,
  google,
}

/// 일반 커스텀 버튼
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // 비활성화 지원을 위해 nullable
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height; // 기본 높이
  final double fontSize; // 기본 폰트 크기
  final bool isLoading; // 로딩 상태
  final Widget? leadingIcon; // 아이콘 (선택 사항)
  final EdgeInsetsGeometry padding; // 패딩
  final double borderRadius; // 테두리 반경
  final bool isOutlined; // 아웃라인 버튼 여부

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50.0,
    this.fontSize = 16.0,
    this.isLoading = false,
    this.leadingIcon,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    this.borderRadius = 8.0,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 반응형 크기 적용 (ScreenUtil 사용 시)
    final double btnHeight = height; // height.h 사용 가능
    final double btnWidth = width ?? double.infinity;
    final Color effectiveBgColor = backgroundColor ?? AppTheme.primaryColor;
    final Color effectiveTextColor = textColor ?? Colors.white;

    final ButtonStyle style = isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(color: effectiveBgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.r),
            ),
            padding: padding,
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            disabledBackgroundColor: effectiveBgColor.withOpacity(0.5),
            disabledForegroundColor: effectiveTextColor.withOpacity(0.7),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveBgColor,
            foregroundColor: effectiveTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.r),
            ),
            padding: padding,
            elevation: 2,
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          );

    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: _buildButtonContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: _buildButtonContent(),
            ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined
                ? (backgroundColor ?? AppTheme.primaryColor)
                : (textColor ?? Colors.white),
          ),
        ),
      );
    }
    if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leadingIcon!,
          const SizedBox(width: 8.0),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isOutlined
                  ? (backgroundColor ?? AppTheme.primaryColor)
                  : (textColor ?? Colors.white),
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: isOutlined
            ? (backgroundColor ?? AppTheme.primaryColor)
            : (textColor ?? Colors.white),
      ),
    );
  }
}

/// 소셜 로그인 버튼
class SocialLoginButton extends StatelessWidget {
  final SocialButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    Key? key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isSmallScreen = constraints.maxWidth < 600;
      return Container(
        height: isSmallScreen ? 50 : 56,
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getButtonIcon(),
                      const SizedBox(width: 10),
                      Text(
                        _getButtonText(),
                        style: TextStyle(
                          color: type == SocialButtonType.google
                              ? Colors.black
                              : Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Color _getButtonColor() {
    switch (type) {
      case SocialButtonType.naver:
        return AppTheme.naverColor;
      case SocialButtonType.facebook:
        return AppTheme.facebookColor;
      case SocialButtonType.phone:
        return Colors.grey.shade800;
      case SocialButtonType.google:
        return Colors.white;
    }
  }

  String _getButtonText() {
    switch (type) {
      case SocialButtonType.naver:
        return '네이버로 로그인';
      case SocialButtonType.facebook:
        return '페이스북으로 로그인';
      case SocialButtonType.phone:
        return '전화번호로 로그인';
      case SocialButtonType.google:
        return '구글로 로그인';
    }
  }

  Widget _getButtonIcon() {
    switch (type) {
      case SocialButtonType.naver:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: AppTheme.naverColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case SocialButtonType.facebook:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.facebook,
            color: AppTheme.facebookColor,
            size: 16,
          ),
        );
      case SocialButtonType.phone:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.phone,
            color: Colors.black,
            size: 16,
          ),
        );
      case SocialButtonType.google:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.googleColor,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }
}
