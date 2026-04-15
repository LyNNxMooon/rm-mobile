import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rmmobile/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmmobile/features/loading_splash/presentation/BLoC/loading_splash_events.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/modern_dialog_styles.dart';
import '../../../../utils/dialog_size_utils.dart';

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
      insetPadding: dialogInsetPadding(context),
      shape: ModernDialogStyles.dialogShape,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ModernDialogContainer(
        maxHeight: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModernDialogHeader(
              title: "Saved Locations",
              icon: Icons.folder_copy_rounded,
              subtitle: "Select a saved network path",
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: paths.length,
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
    final isDark = colors.isDark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Slidable(
        key: ValueKey(realPath),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (context) {
                if (paths.length != 1) {
                  ctx
                      .read<NetworkSavedPathValidationBloc>()
                      .add(DeleteSavedPathEvent(realPath));
                  context.navigateBack();
                }
              },
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: kErrorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: kErrorColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              ctx.read<NetworkSavedPathValidationBloc>().add(
                ConnectionCheckingEvent(realPath),
              );
              ctx.navigateBack();
            },
            borderRadius: BorderRadius.circular(14),
            splashColor: kPrimaryColor.withOpacity(0.08),
            highlightColor: kPrimaryColor.withOpacity(0.04),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : colors.surfaceAlt.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : colors.divider.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kPrimaryColor.withOpacity(isDark ? 0.25 : 0.15),
                          kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_shared_rounded,
                      color: kPrimaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      displayPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: kPrimaryColor,
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
