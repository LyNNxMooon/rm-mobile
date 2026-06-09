import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// The progress stages shown in the finalise step indicator.
enum FinaliseStep { itemsLoaded, optionsSaved, processing, completed }

/// Drives the [_FinaliseStepper]. The picker owns one of these and hands it to
/// the sales flow so processing/completed can be reported back without leaving
/// the picker screen.
class FinaliseStepController extends ValueNotifier<FinaliseStep> {
  // Starts on the 2nd step: the screen opens with the optional actions locked
  // (not in edit mode), so options are considered already saved.
  FinaliseStepController() : super(FinaliseStep.optionsSaved);

  void setItemsLoaded() {
    if (value == FinaliseStep.itemsLoaded ||
        value == FinaliseStep.optionsSaved) {
      value = FinaliseStep.itemsLoaded;
    }
  }

  void setOptionsSaved() {
    if (value == FinaliseStep.itemsLoaded ||
        value == FinaliseStep.optionsSaved) {
      value = FinaliseStep.optionsSaved;
    }
  }

  void setProcessing() => value = FinaliseStep.processing;
  void setCompleted() => value = FinaliseStep.completed;

  /// Forces the indicator back to the 2nd step (used when a commit fails).
  void revertToOptionsSaved() => value = FinaliseStep.optionsSaved;
}

/// Screen shown when the user taps "Finalise" on the unified Sales screen.
/// The user picks the transaction type (Account Sales / Sales Order /
/// Quotes / Lay-bys). Returns the picked title via [Navigator.pop], or
/// `null` if the user cancels.
///
/// The lower "Payments" section is intentionally disabled (Coming Soon).
class FinalisePickerScreen extends StatefulWidget {
  final bool isAccountCustomer;

  /// Invoked when the user taps a transaction type. The finalise flow
  /// (validation prompts + the FinaliseSaleDialog) runs on top of this picker.
  /// The [controller] lets the flow report Processing/Completed back to the
  /// step indicator. Returns `true` when the picker should be closed.
  final Future<bool> Function(
    BuildContext pickerContext,
    String type,
    FinaliseStepController controller,
  )? onFinaliseType;

  /// Invoked when the user taps an optional action (Survey/Comment/Delivery/
  /// Discount). The action's dialog is shown on top of this picker; the picker
  /// stays open.
  final void Function(BuildContext pickerContext, String action)?
      onOptionalAction;

  const FinalisePickerScreen({
    super.key,
    this.isAccountCustomer = false,
    this.onFinaliseType,
    this.onOptionalAction,
  });

  static Future<String?> show(
    BuildContext context, {
    bool isAccountCustomer = false,
    Future<bool> Function(
      BuildContext pickerContext,
      String type,
      FinaliseStepController controller,
    )? onFinaliseType,
    void Function(BuildContext pickerContext, String action)? onOptionalAction,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FinalisePickerScreen(
          isAccountCustomer: isAccountCustomer,
          onFinaliseType: onFinaliseType,
          onOptionalAction: onOptionalAction,
        ),
      ),
    );
  }

  @override
  State<FinalisePickerScreen> createState() => _FinalisePickerScreenState();
}

class _FinalisePickerScreenState extends State<FinalisePickerScreen> {
  final FinaliseStepController _stepController = FinaliseStepController();

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _handleActionTap(BuildContext context, String action) {
    final handler = widget.onOptionalAction;
    if (handler == null) {
      Navigator.of(context).pop('action:$action');
      return;
    }
    handler(context, action);
  }

  Future<void> _handleTypeTap(BuildContext context, String value) async {
    final handler = widget.onFinaliseType;
    if (handler == null) {
      Navigator.of(context).pop(value);
      return;
    }
    final shouldClose = await handler(context, value, _stepController);
    if (shouldClose && context.mounted) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final types = <_TxType>[
      if (widget.isAccountCustomer)
        const _TxType(
          label: 'Account',
          value: 'Account Sales',
          icon: Icons.contact_page_outlined,
          color: Color(0xFFD59BF5),
        ),
      const _TxType(
        label: 'Sales Order',
        value: 'Sales Order',
        icon: Icons.shopping_cart_outlined,
        color: Color(0xFF91E2E6),
      ),
      const _TxType(
        label: 'Quote',
        value: 'Quotes',
        icon: Icons.edit_document,
        color: Color(0xFFFFDE94),
      ),
      const _TxType(
        label: 'Lay-by',
        value: 'Lay-bys',
        icon: Icons.folder_open_rounded,
        color: Color(0xFF7F26B3),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : kBgColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9CE5A6),
        elevation: 0,
        leading: Center(
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: Colors.black, size: 22),
              ),
            ),
          ),
        ),
        title: const Text(
          'Finalise',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: useDesktopNav ? 32 : (isTablet ? 24 : 16),
            vertical: 16,
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _FinaliseStepper(
                controller: _stepController,
                isDark: isDark,
                isTablet: isTablet && !useDesktopNav,
              ),
              const SizedBox(height: 32),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(height: 32),
              _OptionalActionsSection(
                isTablet: isTablet && !useDesktopNav,
                isDark: isDark,
                scaffoldColor: isDark ? Colors.black : kBgColor,
                titleSize: (isTablet && !useDesktopNav) ? 18 : 16,
                stepController: _stepController,
                onAction: (action) => _handleActionTap(context, action),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Choose Transaction Type',
                titleSize: (isTablet && !useDesktopNav) ? 18 : 16,
                expandChild: false,
                isDark: isDark,
                child: ValueListenableBuilder<FinaliseStep>(
                  valueListenable: _stepController,
                  builder: (context, step, child) {
                    final bool editing = step == FinaliseStep.itemsLoaded;
                    return IgnorePointer(
                      ignoring: editing,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: editing ? 0.4 : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: useDesktopNav
                        ? 4
                        : (isTablet ? (isLandscape ? 4 : 3) : 2),
                    mainAxisSpacing: isTablet ? 16 : 12,
                    crossAxisSpacing: isTablet ? 16 : 12,
                    childAspectRatio: useDesktopNav
                        ? 2.6
                        : (isTablet ? (isLandscape ? 3.3 : 2.6) : 2.4),
                    children: types
                        .map((t) => _TypeCard(
                              type: t,
                              isDark: isDark,
                              isTablet: isTablet && !useDesktopNav,
                              onTap: () => _handleTypeTap(context, t.value),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Payments',
                titleSize: (isTablet && !useDesktopNav) ? 18 : 16,
                expandChild: false,
                isDark: isDark,
                child: SizedBox(
                  height: 220,
                  child: _buildComingSoon(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    double titleSize = 16,
    bool expandChild = true,
    bool isDark = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: titleSize,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (expandChild) Expanded(child: child) else child,
      ],
    );
  }

  Widget _buildComingSoon(bool isDark) {
    final Color fg = isDark ? Colors.white : Colors.black;
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? Colors.white24 : Colors.black26),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: fg.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxType {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TxType({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _TypeCard extends StatelessWidget {
  final _TxType type;
  final bool isDark;
  final bool isTablet;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isDark,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final double iconBox = isTablet ? 60 : 44;
    final double glyphSize = isTablet ? 30 : 22;
    final double gap = isTablet ? 16 : 12;
    final double labelSize = isTablet ? 18 : 14;
    return Material(
      color: Colors.transparent,
      borderRadius: isTablet? BorderRadius.circular(60) : BorderRadius.circular(40),
      child: InkWell(
        borderRadius: isTablet? BorderRadius.circular(60) : BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 14,
            vertical: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? colors.surface : kSecondaryColor,
            borderRadius: isTablet? BorderRadius.circular(60) : BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : kThirdColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: type.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: Colors.black,
                  size: glyphSize,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: labelSize,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinaliseStepper extends StatefulWidget {
  final FinaliseStepController controller;
  final bool isDark;
  final bool isTablet;

  const _FinaliseStepper({
    required this.controller,
    required this.isDark,
    required this.isTablet,
  });

  @override
  State<_FinaliseStepper> createState() => _FinaliseStepperState();
}

class _FinaliseStepperState extends State<_FinaliseStepper>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF9CE5A6);

  late final AnimationController _fillController;
  late final AnimationController _pulseController;
  Animation<double> _fillAnim = const AlwaysStoppedAnimation<double>(0.0);

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    // Animate the line splashing into the initial step on first load.
    final initialTarget = _targetFor(widget.controller.value);
    _fillAnim = Tween<double>(begin: 0.0, end: initialTarget).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fillController.forward(from: 0);
    });
    widget.controller.addListener(_onStepChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStepChanged);
    _fillController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _targetFor(FinaliseStep step) {
    switch (step) {
      case FinaliseStep.itemsLoaded:
        return 0.0;
      case FinaliseStep.optionsSaved:
        return 0.5;
      case FinaliseStep.processing:
        return 0.8;
      case FinaliseStep.completed:
        return 1.0;
    }
  }

  void _onStepChanged() {
    final begin = _fillAnim.value;
    final target = _targetFor(widget.controller.value);
    _fillAnim = Tween<double>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );
    _fillController.forward(from: 0);
    if (mounted) setState(() {});
  }

  ({String asset, String label}) _statusData(FinaliseStep step) {
    switch (step) {
      case FinaliseStep.itemsLoaded:
        return (asset: 'ready', label: 'Items loaded');
      case FinaliseStep.optionsSaved:
        return (asset: 'options', label: 'Options saved');
      case FinaliseStep.processing:
        return (asset: 'processing', label: 'Processing\u2026');
      case FinaliseStep.completed:
        return (asset: 'complete', label: 'Completed');
    }
  }

  Widget _statusHeader(FinaliseStep step) {
    final data = _statusData(step);
    final String path =
        'assets/images/${data.asset}-${widget.isDark ? 'dark' : 'light'}.png';
    final double iconSize = widget.isTablet ? 80 : 68;
    final double labelSize = widget.isTablet ? 30 : 26;
    final Color labelColor = widget.isDark ? Colors.white : Colors.black87;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.18),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey<FinaliseStep>(step),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              data.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: labelSize,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Image.asset(
            path,
            width: iconSize,
            height: iconSize,
            errorBuilder: (_, _, _) => Icon(
              Icons.info_outline,
              size: iconSize,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tick(bool active) {
    final double size = widget.isTablet ? 22 : 18;
    final double outer = size + (widget.isTablet ? 10 : 8);
    final Color inactiveBorder =
        widget.isDark ? Colors.white30 : Colors.black26;
    return Container(
      width: outer,
      height: outer,
      alignment: Alignment.center,
      // Outer outlined ring layer.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? _accent.withOpacity(0.5)
              : inactiveBorder.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _accent : Colors.transparent,
          border: Border.all(
            color: active ? _accent : inactiveBorder,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: size * 0.6,
          color: active ? Colors.black : Colors.transparent,
        ),
      ),
    );
  }

  Widget _line(double fraction, {required bool pulse}) {
    final Color track = widget.isDark ? Colors.white24 : Colors.black26;
    final double f = fraction.clamp(0.0, 1.0);
    final bool animating = _fillController.isAnimating || pulse;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 22,
          child: CustomPaint(
            painter: _LiquidLinePainter(
              fraction: f,
              animating: animating,
              phase: _pulseController.value,
              fillColor: _accent,
              trackColor: track,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fillController, _pulseController]),
      builder: (context, _) {
        final FinaliseStep step = widget.controller.value;
        final double p = _fillAnim.value;
        final double line1 = (p / 0.5).clamp(0.0, 1.0);
        final double line2 = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
        final bool tick2Active = p >= 0.5 - 0.001;
        final bool tick3Active =
            step == FinaliseStep.completed && p >= 0.999;
        final bool processing = step == FinaliseStep.processing;
        return Column(
          children: [
            const SizedBox(height: 12),
            _statusHeader(step),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.isTablet ? 680 : 320,
                ),
                child: Row(
                  children: [
                    _tick(true),
                    _line(line1, pulse: false),
                    _tick(tick2Active),
                    _line(line2, pulse: processing),
                    _tick(tick3Active),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

/// Paints the connecting line. When idle the track is a dotted line. While a
/// step transition is in progress the filled portion becomes a continuous
/// liquid bar whose wavy surface flows toward the next point, like water
/// streaming along the line.
class _LiquidLinePainter extends CustomPainter {
  final double fraction;
  final bool animating;
  final double phase; // 0..1 repeating
  final Color fillColor;
  final Color trackColor;

  _LiquidLinePainter({
    required this.fraction,
    required this.animating,
    required this.phase,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double w = size.width;
    final double headX = (fraction.clamp(0.0, 1.0)) * w;

    const double dotR = 2.0;
    const double gap = 3.5;
    final double stepX = dotR * 2 + gap;
    final Paint dot = Paint()..style = PaintingStyle.fill;

    if (!animating) {
      // Idle: dotted track. Green dots up to the fill head, faint dots beyond.
      for (double x = dotR; x <= w; x += stepX) {
        dot.color = x <= headX ? fillColor : trackColor;
        canvas.drawCircle(Offset(x, cy), dotR, dot);
      }
      return;
    }

    // Animating: faint dots only for the not-yet-reached portion.
    for (double x = headX + stepX; x <= w; x += stepX) {
      dot.color = trackColor;
      canvas.drawCircle(Offset(x, cy), dotR, dot);
    }

    if (headX <= 0.5) return;

    // Continuous liquid bar from start to the leading head, with a wavy
    // surface that flows forward.
    const double barH = 6.0;
    const double amp = 0.8; // wave amplitude
    final double topBase = cy - barH / 2;
    final double botBase = cy + barH / 2;
    final double travel = phase * 2 * math.pi; // flow offset

    final Path liquid = Path()..moveTo(0, topBase);
    const double dx = 2.0;
    // Top surface, rippling toward the head.
    for (double x = 0; x <= headX; x += dx) {
      final double k = x / 18.0;
      final double y = topBase + math.sin(k - travel) * amp;
      liquid.lineTo(x, y);
    }
    // Rounded leading head.
    liquid.lineTo(headX, botBase);
    // Bottom surface back to the start.
    for (double x = headX; x >= 0; x -= dx) {
      final double k = x / 18.0;
      final double y = botBase + math.sin(k - travel + math.pi) * amp;
      liquid.lineTo(x, y);
    }
    liquid.close();

    final Paint body = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(liquid, body);
  }

  @override
  bool shouldRepaint(covariant _LiquidLinePainter old) =>
      old.fraction != fraction ||
      old.animating != animating ||
      old.phase != phase ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor;
}

class _OptionalActionsSection extends StatefulWidget {
  final bool isTablet;
  final bool isDark;
  final Color scaffoldColor;
  final double titleSize;
  final FinaliseStepController stepController;
  final void Function(String action) onAction;

  const _OptionalActionsSection({
    required this.isTablet,
    required this.isDark,
    required this.scaffoldColor,
    required this.titleSize,
    required this.stepController,
    required this.onAction,
  });

  @override
  State<_OptionalActionsSection> createState() =>
      _OptionalActionsSectionState();
}

class _OptionalActionsSectionState extends State<_OptionalActionsSection> {
  static const Color _accent = Color(0xFF9CE5A6);
  bool _editing = false;

  void _toggleEditing() {
    setState(() => _editing = !_editing);
    // Entering edit mode -> back to "Items loaded"; leaving edit mode means the
    // options have been saved.
    if (_editing) {
      widget.stepController.setItemsLoaded();
    } else {
      widget.stepController.setOptionsSaved();
    }
  }

  Widget _action(String label, IconData icon, bool filled) {
    return Expanded(
      child: _ActionCard(
        label: label,
        icon: icon,
        filled: filled,
        isTablet: widget.isTablet,
        onTap: _editing ? () => widget.onAction(label) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _editing
        ? _accent
        : (widget.isDark ? Colors.white24 : Colors.black26);
    final Color titleColor = widget.isDark ? Colors.white : Colors.black;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bordered "fieldset" container. Top padding leaves room for the
        // legend title that overlaps the top border.
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(10, 22, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _editing ? 1.0 : 0.45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _action('Survey', Icons.poll_outlined, false),
                _action('Comment', Icons.comment_outlined, false),
                _action('Delivery', Icons.local_shipping_outlined, true),
                _action('Discount', Icons.discount_outlined, true),
              ],
            ),
          ),
        ),
        // Legend: title overlapping the top-left border. The scaffold-coloured
        // background "cuts" the border line behind it.
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            color: widget.scaffoldColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Optional Actions',
              style: TextStyle(
                color: titleColor,
                fontSize: widget.titleSize,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        // Edit/save toggle overlapping the top-right border.
        Positioned(
          right: 14,
          top: 0,
          child: Container(
            color: widget.scaffoldColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: _editing
                  ? _accent
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleEditing,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _editing
                          ? _accent
                          : (widget.isDark
                              ? Colors.white24
                              : Colors.black26),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          _editing
                              ? Icons.check_rounded
                              : Icons.edit_outlined,
                          key: ValueKey<bool>(_editing),
                          size: 16,
                          color: _editing
                              ? Colors.black
                              : (widget.isDark
                                  ? Colors.white70
                                  : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _editing ? 'Done' : 'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: _editing
                              ? Colors.black
                              : (widget.isDark
                                  ? Colors.white70
                                  : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isTablet;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.filled,
    this.isTablet = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.appColors.isDark;
    final double circleSize = isTablet ? 52 : 46;
    final double glyphSize = isTablet ? 24 : 20;
    final double labelSize = isTablet ? 15 : 13;
    final Color iconColor = filled
        ? (isDark ? Colors.black : kThirdColor)
        : (isDark ? const Color(0xFF9CE5A6) : kThirdColor);
    final Color labelColor = isDark ? Colors.white : kThirdColor;
    return InkWell(
      borderRadius: BorderRadius.circular(circleSize),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? const Color(0xFF9CE5A6) : Colors.transparent,
                shape: BoxShape.circle,
                border: filled
                    ? null
                    : Border.all(color: const Color(0xFF9CE5A6), width: 1.5),
              ),
              child: Icon(
                icon,
                size: glyphSize,
                color: iconColor,
              ),
            ),
            SizedBox(height: isTablet ? 10 : 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: labelSize,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
