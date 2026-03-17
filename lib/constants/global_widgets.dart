import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'colors.dart';
import 'theme_colors.dart';

//Global Text Field
class CustomTextField extends StatefulWidget {
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
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      _trimText();
    }
  }

  void _trimText() {
    final trimmedValue = widget.controller.text.trim();
    if (widget.controller.text != trimmedValue) {
      widget.controller.value = widget.controller.value.copyWith(
        text: trimmedValue,
        selection: TextSelection.collapsed(offset: trimmedValue.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.32)).clamp(1.0, 1.18)
        : 1.0;

    return TextField(
      obscureText: widget.obscureText,
      textInputAction: widget.textInputAction,
      focusNode: _effectiveFocusNode,
      onChanged: widget.function,
      onSubmitted: (value) {
        _trimText();
        if (widget.submitFunction != null) {
          widget.submitFunction!(value.trim());
        }
      },
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      enabled: widget.isEnabled,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
        prefixIcon: widget.leadingIcon != null
            ? Icon(
                widget.leadingIcon,
                color: kPrimaryColor,
                size: (20 * uiScale).clamp(20.0, 24.0),
              )
            : null,
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          vertical: (12 * uiScale).clamp(12.0, 14.5),
          horizontal: (10 * uiScale).clamp(10.0, 12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: colors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 12.0)),
          borderSide: BorderSide(color: colors.divider, width: 1),
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
    final colors = context.appColors;
    final double textScale =
        MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.65)).clamp(1.0, 1.42);
    return ClipRRect(
      borderRadius: BorderRadius.circular((10 * uiScale).clamp(10.0, 14.0)),
      child: LinearProgressIndicator(
        minHeight: (6 * uiScale).clamp(6.0, 10.0),
        backgroundColor: colors.surfaceAlt,
        color: kPrimaryColor,
      ),
    );
  }
}

class LottieLoadingBar extends StatelessWidget {
  const LottieLoadingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLargeTablet = shortestSide >= 900;

    final lottie = Lottie.asset(
      'assets/animations/Loading bar.json',
      fit: BoxFit.fill,
    );

    if (!isTablet) {
      return lottie;
    }

    final double height = isLargeTablet ? 80 : 70;
    final double width = isLargeTablet ? 700 : 560;

    return SizedBox(
      height: height,
      width: width,
      child: lottie,
    );
  }
}
