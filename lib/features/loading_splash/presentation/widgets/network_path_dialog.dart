import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_events.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';

class NetworkPathDialog extends StatelessWidget {
  const NetworkPathDialog({super.key, required this.paths});

  final List<Map<String, dynamic>> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.length == 1) {
      context.read<NetworkSavedPathValidationBloc>().add(
        ConnectionCheckingEvent(paths[0]['path']),
      );
      context.navigateBack();
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: kGColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_copy_rounded, color: kSecondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Saved Locations",
                      style: getSmartTitle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: paths.length,
                separatorBuilder: (ctx, i) => Divider(
                  color: kGreyColor.withOpacity(0.2),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final pathData = paths[index];
                  final String path = pathData['path'];
                  final String hostName = pathData['host_name'];

                  final regex = RegExp(r'//(\d{1,3}(?:\.\d{1,3}){3})');

                  String output = path.replaceFirstMapped(regex, (match) {
                    return '//$hostName';
                  });

                  return _buildSlidableTile(output, path, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidableTile(
    String displayPath,
    String realPath,
    BuildContext ctx,
  ) {
    return Slidable(
      key: ValueKey(realPath),

      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (paths.length != 1) {
                 LocalDbDAO.instance.deleteNetworkPath(realPath);
                 context.read<NetworkSavedPathValidationBloc>().add(FetchSavedPathsEvent());
                 context.navigateBack();
              }
            },
            backgroundColor: kErrorColor,
            foregroundColor: kSecondaryColor,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),

      child: InkWell(
        onTap: () {
          ctx.read<NetworkSavedPathValidationBloc>().add(
            ConnectionCheckingEvent(realPath),
          );
          ctx.navigateBack();
        },
        splashColor: kPrimaryColor.withOpacity(0.1),
        highlightColor: kPrimaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_shared_rounded,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kThirdColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: kGreyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
