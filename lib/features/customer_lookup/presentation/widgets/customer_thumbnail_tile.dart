import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';

import '../../../../constants/colors.dart';

class CustomerThumbnailTile extends StatelessWidget {
  final CustomerVO customer;

  const CustomerThumbnailTile({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.people_alt_rounded,
        color: kPrimaryColor,
        size: 20,
      ),
    );
  }
}
