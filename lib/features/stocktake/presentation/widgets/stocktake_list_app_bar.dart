import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/widgets/delete_all_confirmation_dialog.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../BLoC/stocktake_events.dart';

class StocktakeListAppBar extends StatefulWidget {
  const StocktakeListAppBar({super.key});

  @override
  State<StocktakeListAppBar> createState() => _StocktakeListAppBarState();
}

class _StocktakeListAppBarState extends State<StocktakeListAppBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                //const SizedBox(width: 15),
                IconButton(
                  onPressed: () => context.navigateBack(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: kPrimaryColor,
                    size: 15,
                  ),
                ),
                //const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                                  .split('\\')
                                  .last
                                  .length >
                              18
                          ? "${(AppGlobals.instance.shopfront ?? "RM-Shopfront").split('\\').last.substring(0, 18)}.."
                          : (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                                .split('\\')
                                .last,
                      style: getSmartTitle(color: kThirdColor, fontSize: 16),
                    ),
                    Text(
                      "Stocktake List",
                      // style: getSmartTitle(color: kThirdColor, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => StocktakeDeleteConfirmationDialog(
                          onConfirm: () {
                            LocalDbDAO.instance.deleteAllStocktake();
                            context.read<FetchingStocktakeListBloc>().add(
                              FetchStocktakeListEvent(),
                            );
                          },
                        ),
                      );
                    },
                    icon: Icon(
                      CupertinoIcons.delete_solid,
                      size: 18,
                      color: kErrorColor,
                    ),
                  ),
                ),
                //const SizedBox(width: 3),
                Text(
                  "1-50 of 4,795",
                  style: TextStyle(color: kPrimaryColor, fontSize: 12),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_back_ios_new, size: 12, color: kPrimaryColor),
                const SizedBox(width: 15),
                Icon(Icons.arrow_forward_ios, size: 12, color: kPrimaryColor),

                const SizedBox(width: 15),
              ],
            ),
          ],
        ),
        const Divider(
          indent: 15,
          endIndent: 15,
          thickness: 0.3,
          color: Colors.grey,
          height: 20,
        ),
      ],
    );
  }
}
