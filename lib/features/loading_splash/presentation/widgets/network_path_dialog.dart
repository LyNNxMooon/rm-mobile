import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_events.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/dialog_size_utils.dart';

class NetworkPathDialog extends StatelessWidget {
  const NetworkPathDialog({super.key, required this.paths});

  final List<Map<String, dynamic>> paths;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (paths.length == 1) {
      context.read<NetworkSavedPathValidationBloc>().add(
        ConnectionCheckingEvent(paths[0]['path']),
      );
      context.navigateBack();
    }

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: colors.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_copy_rounded, color: colors.onHero),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Saved Locations",
                      style: getSmartTitle(fontSize: 16, color: colors.onHero),
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
                  color: colors.divider,
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
    final colors = ctx.appColors;
    return Slidable(
      key: ValueKey(realPath),

      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (paths.length != 1) {
                 ctx
                     .read<NetworkSavedPathValidationBloc>()
                     .add(DeleteSavedPathEvent(realPath));
                 context.navigateBack();
              }
            },
            backgroundColor: kErrorColor,
            foregroundColor: colors.onHero,
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
                    color: colors.onSurface,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
