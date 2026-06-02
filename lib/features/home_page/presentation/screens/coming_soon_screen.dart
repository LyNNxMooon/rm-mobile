import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;

  const ComingSoonScreen({super.key, this.featureName = "This feature"});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final bool isDesktopOrTablet = isTablet || useDesktopNav;
    final double outerCircle = isDesktopOrTablet ? 210 : 160;
    final double innerCircle = isDesktopOrTablet ? 160 : 120;
    final double iconSize = isDesktopOrTablet ? 78 : 60;
    final double buttonHeight = isDesktopOrTablet ? 48 : 50;
    final double sidePadding = useDesktopNav ? 50 : (isTablet ? 60 : 30);
    final double maxContentWidth = useDesktopNav ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.navigateBack(),
          icon: Icon(
            Icons.home_filled,
            color: colors.onHero,
            size: 20,
          ),
        ),
        title: Text(
          "Coming Soon",
          style: getSmartTitle(color: colors.onHero, fontSize: useDesktopNav ? 18 : 20),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.1),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: outerCircle,
                          height: outerCircle,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor.withOpacity(0.1),
                          ),
                        ),
                        Container(
                          width: innerCircle,
                          height: innerCircle,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor.withOpacity(0.3),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.rocket_launch_rounded,
                              size: iconSize,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "We're working on it!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "$featureName is currently under construction. We're working hard to bring it to you soon.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    isDesktopOrTablet
                        ? Center(
                            child: SizedBox(
                              width: 280,
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: () {
                                  AlertInfo.show(
                                    context: context,
                                    text: "You'll be notified when it is ready!",
                                    typeInfo: TypeInfo.success,
                                    backgroundColor: colors.surface,
                                    iconColor: kPrimaryColor,
                                    textColor: colors.onSurface,
                                    padding: 70,
                                    position: MessagePosition.top,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: colors.onHero,
                                  minimumSize: Size(280, buttonHeight),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: const Text(
                                  "Notify Me When Ready",
                                  textScaler: TextScaler.noScaling,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {
                                AlertInfo.show(
                                  context: context,
                                  text: "You'll be notified when it is ready!",
                                  typeInfo: TypeInfo.success,
                                  backgroundColor: colors.surface,
                                  iconColor: kPrimaryColor,
                                  textColor: colors.onSurface,
                                  padding: 70,
                                  position: MessagePosition.top,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: colors.onHero,
                                minimumSize: Size(double.infinity, buttonHeight),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text(
                                "Notify Me When Ready",
                                textScaler: TextScaler.noScaling,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    isDesktopOrTablet
                        ? Center(
                            child: SizedBox(
                              width: 280,
                              height: buttonHeight,
                              child: TextButton(
                                onPressed: () => context.navigateBack(),
                                style: TextButton.styleFrom(
                                  foregroundColor: kPrimaryColor,
                                  minimumSize: Size(280, buttonHeight),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: const Text(
                                  "Go Back",
                                  textScaler: TextScaler.noScaling,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: TextButton(
                              onPressed: () => context.navigateBack(),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                                minimumSize: Size(double.infinity, buttonHeight),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text(
                                "Go Back",
                                textScaler: TextScaler.noScaling,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: constraints.maxHeight * 0.15),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
