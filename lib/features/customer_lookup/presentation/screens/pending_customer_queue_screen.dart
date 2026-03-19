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
import '../../../../constants/txt_styles.dart';

class PendingCustomerQueueScreen extends StatefulWidget {
  final bool showSendButton;

  const PendingCustomerQueueScreen({
    super.key,
    required this.showSendButton,
  });

  @override
  State<PendingCustomerQueueScreen> createState() =>
      _PendingCustomerQueueScreenState();
}

class _PendingCustomerQueueScreenState
    extends State<PendingCustomerQueueScreen> {
  List<PendingCustomerUpdateVO> _updates = const [];
  List<PendingCustomerCreationVO> _creations = const [];

  @override
  void initState() {
    super.initState();
    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesEvent(showDialog: false),
    );
  }

  Future<void> _sendPendingUpdates(
    PendingCustomerUpdatesBloc pendingBloc,
    FetchCustomerBloc fetchBloc,
    ScaffoldMessengerState messenger, {
    bool triggerSync = true,
  }) async {
    pendingBloc.add(SendPendingCustomerUpdatesEvent());

    final result = await pendingBloc.stream.firstWhere(
      (state) =>
          state is PendingCustomerUpdatesSent ||
          state is PendingCustomerUpdatesError,
    );

    if (result is PendingCustomerUpdatesSent) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (triggerSync) {
        fetchBloc.add(StartCustomerSyncEvent(ipAddress: ""));
      }
    } else if (result is PendingCustomerUpdatesError) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _sendPendingCreations(
    PendingCustomerUpdatesBloc pendingBloc,
    FetchCustomerBloc fetchBloc,
    ScaffoldMessengerState messenger, {
    bool triggerSync = true,
  }) async {
    pendingBloc.add(SendPendingCustomerCreationsEvent());

    final result = await pendingBloc.stream.firstWhere(
      (state) =>
          state is PendingCustomerCreationsSent ||
          state is PendingCustomerCreationsError,
    );

    if (result is PendingCustomerCreationsSent) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (triggerSync) {
        fetchBloc.add(StartCustomerSyncEvent(ipAddress: ""));
      }
    } else if (result is PendingCustomerCreationsError) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _sendPendingAll(
    PendingCustomerUpdatesBloc pendingBloc,
    FetchCustomerBloc fetchBloc,
    ScaffoldMessengerState messenger,
  ) async {
    await _sendPendingUpdates(
      pendingBloc,
      fetchBloc,
      messenger,
      triggerSync: false,
    );
    await _sendPendingCreations(
      pendingBloc,
      fetchBloc,
      messenger,
      triggerSync: false,
    );
    fetchBloc.add(StartCustomerSyncEvent(ipAddress: ""));
    pendingBloc.add(
      LoadPendingCustomerUpdatesEvent(showDialog: false),
    );
    pendingBloc.add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Text(
          'Pending Customer Items',
          style: getSmartTitle(
            color: isDark ? Colors.white : colors.onSurface,
            fontSize: 16,
          ),
        ),
        backgroundColor: isDark ? colors.bg : kBgColor,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<PendingCustomerUpdatesBloc,
            PendingCustomerUpdatesState>(
          listener: (context, state) {
            if (state is PendingCustomerUpdatesLoaded) {
              setState(() {
                _updates = state.updates;
                _creations = state.creations;
              });
            }
          },
          builder: (context, state) {
            if (state is PendingCustomerUpdatesLoading &&
                _updates.isEmpty &&
                _creations.isEmpty) {
              return _buildLoadingTile(context);
            }

            final entries = _buildEntries(_updates, _creations);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${entries.length} item(s) are queued and not sent yet.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            "No pending customer items found.",
                            style: TextStyle(color: colors.onSurfaceMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
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
                              onDismissed: (direction) {
                                if (isCreation) {
                                  context
                                      .read<PendingCustomerUpdatesBloc>()
                                      .add(
                                        DeletePendingCustomerCreationEvent(
                                          id: entry.creation!.id,
                                        ),
                                      );
                                  setState(() {
                                    _creations = _creations
                                        .where(
                                          (item) =>
                                              item.id != entry.creation!.id,
                                        )
                                        .toList();
                                  });
                                } else {
                                  context
                                      .read<PendingCustomerUpdatesBloc>()
                                      .add(
                                        DeletePendingCustomerUpdateEvent(
                                          id: entry.update!.id,
                                        ),
                                      );
                                  setState(() {
                                    _updates = _updates
                                        .where(
                                          (item) => item.id != entry.update!.id,
                                        )
                                        .toList();
                                  });
                                }
                              },
                              child: isCreation
                                  ? _PendingCustomerCreationTile(
                                      creation: entry.creation!,
                                      statusLabel: 'CREATE',
                                      statusColor: Colors.green.shade700,
                                      onTap: () async {
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: entries.isEmpty
                              ? null
                              : () {
                                  final updateIds = entries
                                      .where((entry) => entry.update != null)
                                      .map((entry) => entry.update!.id)
                                      .toList();
                                  final creationIds = entries
                                      .where((entry) => entry.creation != null)
                                      .map((entry) => entry.creation!.id)
                                      .toList();
                                  context
                                      .read<PendingCustomerUpdatesBloc>()
                                      .add(
                                        DeleteAllPendingCustomerItemsEvent(
                                          updateIds: updateIds,
                                          creationIds: creationIds,
                                        ),
                                      );
                                  Navigator.of(context).pop();
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
                        child: widget.showSendButton
                            ? ElevatedButton(
                                onPressed: entries.isEmpty
                                    ? null
                                    : () async {
                                    final pendingBloc = context
                                      .read<PendingCustomerUpdatesBloc>();
                                    final fetchBloc =
                                      context.read<FetchCustomerBloc>();
                                    final messenger =
                                      ScaffoldMessenger.of(context);
                                Navigator.of(context).pop();
                                    await _sendPendingAll(
                                      pendingBloc,
                                      fetchBloc,
                                      messenger,
                                    );
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
                                onPressed: () => Navigator.of(context).pop(),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingTile(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
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

List<_PendingCustomerQueueEntry> _buildEntries(
  List<PendingCustomerUpdateVO> updates,
  List<PendingCustomerCreationVO> creations,
) {
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
  return entries;
}

DateTime _pendingDateTime(String value) {
  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
      : (update.customerId > 0
          ? 'Customer #${update.customerId}'
          : 'New customer');
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
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;

    final String title = customer?.displayName ?? _pendingCustomerName(update);
    final String barcode = customer?.barcode ?? _pendingCustomerBarcode(update);
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : colors.cardShadow,
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
    final bool isDark = colors.isDark;
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
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : colors.cardShadow,
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
