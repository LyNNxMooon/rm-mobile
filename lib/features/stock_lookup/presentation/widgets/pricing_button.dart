import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';

class PricingButton extends StatelessWidget {
  const PricingButton({
    super.key,
    required this.onTap,
    required this.verticalPadding,
  });

  final VoidCallback onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: _buttonDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sell_outlined,
              color: kPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "PRICING",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buttonDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kSecondaryColor.withOpacity(0.95),
          kSecondaryColor.withOpacity(0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: kSecondaryColor.withOpacity(0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: kThirdColor.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
