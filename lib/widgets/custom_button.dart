import 'package:flutter/material.dart';
import '../config/theme.dart';

// 소셜 로그인 버튼 종류
enum SocialButtonType {
  naver,
  facebook,
  phone,
  google,
}

// 일반 커스텀 버튼
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppTheme.primaryColor,
    this.textColor = Colors.white,
    this.height = 50.0,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: backgroundColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildButtonContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildButtonContent(),
            ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? backgroundColor : textColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOutlined ? backgroundColor : textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isOutlined ? backgroundColor : textColor,
      ),
    );
  }
}

// 소셜 로그인 버튼
// lib/widgets/custom_button.dart
class SocialLoginButton extends StatelessWidget {
  final SocialButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
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
        return Colors.white; // 구글 버튼은 흰색 배경
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
        // G 아이콘 (실제로는 이미지 에셋을 사용하는 것이 좋음)
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
