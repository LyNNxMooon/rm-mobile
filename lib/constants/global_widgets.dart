import 'package:flutter/material.dart';

import 'colors.dart';

//Global Text Field
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isEnabled;
  final bool obscureText;
  final IconData? leadingIcon;
  final TextInputType? keyboardType;
  final void Function(String)? function;
  final void Function(String)? submitFunction;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isEnabled = true,
    this.obscureText = false,
    this.leadingIcon,
    this.keyboardType,
    this.function,
    this.focusNode,
    this.submitFunction,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.32)).clamp(1.0, 1.18)
        : 1.0;

    return TextField(
      obscureText: obscureText,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onChanged: function,
      onSubmitted: submitFunction,
      controller: controller,
      keyboardType: keyboardType,
      enabled: isEnabled,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: kGreyColor, fontSize: 14),
        prefixIcon: leadingIcon != null
            ? Icon(
                leadingIcon,
                color: kPrimaryColor,
                size: (20 * uiScale).clamp(20.0, 24.0),
              )
            : null,
        filled: true,
        fillColor: kSecondaryColor,
        contentPadding: EdgeInsets.symmetric(
          vertical: (12 * uiScale).clamp(12.0, 14.5),
          horizontal: (10 * uiScale).clamp(10.0, 12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: kGreyColor, width: 1),
        ),
      ),
    );
  }
}

//Global Loading Bar
class ModernLoadingBar extends StatelessWidget {
  const ModernLoadingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double textScale =
        MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.65)).clamp(1.0, 1.42);
    return ClipRRect(
      borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 14.0)),
      child: LinearProgressIndicator(
        minHeight: (6 * uiScale).clamp(6.0, 10.0),
        backgroundColor: kSecondaryColor,
        color: kGreyColor,
      ),
    );
  }
}
