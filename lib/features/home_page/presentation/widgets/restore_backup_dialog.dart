import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/standard_dialog.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/backup_session_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({super.key});

  String _fmt(DateTime dt) =>
      "${dt.toLocal().day.toString().padLeft(2, '0')}/"
      "${dt.toLocal().month.toString().padLeft(2, '0')}/"
      "${dt.toLocal().year} "
      "${dt.toLocal().hour.toString().padLeft(2, '0')}:"
      "${dt.toLocal().minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.6;

    return StandardDialog(
      title: "Restore Session",
      colors: colors,
      isDark: isDark,
      maxHeight: maxDialogHeight,
      content: BlocConsumer<BackupRestoreBloc, BackupRestoreState>(
                listener: (context, state) {
                  if (state is BackupRestoreDone) {
                    Navigator.pop(context);
                    context.read<FetchingStocktakeListBloc>().add(
                      FetchStocktakeListEvent(reset: true),
                    );

                    AlertInfo.show(
                      context: context,
                      text: "Your Backup is restored!",
                      typeInfo: TypeInfo.success,
                      backgroundColor: colors.surface,
                      iconColor: kPrimaryColor,
                      textColor: colors.onSurface,
                      position: MessagePosition.top,
                      padding: 70,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is BackupRestoreLoading ||
                      state is BackupRestoreRestoring) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(radius: 15),
                            const SizedBox(height: 15),
                            Text(
                              "Processing...",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : colors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is BackupRestoreError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: kErrorColor,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : colors.onSurfaceMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is BackupRestoreSessionsLoaded) {
                    if (state.sessions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            "No backup sessions found.",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : colors.onSurfaceMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    String currentShopfront =
                      (AppGlobals.instance.shopfront ?? "").split(r'\\').last;

                    final filteredSessions = state.sessions.where((session) {
                      return session.fileName.contains(
                        "_backup_${currentShopfront}_",
                      );
                    }).toList();
                    if (filteredSessions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            "No backups found for this shopfront.",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : colors.onSurfaceMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: false,
                      itemCount: filteredSessions.length, // Use filtered count
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        // Pass the filtered session to the builder
                        return _buildBackupItem(context, filteredSessions[i]);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
      actions: [
        DialogTextAction(
          label: "Cancel",
          style: DialogActionStyle.cancelOutline,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBackupItem(BuildContext context, BackupSessionVO session) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: () {
        context.read<BackupRestoreBloc>().add(
          RestoreBackupSessionEvent(session),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2F3B4B) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, size: 20, color: kPrimaryColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmt(session.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // File Name - Fully Visible
                  Text(
                    session.fileName,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
