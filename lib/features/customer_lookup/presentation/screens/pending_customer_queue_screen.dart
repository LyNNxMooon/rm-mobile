import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
import 'package:rmmobile/entities/vos/pending_customer_creation_vo.dart';
import 'package:rmmobile/entities/vos/pending_customer_update_vo.dart';
import 'package:rmmobile/entities/vos/pending_customer_payload_utils.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmmobile/features/customer_lookup/presentation/screens/customer_create_screen.dart';
import 'package:rmmobile/features/customer_lookup/presentation/screens/customer_details_screen.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_thumbnail_tile.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';

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
    final bool useDesktopNav = context.useDesktopNav;
    final double titleFontSize = useDesktopNav ? 14 : 16;
    final double subtitleFontSize = useDesktopNav ? 11 : 12.5;
    final double horizontalPadding = useDesktopNav ? 14 : 18;
    final double itemSpacing = useDesktopNav ? 6 : 8;
    final double topSpacer = useDesktopNav ? 8 : 10;
    final double bottomButtonPadding = useDesktopNav ? 12 : 18;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: useDesktopNav ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Pending Customer Items',
          style: getSmartTitle(
            color: isDark ? Colors.white : colors.onSurface,
            fontSize: titleFontSize,
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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${entries.length} item(s) are queued and not sent yet.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: topSpacer),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            "No pending customer items found.",
                            style: TextStyle(color: colors.onSurfaceMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: itemSpacing,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: itemSpacing),
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
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, bottomButtonPadding),
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
    final bool useDesktopNav = context.useDesktopNav;
    final double horizontalPadding = useDesktopNav ? 14 : 18;
    final double tilePaddingV = useDesktopNav ? 8 : 10;
    final double tilePaddingH = useDesktopNav ? 10 : 12;
    final double fontSize = useDesktopNav ? 12 : 13;
    final double spinnerSize = useDesktopNav ? 16 : 18;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        margin: EdgeInsets.only(top: useDesktopNav ? 10 : 12, bottom: useDesktopNav ? 6 : 8),
        padding: EdgeInsets.symmetric(vertical: tilePaddingV, horizontal: tilePaddingH),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CupertinoActivityIndicator(
                color: kPrimaryColor,
                radius: useDesktopNav ? 8 : 10,
              ),
            ),
            SizedBox(width: useDesktopNav ? 8 : 10),
            Expanded(
              child: Text(
                "Processing pending customer updates...",
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: fontSize,
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
    final customer = customerFromPendingUpdate(update);
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
    final bool useDesktopNav = context.useDesktopNav;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = useDesktopNav ? 1.0 : isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = useDesktopNav ? 32 : (isTablet ? 44 : 36) * uiScale;
    final double tilePaddingH = useDesktopNav ? 10 : 12;
    final double tilePaddingV = useDesktopNav ? 8 : 10;
    final double titleFontSize = useDesktopNav ? 12 : 14;
    final double barcodeFontSize = useDesktopNav ? 11 : 13;
    final double errorFontSize = useDesktopNav ? 10.5 : 12;
    final double warningFontSize = useDesktopNav ? 10 : 11.5;
    final double statusFontSize = useDesktopNav ? 10 : 11.5;
    final double chevronSize = useDesktopNav ? 18 : 20;
    final double borderRadius = useDesktopNav ? 8 : 10;

    final String title = customer?.displayName ?? pendingCustomerName(update);
    final String barcode = customer?.barcode ?? pendingCustomerBarcode(update);
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
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
      padding: EdgeInsets.symmetric(horizontal: tilePaddingH, vertical: tilePaddingV),
      child: Row(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(useDesktopNav ? 5 : isTablet ? 8 : 6),
            ),
            child: ClipOval(
              child: customer == null
                  ? Container(
                      color: kPrimaryColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Text(
                        initialsFromName(title),
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
          SizedBox(width: useDesktopNav ? 10 : (isTablet ? 17 : 15) * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: useDesktopNav ? 2 : 3),
                Text(
                  barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: barcodeFontSize,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (update.hasConflict)
                  Padding(
                    padding: EdgeInsets.only(top: useDesktopNav ? 3 : 4),
                    child: Text(
                      "This record has been modified in RetailManager, please review and decide whether you still want to update it.",
                      style: TextStyle(
                        fontSize: warningFontSize,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (update.errorMessage != null &&
                    update.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: useDesktopNav ? 3 : 4),
                    child: Text(
                      update.errorMessage!,
                      style: TextStyle(
                        fontSize: errorFontSize,
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
              padding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 6 : 8, vertical: useDesktopNav ? 3 : 4),
              decoration: BoxDecoration(
                color: (statusColor ?? kPrimaryColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(useDesktopNav ? 10 : 12),
                border: Border.all(
                  color: (statusColor ?? kPrimaryColor).withOpacity(0.6),
                ),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: statusFontSize,
                  fontWeight: FontWeight.w700,
                  color: statusColor ?? kPrimaryColor,
                ),
              ),
            ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: chevronSize),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
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
    final bool useDesktopNav = context.useDesktopNav;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = useDesktopNav ? 1.0 : isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = useDesktopNav ? 32 : (isTablet ? 44 : 36) * uiScale;
    final double tilePaddingH = useDesktopNav ? 10 : 12;
    final double tilePaddingV = useDesktopNav ? 8 : 10;
    final double titleFontSize = useDesktopNav ? 12 : 14;
    final double barcodeFontSize = useDesktopNav ? 11 : 13;
    final double errorFontSize = useDesktopNav ? 10.5 : 12;
    final double statusFontSize = useDesktopNav ? 10 : 11.5;
    final double chevronSize = useDesktopNav ? 18 : 20;
    final double borderRadius = useDesktopNav ? 8 : 10;

    final String title = pendingCustomerCreationName(creation);
    final String barcode = pendingCustomerCreationBarcode(creation);
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : colors.surface,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
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
      padding: EdgeInsets.symmetric(horizontal: tilePaddingH, vertical: tilePaddingV),
      child: Row(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(useDesktopNav ? 5 : isTablet ? 8 : 6),
            ),
            child: ClipOval(
              child: Container(
                color: kPrimaryColor.withOpacity(0.1),
                alignment: Alignment.center,
                child: Text(
                  initialsFromName(title),
                  style: TextStyle(
                    color: kPrimaryColor.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: useDesktopNav ? 10 : (isTablet ? 17 : 15) * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: useDesktopNav ? 2 : 3),
                Text(
                  barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: barcodeFontSize,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (creation.errorMessage != null &&
                    creation.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: useDesktopNav ? 3 : 4),
                    child: Text(
                      creation.errorMessage!,
                      style: TextStyle(
                        fontSize: errorFontSize,
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
              padding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 6 : 8, vertical: useDesktopNav ? 3 : 4),
              decoration: BoxDecoration(
                color: (statusColor ?? kPrimaryColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(useDesktopNav ? 10 : 12),
                border: Border.all(
                  color: (statusColor ?? kPrimaryColor).withOpacity(0.6),
                ),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: statusFontSize,
                  fontWeight: FontWeight.w700,
                  color: statusColor ?? kPrimaryColor,
                ),
              ),
            ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: chevronSize),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: tile,
    );
  }
}
