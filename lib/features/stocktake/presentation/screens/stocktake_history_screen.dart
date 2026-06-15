import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/constants/txt_styles.dart';
import 'package:rmmobile/entities/vos/stocktake_history_session_row.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stocktake_history_detail_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

class StocktakeHistoryScreen extends StatefulWidget {
  const StocktakeHistoryScreen({super.key});

  @override
  State<StocktakeHistoryScreen> createState() => _StocktakeHistoryScreenState();
}

class _StocktakeHistoryScreenState extends State<StocktakeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StocktakeHistoryBloc>().add(LoadHistorySessionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;

    // Desktop sizing
    final double titleFontSize = useDesktopNav ? 14.0 : 16.0;
    final double backIconSize = useDesktopNav ? 16.0 : 18.0;
    final double topPadding = useDesktopNav ? 12.0 : 15.0;
    final double listPadding = useDesktopNav ? 12.0 : 15.0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // simple top bar (same vibe as your screens)
            Padding(
              padding: EdgeInsets.fromLTRB(topPadding, topPadding, topPadding, useDesktopNav ? 8 : 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.navigateBack(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? Colors.white : kPrimaryColor,
                      size: backIconSize,
                    ),
                  ),
                  SizedBox(width: useDesktopNav ? 8 : 12),
                  Text(
                    "Stocktake History",
                    style: getSmartTitle(
                      color: isDark ? Colors.white : colors.onSurface,
                      fontSize: titleFontSize,
                    ),
                  ),
                ],
              ),
            ),
    
            Expanded(
              child: BlocBuilder<StocktakeHistoryBloc, StocktakeHistoryState>(
                builder: (context, state) {
                  if (state is StocktakeHistoryLoading) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
    
                  if (state is StocktakeHistoryError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: getSmartTitle(
                          color: kErrorColor,
                          fontSize: useDesktopNav ? 12 : 14,
                        ),
                      ),
                    );
                  }
    
                  if (state is StocktakeHistorySessionsLoaded) {
                    if (state.sessions.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer Decorative Ring
                                        Container(
                                          width: useDesktopNav ? 120 : 160,
                                          height: useDesktopNav ? 120 : 160,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: kPrimaryColor.withOpacity(0.2),
                                              width: 2,
                                            ),
                                          ),
                                        ),

                                        // Inner Circle (no fill, holds the image)
                                        Container(
                                          width: useDesktopNav ? 100 : 130,
                                          height: useDesktopNav ? 100 : 130,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            // Using an "Open Box" icon usually signifies "Empty" better than a rocket
                                            child: SizedBox(
                                              width: useDesktopNav ? 95 : 120,
                                              height: useDesktopNav ? 95 : 120,
                                              child: Image.asset(
                                                "assets/images/empty.png",
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: useDesktopNav ? 18 : 24),

                                    Text(
                                      "No stocktake history found.",
                                      style: TextStyle(
                                        color: colors.onSurfaceMuted,
                                        fontSize: useDesktopNav ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    SizedBox(height: useDesktopNav ? 12 : 16),
                                    TextButton.icon(
                                      onPressed: () {
                                        context.read<StocktakeHistoryBloc>().add(
                                          LoadHistorySessionsEvent(),
                                        );
                                      },
                                      icon: Icon(Icons.refresh, size: useDesktopNav ? 16 : 18),
                                      label: Text("Refresh List", style: TextStyle(fontSize: useDesktopNav ? 12 : 14)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: kPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 55),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
    
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
                        child: AnimationLimiter(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(listPadding, 5, listPadding, listPadding),
                            separatorBuilder: (_, _) => _buildFadedDivider(),
                            itemCount: state.sessions.length,
                            itemBuilder: (_, i) =>
                                _sessionTile(state.sessions[i], i, useDesktopNav),
                          ),
                        ),
                      ),
                    );
                  }
    
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionTile(StocktakeHistorySessionRow s, int index, bool useDesktopNav) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    // Desktop sizing
    final double tilePaddingH = useDesktopNav ? 12.0 : 16.0;
    final double tilePaddingV = useDesktopNav ? 10.0 : 12.0;
    final double iconContainerSize = useDesktopNav ? 32.0 : 38.0;
    final double iconSize = useDesktopNav ? 20.0 : 24.0;
    final double titleFontSize = useDesktopNav ? 12.0 : 14.0;
    final double dateFontSize = useDesktopNav ? 10.0 : 11.0;
    final double borderRadius = useDesktopNav ? 8.0 : 10.0;

    String fmt(DateTime dt) =>
        "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: InkWell(
            onTap: () {
              context.navigateToNext(StocktakeHistoryDetailsScreen(session: s));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: tilePaddingH, vertical: tilePaddingV),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    child: Icon(Icons.history, color: kPrimaryColor, size: iconSize),
                  ),
                  SizedBox(width: useDesktopNav ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sent ${s.totalStocks} item(s)",
                          style: getSmartTitle(
                            color: isDark ? Colors.white : colors.onSurface,
                            fontSize: titleFontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: useDesktopNav ? 2 : 3),
                        Text(
                          fmt(s.createdAt),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                            fontSize: dateFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white54 : colors.onSurfaceMuted,
                    size: useDesktopNav ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFadedDivider() {
    final bool isDark = context.appColors.isDark;
    final Color lineColor = isDark ? Colors.white : Colors.black;
    final double opacity = isDark ? 0.2 : 0.25;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            lineColor.withOpacity(opacity),
            lineColor.withOpacity(opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}
