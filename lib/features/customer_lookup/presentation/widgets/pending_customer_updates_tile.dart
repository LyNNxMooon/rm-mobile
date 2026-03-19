import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_creation_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_update_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_create_screen.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_details_screen.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_thumbnail_tile.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/dialog_size_utils.dart';

class PendingCustomerUpdatesTile extends StatefulWidget {
  const PendingCustomerUpdatesTile({super.key});

  @override
  State<PendingCustomerUpdatesTile> createState() =>
      _PendingCustomerUpdatesTileState();
}

class _PendingCustomerUpdatesTileState extends State<PendingCustomerUpdatesTile> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PendingCustomerUpdatesBloc, PendingCustomerUpdatesState>(
      listener: (context, state) async {
        if (state is PendingCustomerUpdatesCountLoaded) {
          setState(() {
            _count = state.count + state.creationsCount;
          });
        }
        if (state is PendingCustomerUpdatesLoaded) {
          setState(() {
            _count = state.updates.length + state.creations.length;
          });
          if (state.showDialog) {
            await _showPendingDialog(
              context,
              state.updates,
              state.creations,
            );
          }
        }
      },
      builder: (context, state) {
        if (state is PendingCustomerUpdatesLoading) {
          return _buildLoadingTile();
        }
        if (_count <= 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: InkWell(
            onTap: () {
              context.read<PendingCustomerUpdatesBloc>().add(
                LoadPendingCustomerUpdatesEvent(),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(top: 5, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade800.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_problem, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$_count pending customer item(s) not sent",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.orange.shade800, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPendingDialog(
    BuildContext context,
    List<PendingCustomerUpdateVO> updates,
    List<PendingCustomerCreationVO> creations,
  ) async {
    await showPendingCustomerQueueDialog(
      context: context,
      updates: updates,
      creations: creations,
      showSendButton: false,
    );

    if (!context.mounted) return;
    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  Widget _buildLoadingTile() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        margin: const EdgeInsets.only(top: 5, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CupertinoActivityIndicator(
                color: kPrimaryColor,
                radius: 10,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Processing pending customer updates...",
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCustomerEntry {
  final PendingCustomerUpdateVO update;
  final CustomerVO? customer;

  const _PendingCustomerEntry({required this.update, required this.customer});
}

class _PendingCustomerQueueEntry {
  final PendingCustomerUpdateVO? update;
  final PendingCustomerCreationVO? creation;
  final CustomerVO? customer;
  final DateTime createdAt;

  const _PendingCustomerQueueEntry({
    required this.update,
    required this.creation,
    required this.customer,
    required this.createdAt,
  });

  bool get isCreation => creation != null;
}

Map<String, dynamic> _firstCustomerPayloadItem(Map<String, dynamic> payload) {
  final items = payload['items'];
  if (items is List && items.isNotEmpty) {
    final raw = items.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

String _payloadString(Map<String, dynamic> item, String key) {
  final value = item[key];
  return value is String ? value.trim() : '';
}

String _pendingCustomerName(PendingCustomerUpdateVO update) {
  final item = _firstCustomerPayloadItem(update.payload);
  final given = _payloadString(item, 'givenNames').isNotEmpty
      ? _payloadString(item, 'givenNames')
      : _payloadString(item, 'given_names');
  final surname = _payloadString(item, 'surname');
  final company = _payloadString(item, 'company');
  final baseName = [given, surname].where((s) => s.isNotEmpty).join(' ');
  final name = baseName.isNotEmpty
      ? baseName
      : (update.customerId > 0 ? 'Customer #${update.customerId}' : 'New customer');
  return company.isNotEmpty ? '$name ($company)' : name;
}

String _pendingCustomerBarcode(PendingCustomerUpdateVO update) {
  final item = _firstCustomerPayloadItem(update.payload);
  final barcode = _payloadString(item, 'barcode');
  return barcode.isNotEmpty ? barcode : 'Pending update';
}

CustomerVO? _customerFromPendingUpdate(PendingCustomerUpdateVO update) {
  final item = _firstCustomerPayloadItem(update.payload);
  if (item.isEmpty) return null;
  return CustomerVO.fromApiItem(item);
}

String _initialsFromName(String name) {
  final parts = name.split(' ').where((part) => part.trim().isNotEmpty).toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
      .toUpperCase();
}

class _PendingCustomerTile extends StatelessWidget {
  final PendingCustomerUpdateVO update;
  final CustomerVO? customer;
  final VoidCallback? onTap;
  final String? statusLabel;
  final Color? statusColor;

  const _PendingCustomerTile({
    required this.update,
    required this.customer,
    required this.onTap,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;

    final String title =
        customer?.displayName ?? _pendingCustomerName(update);
    final String barcode =
        customer?.barcode ?? _pendingCustomerBarcode(update);
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
            ),
            child: ClipOval(
              child: customer == null
                  ? Container(
                      color: kPrimaryColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Text(
                        _initialsFromName(title),
                        style: TextStyle(
                          color: kPrimaryColor.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : CustomerThumbnailTile(
                      customer: customer!,
                      size: thumbnailSize,
                    ),
            ),
          ),
          SizedBox(width: (isTablet ? 17 : 15) * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (update.errorMessage != null &&
                    update.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      update.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (statusLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (statusColor ?? kPrimaryColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (statusColor ?? kPrimaryColor).withOpacity(0.6),
                ),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor ?? kPrimaryColor,
                ),
              ),
            ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: 20),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );
  }
}

DateTime _pendingDateTime(String value) {
  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

Future<void> showPendingCustomerQueueDialog({
  required BuildContext context,
  required List<PendingCustomerUpdateVO> updates,
  required List<PendingCustomerCreationVO> creations,
  required bool showSendButton,
  String? warningMessage,
  Future<void> Function()? onSend,
}) async {
  if (updates.isEmpty && creations.isEmpty) return;
  final entries = <_PendingCustomerQueueEntry>[];
  for (final update in updates) {
    final customer = _customerFromPendingUpdate(update);
    entries.add(
      _PendingCustomerQueueEntry(
        update: update,
        creation: null,
        customer: customer,
        createdAt: _pendingDateTime(update.createdAt),
      ),
    );
  }
  for (final creation in creations) {
    entries.add(
      _PendingCustomerQueueEntry(
        update: null,
        creation: creation,
        customer: null,
        createdAt: _pendingDateTime(creation.createdAt),
      ),
    );
  }
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final dialogEntries = List<_PendingCustomerQueueEntry>.from(entries);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.appColors;
          final bool isDark = colors.isDark;
          return Dialog(
            insetPadding: dialogInsetPadding(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side:
                  isDark ? const BorderSide(color: Colors.white30) : BorderSide.none,
            ),
            backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync_problem,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pending Customer Items",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(Icons.close, color: colors.onSurface),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${dialogEntries.length} item(s) are queued and not sent yet.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  if (warningMessage != null && warningMessage.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        warningMessage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: kErrorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 380),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white24 : colors.divider,
                      ),
                    ),
                    child: dialogEntries.isEmpty
                        ? Text(
                            "No pending customer items found.",
                            style: TextStyle(color: colors.onSurfaceMuted),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: dialogEntries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = dialogEntries[index];
                              final bool isCreation = entry.isCreation;
                              return Dismissible(
                                key: ValueKey(
                                  isCreation
                                      ? 'pending_customer_create_${entry.creation!.id}'
                                      : 'pending_customer_${entry.update!.id}',
                                ),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  if (isCreation) {
                                    dialogContext
                                        .read<PendingCustomerUpdatesBloc>()
                                        .add(
                                          DeletePendingCustomerCreationEvent(
                                            id: entry.creation!.id,
                                          ),
                                        );
                                  } else {
                                    dialogContext
                                        .read<PendingCustomerUpdatesBloc>()
                                        .add(
                                          DeletePendingCustomerUpdateEvent(
                                            id: entry.update!.id,
                                          ),
                                        );
                                  }
                                  setDialogState(() {
                                    dialogEntries.removeWhere(
                                      (item) => isCreation
                                          ? item.creation?.id == entry.creation!.id
                                          : item.update?.id == entry.update!.id,
                                    );
                                  });
                                  if (!dialogContext.mounted) return;
                                  if (dialogEntries.isEmpty) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: isCreation
                                    ? _PendingCustomerCreationTile(
                                        creation: entry.creation!,
                                        statusLabel: 'CREATE',
                                        statusColor: Colors.green.shade700,
                                        onTap: () async {
                                          Navigator.of(dialogContext).pop();
                                          await context.navigateToNext(
                                            CustomerCreateScreen(
                                              pendingCreation: entry.creation,
                                            ),
                                          );
                                        },
                                      )
                                    : _PendingCustomerTile(
                                        update: entry.update!,
                                        customer: entry.customer,
                                        statusLabel: 'UPDATE',
                                        statusColor: Colors.orange.shade700,
                                        onTap: () async {
                                          Navigator.of(dialogContext).pop();
                                          if (entry.customer != null) {
                                            await context.navigateToNext(
                                              CustomerDetailsScreen(
                                                customer: entry.customer!,
                                              ),
                                            );
                                          }
                                          if (!context.mounted) return;
                                          context
                                              .read<PendingCustomerUpdatesBloc>()
                                              .add(
                                                LoadPendingCustomerUpdatesCountEvent(),
                                              );
                                        },
                                      ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: dialogEntries.isEmpty
                              ? null
                              : () async {
                                  final updateIds = dialogEntries
                                      .where((entry) => entry.update != null)
                                      .map((entry) => entry.update!.id)
                                      .toList();
                                  final creationIds = dialogEntries
                                      .where((entry) => entry.creation != null)
                                      .map((entry) => entry.creation!.id)
                                      .toList();
                                  dialogContext
                                      .read<PendingCustomerUpdatesBloc>()
                                      .add(
                                        DeleteAllPendingCustomerItemsEvent(
                                          updateIds: updateIds,
                                          creationIds: creationIds,
                                        ),
                                      );
                                  if (!dialogContext.mounted) return;
                                  Navigator.of(dialogContext).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kErrorColor.withOpacity(0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Delete All",
                            style: TextStyle(color: kErrorColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: showSendButton
                            ? ElevatedButton(
                                onPressed: dialogEntries.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.of(dialogContext).pop();
                                        if (onSend != null) {
                                          await onSend();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: colors.onHero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Send"),
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: kPrimaryColor.withOpacity(0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Close",
                                  style: TextStyle(color: kPrimaryColor),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (!context.mounted) return;
  context.read<PendingCustomerUpdatesBloc>().add(
    LoadPendingCustomerUpdatesCountEvent(),
  );
}

class _PendingCustomerCreationEntry {
  final PendingCustomerCreationVO creation;

  const _PendingCustomerCreationEntry({required this.creation});
}

String _pendingCustomerCreationName(PendingCustomerCreationVO creation) {
  final item = _firstCustomerPayloadItem(creation.payload);
  final given = _payloadString(item, 'givenNames').isNotEmpty
      ? _payloadString(item, 'givenNames')
      : _payloadString(item, 'given_names');
  final surname = _payloadString(item, 'surname');
  final company = _payloadString(item, 'company');
  final baseName = [given, surname].where((s) => s.isNotEmpty).join(' ');
  final name = baseName.isNotEmpty
      ? baseName
      : (creation.customerId > 0
          ? 'Customer #${creation.customerId}'
          : 'New customer');
  return company.isNotEmpty ? '$name ($company)' : name;
}

String _pendingCustomerCreationBarcode(PendingCustomerCreationVO creation) {
  final item = _firstCustomerPayloadItem(creation.payload);
  final barcode = _payloadString(item, 'barcode');
  if (barcode.isEmpty) return 'Pending create';
  return barcode;
}

class _PendingCustomerCreationTile extends StatelessWidget {
  final PendingCustomerCreationVO creation;
  final VoidCallback? onTap;
  final String? statusLabel;
  final Color? statusColor;

  const _PendingCustomerCreationTile({
    required this.creation,
    required this.onTap,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;

    final String title = _pendingCustomerCreationName(creation);
    final String barcode = _pendingCustomerCreationBarcode(creation);
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
            ),
            child: ClipOval(
              child: Container(
                color: kPrimaryColor.withOpacity(0.1),
                alignment: Alignment.center,
                child: Text(
                  _initialsFromName(title),
                  style: TextStyle(
                    color: kPrimaryColor.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: (isTablet ? 17 : 15) * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (creation.errorMessage != null &&
                    creation.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      creation.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (statusLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (statusColor ?? kPrimaryColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (statusColor ?? kPrimaryColor).withOpacity(0.6),
                ),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor ?? kPrimaryColor,
                ),
              ),
            ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: 20),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );
  }
}