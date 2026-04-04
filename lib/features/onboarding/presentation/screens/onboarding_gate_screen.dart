import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/theme_colors.dart';
//import 'package:rmstock_scanner/constants/global_widgets.dart';
import 'package:rmstock_scanner/constants/txt_styles.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/screens/index_screen.dart';
import 'package:rmstock_scanner/features/onboarding/onboarding_content.dart';
import 'package:rmstock_scanner/features/onboarding/presentation/screens/welcome_video_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/onboarding/presentation/BLoC/onboarding_bloc.dart';
import 'package:rmstock_scanner/utils/responsive_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnboardingGateScreen extends StatefulWidget {
  const OnboardingGateScreen({super.key});

  @override
  State<OnboardingGateScreen> createState() => _OnboardingGateScreenState();
}

class _OnboardingGateScreenState extends State<OnboardingGateScreen> {
  bool _isLoading = true;
  bool _termsAccepted = false;
  bool _movedToWelcomeInCurrentLaunch = false;
  bool _movedToTermsInCurrentLaunch = false;

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(LoadOnboardingStatusEvent());
  }

  Future<void> _onWelcomeContinue() async {
    if (!mounted) return;
    setState(() {
      _movedToTermsInCurrentLaunch = true;
    });
  }

  Future<void> _onVideoWelcomeContinue() async {
    if (!mounted) return;
    setState(() {
      _movedToWelcomeInCurrentLaunch = true;
    });
  }

  Future<void> _onTermsAgree() async {
    context.read<OnboardingBloc>().add(SetTermsAcceptedEvent(true));
    if (!mounted) return;
  }

  Future<void> _onTermsDecline() async {
    context.read<OnboardingBloc>().add(SetTermsAcceptedEvent(false));
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_isLoading) {
      body = Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.appColors.heroGradient),
          child: SizedBox()
        ),
      );
    } else if (!_termsAccepted && !_movedToTermsInCurrentLaunch) {
      if (!_movedToWelcomeInCurrentLaunch) {
        body = WelcomeScreen(onContinue: _onVideoWelcomeContinue);
      } else {
        body = _WelcomeScreen(onContinue: _onWelcomeContinue);
      }
    } else if (!_termsAccepted) {
      body = _TermsScreen(onAgree: _onTermsAgree, onDecline: _onTermsDecline);
    } else {
      body = const IndexScreen();
    }

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is OnboardingLoaded) {
          setState(() {
            _termsAccepted = state.termsAccepted;
            _isLoading = false;
          });
        } else if (state is OnboardingError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: body,
    );
  }
}

class _WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const _WelcomeScreen({required this.onContinue});

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _bodyFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.55), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.72, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.68, curve: Curves.easeOut),
      ),
    );

    _bodySlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _bodyFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    const double horizontalPadding = 22;
    final double mobileContentWidth = (media.size.width - (horizontalPadding * 2))
        .clamp(220.0, media.size.width);
    final double cardMaxWidth = isTablet
        ? (media.size.width * 0.68).clamp(440.0, 760.0)
        : media.size.width;
    final double logoWidth = isTablet
        ? (media.size.width * 0.52).clamp(320.0, 500.0)
        : mobileContentWidth;
    final double logoHeight = (logoWidth * 0.22).clamp(56.0, 110.0);
    final double logoCardGap = isTablet ? 28 : 36;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.appColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Center(
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: SizedBox(
                          width: logoWidth,
                          height: logoHeight,
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? "assets/images/trademark_dark.png"
                                : "assets/images/trademark.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: logoCardGap),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                          decoration: BoxDecoration(
                            color: colors.glassFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeTransition(
                                opacity: _titleFade,
                                child: SlideTransition(
                                  position: _titleSlide,
                                  child: Text(
                                    "Welcome!",
                                    style: getSmartTitle(
                                      color: colors.onHero,
                                      fontSize: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FadeTransition(
                                opacity: _bodyFade,
                                child: SlideTransition(
                                  position: _bodySlide,
                                  child: Text(
                                    kWelcomeContent,
                                    style: TextStyle(
                                      color: colors.onHero.withOpacity(0.92),
                                      height: 1.45,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: widget.onContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    foregroundColor: colors.onHero,
                                    minimumSize: const Size(double.infinity, 42),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "App Version 1.0.0 (AAAPOS Pty Ltd)",
                    style: TextStyle(
                      color: colors.onHero.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsScreen extends StatefulWidget {
  final VoidCallback onAgree;
  final VoidCallback onDecline;

  const _TermsScreen({required this.onAgree, required this.onDecline});

  @override
  State<_TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<_TermsScreen> {
  WebViewController? _webViewController;
  bool _isWebLoading = true;
  bool _isAgreed = false;
  final bool _isDesktop = Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    if (!_isDesktop) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() => _isWebLoading = true);
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() => _isWebLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(kTermsAndConditionsUrl));
    }
  }

  Future<void> _openTermsInBrowser() async {
    final uri = Uri.parse(kTermsAndConditionsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.appColors.heroGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: colors.glassFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Terms & Conditions",
                            style: getSmartTitle(
                              color: colors.onHero,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colors.divider,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _isDesktop
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.description_outlined,
                                            size: 64,
                                            color: colors.onSurface.withOpacity(0.6),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Please review our Terms & Conditions",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: _openTermsInBrowser,
                                            icon: const Icon(Icons.open_in_new),
                                            label: const Text("Open in Browser"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimaryColor,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        WebViewWidget(
                                          controller: _webViewController!,
                                        ),
                                        if (_isWebLoading)
                                          Container(
                                            color: colors.surface.withOpacity(0.65),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: kPrimaryColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _isAgreed,
                                activeColor: kPrimaryColor,
                                checkColor: colors.onHero,
                                side: BorderSide(
                                  color: colors.onHero.withOpacity(0.85),
                                ),
                                onChanged: (v) {
                                  setState(() => _isAgreed = v ?? false);
                                },
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    "I agree to the Terms & Conditions and Privacy Policy.",
                                    style: TextStyle(
                                      color: colors.onHero.withOpacity(0.95),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: widget.onDecline,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.onHero,
                                      minimumSize: const Size(double.infinity, 40),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: colors.onHero.withOpacity(0.7),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Decline",
                                        textScaler: TextScaler.noScaling,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.onHero,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: _isAgreed ? widget.onAgree : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      foregroundColor: colors.onHero,
                                      disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
                                      disabledForegroundColor: colors.onHero.withOpacity(0.6),
                                      minimumSize: const Size(double.infinity, 40),
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Agree",
                                        textScaler: TextScaler.noScaling,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.onHero,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
