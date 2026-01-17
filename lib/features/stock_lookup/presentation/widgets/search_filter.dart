import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_states.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';

class SearchFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchFilterBar({super.key, this.onChanged, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: "Search by Barcode, Desc, Cat1...",
                  hintStyle: TextStyle(
                    color: kGreyColor.withOpacity(0.8),
                    fontSize: 13,
                  ),

                  suffixIcon: InkWell(
                    onTap: () {
                      logger.d("Scan Icon Tapped");
                    },
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  filled: true,
                  fillColor: kSecondaryColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue[700]!,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          Material(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Icon(Icons.tune, color: Colors.blueGrey[800], size: 24),
              ),
            ),
          ),

          const SizedBox(width: 5),

          BlocBuilder<FetchStockBloc, FetchStockStates>(
            builder: (context, state) {
              if (state is FetchStockProgress) {
                return Material(
                  color: kSecondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    width: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Icon(Icons.sync, color: Colors.grey, size: 24),
                  ),
                );
              } else {
                return Material(
                  color: kSecondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      context.read<ShopFrontConnectionBloc>().add(
                        ConnectToShopfrontEvent(
                          ip: AppGlobals.instance.currentHostIp ?? "",
                          shopName: AppGlobals.instance.shopfront ?? "",
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      width: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
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
        ],
      ),
    );
  }
}
