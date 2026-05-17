import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/utils/responsive_utils.dart';
import 'package:video_player/video_player.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  double _coverScale({required Size parent, required Size child}) {
    final widthScale = parent.width / child.width;
    final heightScale = parent.height / child.height;
    return widthScale > heightScale ? widthScale : heightScale;
  }

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/videos/welcome_bg.mp4',
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setVolume(0.0);
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final size = media.size;
    final shortestSide = size.shortestSide;
    final orientation = media.orientation;
    final isTablet = context.isTablet;
    final isLargeTablet = context.isLargeTablet;
    // Use image instead of video for desktop platforms (Windows/Linux/macOS) or tablets
    final bool isDesktopPlatform = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final bool useImage = isTablet || isDesktopPlatform;
    // Desktop: no scaling to keep fonts reasonable; mobile/tablet: scale as before
    final scale = isDesktopPlatform ? 1.0 : (shortestSide / 375).clamp(1.0, 1.25);
    final horizontalPadding = isDesktopPlatform ? 50.0 : (isLargeTablet ? 64.0 : isTablet ? 48.0 : 24.0) * scale;
    final verticalPadding = isDesktopPlatform ? 50.0 : (isLargeTablet ? 48.0 : 32.0) * scale;
    final logoWidth = isDesktopPlatform ? 120.0 : (isTablet ? 140.0 : 100.0) * scale;
    final logoHeight = isDesktopPlatform ? 50.0 : (isTablet ? 60.0 : 45.0) * scale;
    // Desktop: smaller fonts (36 headline, 15 body)
    final headlineFontSize = isDesktopPlatform ? 36.0 : (isLargeTablet ? 50.0 : isTablet ? 40.0 : 42.0) * scale;
    final bodyFontSize = isDesktopPlatform ? 15.0 : (isLargeTablet ? 18.0 : 16.0) * scale;
    final buttonHeight = isDesktopPlatform ? 48.0 : 56.0;
    final buttonFontSize = isDesktopPlatform ? 15.0 : 18.0;
    // Use constrained content width on desktop for comfortable reading
    final contentMaxWidth = isDesktopPlatform 
        ? 480.0 
        : (isTablet ? 520.0 * scale : double.infinity);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Use image for tablets AND desktop platforms
          if (useImage)
            Image.asset(
              orientation == Orientation.landscape || isDesktopPlatform
                  ? 'assets/images/landscape.jpg'
                  : 'assets/images/portrait.jpg',
              fit: BoxFit.cover,
            )
          else if (_isVideoInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
                final videoSize = _videoController.value.size;
                final scaleFactor = _coverScale(parent: parentSize, child: videoSize);

                return ClipRect(
                  child: Center(
                    child: SizedBox(
                      width: videoSize.width * scaleFactor,
                      height: videoSize.height * scaleFactor,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                );
              },
            ),
          Container(
            color: Colors.black.withOpacity(0.45),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: logoWidth,
                                  height: logoHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * scale,
                                    vertical: 4 * scale,
                                  ),
                                  child: Image.asset(
                                    'assets/images/aaapos.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Smart inventory management, \nRight in your pocket.",
                                  style: TextStyle(
                                    color: colors.onHero,
                                    fontSize: headlineFontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 16 * scale),
                                Text(
                                  "The complete Point of Sale solution for your mobile device.",
                                  style: TextStyle(
                                    color: colors.onHero.withOpacity(0.85),
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 40 * scale),
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: widget.onContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      foregroundColor: colors.onHero,
                                      minimumSize: Size(double.infinity, buttonHeight),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      textStyle: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Continue",
                                        textScaler: TextScaler.noScaling,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.onHero,
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20 * scale),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
