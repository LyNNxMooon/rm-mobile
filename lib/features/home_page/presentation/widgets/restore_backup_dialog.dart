import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/backup_session_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({super.key});

  String _fmt(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/"
      "${dt.month.toString().padLeft(2, '0')}/"
      "${dt.year} "
      "${dt.hour.toString().padLeft(2, '0')}:"
      "${dt.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore_page_outlined,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text(
                      "Restore Session",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kThirdColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            Flexible(
              child: BlocConsumer<BackupRestoreBloc, BackupRestoreState>(
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
                      backgroundColor: kSecondaryColor,
                      iconColor: kPrimaryColor,
                      textColor: kThirdColor,
                      position: MessagePosition.top,
                      padding: 70,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is BackupRestoreLoading ||
                      state is BackupRestoreRestoring) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoActivityIndicator(radius: 15),
                            SizedBox(height: 15),
                            Text(
                              "Processing...",
                              style: TextStyle(color: kGreyColor),
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
                              style: const TextStyle(
                                color: kGreyColor,
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
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            "No backup sessions found.",
                            style: TextStyle(color: kGreyColor, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    String currentShopfront =
                        (AppGlobals.instance.shopfront ?? "").split(r'\').last;

           
                    final filteredSessions = state.sessions.where((session) {
                      return session.fileName.contains(
                        "_backup_${currentShopfront}_",
                      );
                    }).toList();
                    if (filteredSessions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            "No backups found for this shopfront.",
                            style: TextStyle(color: kGreyColor, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(15),
                      shrinkWrap: true,
                      itemCount: filteredSessions.length, // Use filtered count
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        // Pass the filtered session to the builder
                        return _buildBackupItem(context, filteredSessions[i]);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // --- Footer ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: kGreyColor.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: kGreyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(BuildContext context, BackupSessionVO session) {
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
          color: kSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: kThirdColor.withOpacity(0.05),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // File Name - Fully Visible
                  Text(
                    session.fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kGreyColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
