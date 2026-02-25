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
        hintStyle: TextStyle(color: kGreyColor, fontSize: 14),
        prefixIcon: leadingIcon != null
            ? Icon(leadingIcon, color: kPrimaryColor, size: 20)
            : null,
        filled: true,
        fillColor: kSecondaryColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        minHeight: 6,
        backgroundColor: kSecondaryColor,
        color: kGreyColor,
      ),
    );
  }
}
