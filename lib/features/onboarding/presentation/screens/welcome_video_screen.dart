import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/colors.dart';
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
    final media = MediaQuery.of(context);
    final size = media.size;
    final shortestSide = size.shortestSide;
    final orientation = media.orientation;
    final isTablet = shortestSide >= 600;
    final isLargeTablet = shortestSide >= 900;
    final scale = (shortestSide / 375).clamp(1.0, 1.25);
    final horizontalPadding = (isLargeTablet ? 64.0 : isTablet ? 48.0 : 24.0) * scale;
    final verticalPadding = (isLargeTablet ? 48.0 : 32.0) * scale;
    final logoWidth = (isTablet ? 140.0 : 100.0) * scale;
    final logoHeight = (isTablet ? 60.0 : 45.0) * scale;
    final headlineFontSize = (isLargeTablet ? 50.0 : isTablet ? 46.0 : 42.0) * scale;
    final bodyFontSize = (isLargeTablet ? 18.0 : 16.0) * scale;
    const buttonHeight = 56.0;
    const buttonFontSize = 18.0;
    final contentMaxWidth = isTablet ? 520.0 * scale : double.infinity;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isTablet)
            Image.asset(
              orientation == Orientation.landscape
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
                          color: Colors.white,
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
                          color: Colors.white.withOpacity(0.85),
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 48 * scale),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: kSecondaryColor,
                            minimumSize: const Size(double.infinity, buttonHeight),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Continue",
                              textScaler: TextScaler.noScaling,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kSecondaryColor,
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
            ),
          ),
        ],
      ),
    );
  }
}
