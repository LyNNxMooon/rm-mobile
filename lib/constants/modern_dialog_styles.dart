import 'package:flutter/material.dart';
import 'colors.dart';
import 'theme_colors.dart';

/// Modern dialog styling constants and components for consistent UI/UX
class ModernDialogStyles {
  ModernDialogStyles._();

  // Border radius values - more rounded for modern look
  static const double dialogRadius = 25.0;
  static const double headerRadius = 25.0;
  static const double buttonRadius = 14.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 14.0;

  // Spacing values
  static const double headerPaddingV = 24.0;
  static const double headerPaddingH = 24.0;
  static const double contentPadding = 24.0;
  static const double itemSpacing = 16.0;
  static const double sectionSpacing = 24.0;

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 250);

  /// Modern dialog shape
  static ShapeBorder get dialogShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogRadius),
      );

  /// Accent gradient for primary elements
  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
      );

  /// Header gradient for primary buttons and headers
  static LinearGradient get headerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
      );

  /// Dialog decoration for dark/light mode with glassmorphism
  static BoxDecoration dialogDecoration(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return BoxDecoration(
      color: isDark 
          ? const Color(0xFF1A1F2E).withOpacity(0.95) 
          : Colors.white.withOpacity(0.98),
      borderRadius: BorderRadius.circular(dialogRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.08),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
          blurRadius: 60,
          spreadRadius: -10,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  /// Modern header decoration with vibrant gradient
  static BoxDecoration headerDecoration(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return BoxDecoration(
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D3A4F),
                Color(0xFF1A2332),
              ],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0891B2),
                Color(0xFF0E7490),
              ],
            ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(headerRadius),
        topRight: Radius.circular(headerRadius),
      ),
    );
  }

  /// Modern primary button style with gradient
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: kPrimaryColor.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withOpacity(0.15);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withOpacity(0.1);
        }
        return null;
      }),
    );
  }

  /// Modern secondary/outlined button style
  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      side: BorderSide(
        color: kPrimaryColor.withOpacity(isDark ? 0.5 : 0.35),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    );
  }

  /// Modern text button style
  static ButtonStyle textButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: kPrimaryColor,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    );
  }

  /// Modern input decoration with pill-like appearance
  static InputDecoration inputDecoration(
    BuildContext context, {
    required String hintText,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : colors.onSurfaceMuted.withOpacity(0.7),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                prefixIcon,
                color: kPrimaryColor.withOpacity(0.7),
                size: 22,
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffix: suffix,
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: kPrimaryColor,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: colors.divider.withOpacity(0.3),
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: kErrorColor.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: kErrorColor,
          width: 2,
        ),
      ),
    );
  }

  /// Modern card decoration for list items
  static BoxDecoration cardDecoration(BuildContext context, {bool isSelected = false}) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return BoxDecoration(
      gradient: isSelected
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryColor.withOpacity(isDark ? 0.2 : 0.12),
                kPrimaryColor.withOpacity(isDark ? 0.1 : 0.06),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.03),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFFAFBFC),
                    ],
            ),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: isSelected
            ? kPrimaryColor.withOpacity(0.4)
            : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04)),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  /// Modern list tile decoration for selectable items
  static BoxDecoration listTileDecoration(
    BuildContext context, {
    bool isSelected = false,
  }) {
    return cardDecoration(context, isSelected: isSelected);
  }

  /// Icon container decoration with gradient
  static BoxDecoration iconContainerDecoration(
    BuildContext context, {
    Color? color,
  }) {
    final baseColor = color ?? kPrimaryColor;
    final colors = context.appColors;
    final isDark = colors.isDark;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withOpacity(isDark ? 0.25 : 0.15),
          baseColor.withOpacity(isDark ? 0.15 : 0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: baseColor.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  /// Loading indicator style
  static Widget loadingIndicator(BuildContext context, {double size = 22}) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

/// Modern dialog header widget with enhanced styling
class ModernDialogHeader extends StatelessWidget {
  const ModernDialogHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ModernDialogStyles.headerPaddingV,
        horizontal: ModernDialogStyles.headerPaddingH,
      ),
      decoration: BoxDecoration(
        // Light mode: subtle primary tint like sales picker, Dark mode: gradient
        color: isDark ? null : kPrimaryColor.withOpacity(0.1),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D3A4F),
                  Color(0xFF1A2332),
                ],
              )
            : null,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ModernDialogStyles.headerRadius),
        ),
      ),
      child: Row(
        children: [
          // Icon container - glass effect in dark, subtle circle in light
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? null : kPrimaryColor.withOpacity(0.15),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.1),
                      ],
                    )
                  : null,
              shape: BoxShape.circle,
              border: isDark
                  ? Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : kPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : kPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Modern dialog container with enhanced visual styling
class ModernDialogContainer extends StatelessWidget {
  const ModernDialogContainer({
    super.key,
    required this.child,
    this.maxHeight,
    this.maxWidth,
  });

  final Widget child;
  final double? maxHeight;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? 520,
        maxWidth: maxWidth ?? double.infinity,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  colors.surface,
                  colors.surface.withOpacity(0.98),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFCFCFD),
                ],
        ),
        borderRadius: BorderRadius.circular(ModernDialogStyles.dialogRadius),
        // Border only in dark mode
        border: isDark
            ? Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Modern loading state widget with enhanced visuals
class ModernLoadingState extends StatefulWidget {
  const ModernLoadingState({
    super.key,
    required this.message,
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  State<ModernLoadingState> createState() => _ModernLoadingStateState();
}

class _ModernLoadingStateState extends State<ModernLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryColor.withOpacity(isDark ? 0.25 : 0.15),
                    kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceMuted.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern error state widget with enhanced visuals
class ModernErrorState extends StatelessWidget {
  const ModernErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kErrorColor.withOpacity(isDark ? 0.25 : 0.15),
                  kErrorColor.withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: kErrorColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: kErrorColor.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: kErrorColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : colors.onSurfaceMuted,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryColor,
                    kPrimaryColor.withBlue(220),
                  ],
                ),
                borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          retryText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern empty state widget with enhanced visuals
class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        const Color(0xFFF0F4F8),
                        const Color(0xFFE8EEF4),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: colors.onSurfaceMuted.withOpacity(0.7),
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
