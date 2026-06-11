import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/theme_colors.dart';
import '../utils/dialog_size_utils.dart';
import '../utils/responsive_utils.dart';

enum DialogActionStyle { primary, danger, outline, dangerOutline, cancelOutline, text }

class DialogActionTheme {
  final AppThemeColors colors;
  final bool isDark;
  final double height;
  final BorderRadius borderRadius;

  const DialogActionTheme({
    required this.colors,
    required this.isDark,
    this.height = 44,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });
}

abstract class DialogActionDecorator {
  Widget build(BuildContext context, DialogActionTheme theme);
}

class DialogTextAction extends DialogActionDecorator {
  final String label;
  final VoidCallback? onPressed;
  final DialogActionStyle style;
  final IconData? icon;

  DialogTextAction({
    required this.label,
    required this.onPressed,
    this.style = DialogActionStyle.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context, DialogActionTheme theme) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final horizontalPadding = textScale > 1.0 ? 24.0 : 20.0;
    
    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
            ],
          );

    switch (style) {
      case DialogActionStyle.primary:
        return SizedBox(
          height: theme.height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
            ),
            child: child,
          ),
        );
      case DialogActionStyle.danger:
        return SizedBox(
          height: theme.height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
            ),
            child: child,
          ),
        );
      case DialogActionStyle.dangerOutline:
        return SizedBox(
          height: theme.height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: kErrorColor,
              side: const BorderSide(color: kErrorColor),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
            ),
            child: child,
          ),
        );
      case DialogActionStyle.cancelOutline:
        final Color neutralColor = theme.isDark
            ? Colors.white70
            : Colors.black87;
        final Color neutralBorder = theme.isDark
            ? Colors.white38
            : Colors.black38;
        return SizedBox(
          height: theme.height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: neutralColor,
              side: BorderSide(color: neutralBorder),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
            ),
            child: child,
          ),
        );
      case DialogActionStyle.outline:
        return SizedBox(
          height: theme.height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              side: const BorderSide(color: kPrimaryColor),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
            ),
            child: child,
          ),
        );
      case DialogActionStyle.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: kErrorColor),
          child: child,
        );
    }
  }
}

class DialogFixedWidthAction extends DialogActionDecorator {
  final DialogActionDecorator action;
  final double width;

  DialogFixedWidthAction({required this.action, required this.width});

  @override
  Widget build(BuildContext context, DialogActionTheme theme) {
    return SizedBox(
      width: width,
      child: action.build(context, theme),
    );
  }
}

class DialogActionsRow extends DialogActionDecorator {
  final List<DialogActionDecorator> actions;
  final double spacing;

  DialogActionsRow({required this.actions, this.spacing = 12});

  @override
  Widget build(BuildContext context, DialogActionTheme theme) {
    final built = actions.map((action) => action.build(context, theme)).toList();
    return Row(
      children: [
        for (int i = 0; i < built.length; i++) ...[
          Expanded(child: built[i]),
          if (i != built.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

class DialogIconAction extends DialogActionDecorator {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  DialogIconAction({required this.icon, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context, DialogActionTheme theme) {
    return SizedBox(
      height: theme.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
        ),
        child: Tooltip(message: tooltip ?? '', child: Icon(icon, size: 20)),
      ),
    );
  }
}

class StandardDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<DialogActionDecorator> actions;
  final AppThemeColors colors;
  final bool isDark;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? insetPadding;
  final EdgeInsetsGeometry? contentPadding;
  final bool showClose;
  final VoidCallback? onClose;
  final bool showHeader;

  const StandardDialog({
    super.key,
    required this.title,
    required this.content,
    required this.colors,
    required this.isDark,
    this.subtitle,
    this.actions = const [],
    this.maxWidth,
    this.maxHeight,
    this.insetPadding,
    this.contentPadding,
    this.showClose = true,
    this.onClose,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final padding = contentPadding ?? EdgeInsets.all(isTablet || useDesktopNav ? 24 : 18);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final buttonHeight = textScale > 1.0 ? 52.0 : 44.0;
    final dialogTheme = DialogActionTheme(colors: colors, isDark: isDark, height: buttonHeight);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding ?? dialogInsetPadding(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? (isTablet || useDesktopNav ? 520 : double.infinity),
          maxHeight: maxHeight ?? double.infinity,
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF212121) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        size: isTablet ? 24 : 22,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Flexible(child: content),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: actions
                      .map((action) => action.build(context, dialogTheme))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
