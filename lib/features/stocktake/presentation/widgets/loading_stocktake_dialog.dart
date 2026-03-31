import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/modern_dialog_styles.dart';
import '../../../../utils/dialog_size_utils.dart';

class LoadingStocktakeDialog extends StatefulWidget {
  const LoadingStocktakeDialog({super.key});

  @override
  State<LoadingStocktakeDialog> createState() => _LoadingStocktakeDialogState();
}

class _LoadingStocktakeDialogState extends State<LoadingStocktakeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: ModernDialogStyles.dialogShape,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ModernDialogContainer(
        maxHeight: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModernDialogHeader(
              title: "Stocktaking",
              icon: Icons.inventory_2_outlined,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kPrimaryColor.withOpacity(isDark ? 0.2 : 0.15),
                                    kPrimaryColor.withOpacity(isDark ? 0.1 : 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Validating Stocktake Data",
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This may take a few seconds...",
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
