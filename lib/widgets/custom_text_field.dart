import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final EdgeInsets? contentPadding;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorMaxLines: 2,
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onChanged;

  const PhoneTextField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: '전화번호',
      hint: '01012345678',
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      validator: validator ?? _validatePhoneNumber,
      prefixIcon: const Icon(Icons.phone),
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '전화번호를 입력해주세요.';
    }
    if (value.length < 10) {
      return '유효한 전화번호를 입력해주세요.';
    }
    return null;
  }
}

class VerificationCodeTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;

  const VerificationCodeTextField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: '인증 코드',
      hint: '인증 코드 6자리 입력',
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: _validateVerificationCode,
      prefixIcon: const Icon(Icons.security),
      onChanged: onChanged,
    );
  }

  String? _validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return '인증 코드를 입력해주세요.';
    }
    if (value.length < 6) {
      return '6자리 인증 코드를 입력해주세요.';
    }
    return null;
  }
}

class NameTextField extends StatelessWidget {
  final TextEditingController controller;

  const NameTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: '이름',
      hint: '이름을 입력해주세요',
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이름을 입력해주세요.';
        }
        return null;
      },
      prefixIcon: const Icon(Icons.person),
    );
  }
}
