
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';
import '../../../home_page/presentation/BLoC/home_screen_states.dart';

class StockLookupAppbar extends StatefulWidget {
  const StockLookupAppbar({super.key});

  @override
  State<StockLookupAppbar> createState() => _StockLookupAppbarState();
}

class _StockLookupAppbarState extends State<StockLookupAppbar> {
  // Future<void> clearAllImageCache() async {
  //   final dir = await getTemporaryDirectory();

  //   final thumbRoot = Directory(p.join(dir.path, "thumb_cache"));
  //   final fullRoot = Directory(p.join(dir.path, "fullimg_cache"));

  //   if (await thumbRoot.exists()) {
  //     await thumbRoot.delete(recursive: true);
  //   }
  //   if (await fullRoot.exists()) {
  //     await fullRoot.delete(recursive: true);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: Icon + Texts
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 15),
              SizedBox(
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(25)),
                    child: Image.asset(
                      "assets/images/appicon.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Responsive Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Stock List", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                          .split('\\')
                          .last,
                      style: getSmartTitle(color: kPrimaryColor, fontSize: 16),
                      maxLines: 1, // Prevent vertical overflow
                      overflow:
                          TextOverflow.ellipsis, // Handle long names gracefully
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Side: Buttons
        Row(
          children: [
            const SizedBox(width: 10), // Padding between text and buttons
            Material(
              color: kSecondaryColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  context.navigateBack();
                },
                child: Container(
                  height: 45,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.home_filled,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            BlocBuilder<FetchStockBloc, FetchStockStates>(
              builder: (context, state) {
                if (state is FetchStockProgress) {
                  return Material(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 45,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.sync,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  );
                } else {
                  return Material(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        context.read<FetchStockBloc>().add(
                          StartSyncEvent(
                            ipAddress: AppGlobals.instance.currentHostIp ?? "",
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 45,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.sync,
                          color: Colors.blueGrey[800],
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 15),
          ],
        ),
      ],
    );
  }
}
