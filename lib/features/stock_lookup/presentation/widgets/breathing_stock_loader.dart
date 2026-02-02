import 'package:flutter/material.dart';
//import 'package:lottie/lottie.dart';
import 'package:rmstock_scanner/constants/colors.dart';

class BreathingStockLoader extends StatefulWidget {
  const BreathingStockLoader({super.key});

  @override
  State<BreathingStockLoader> createState() => _BreathingStockLoaderState();
}

class _BreathingStockLoaderState extends State<BreathingStockLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Creates a repeating "breathing" effect (2 seconds per cycle)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Breathing Ring
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withOpacity(0.05), // Very faint
            ),
          ),
        ),
        
        // Inner Static Ring (Anchors the design)
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryColor.withOpacity(0.1),
          ),
        ),
    
        // Your Lottie Animation
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 20),
        //   child: SizedBox(
        //     width: 200, // Slightly smaller to fit inside rings
        //     height: 200,
        //     child: Lottie.asset(
        //       "assets/animations/empty.json",
        //       fit: BoxFit.fill,
        //     ),
        //   ),
        // ),
        SizedBox(
          width: 80, // Slightly smaller to fit inside rings
          height: 80,
          child: Image.asset(
            "assets/images/empty.png",
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}