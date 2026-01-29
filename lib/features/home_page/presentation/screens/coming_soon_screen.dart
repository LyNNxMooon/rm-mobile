import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;

  const ComingSoonScreen({super.key, this.featureName = "This feature"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.navigateBack(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSecondaryColor,
            size: 20,
          ),
        ),
        title: Text("Coming Soon", style: getSmartTitle()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.1),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 60,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "We're working on it!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kThirdColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "$featureName is currently under construction. We're working hard to bring it to you soon.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: kGreyColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  AlertInfo.show(
                    context: context,
                    text: "You'll be notified when it is ready!",
                    typeInfo: TypeInfo.success,
                    backgroundColor: kSecondaryColor,
                    iconColor: kPrimaryColor,
                    textColor: kThirdColor,
                    padding: 70,
                    position: MessagePosition.top,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text("Notify Me When Ready"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => context.navigateBack(),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text("Go Back"),
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
