import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/txt_styles.dart';
import 'package:rmstock_scanner/entities/vos/stocktake_history_session_row.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stocktake_history_detail_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

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
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // simple top bar (same vibe as your screens)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.navigateBack(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Stocktake History",
                    style: getSmartTitle(color: kThirdColor, fontSize: 16),
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
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
    
                  if (state is StocktakeHistorySessionsLoaded) {
                    if (state.sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Decorative Ring
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kPrimaryColor.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                ),
    
                                // Inner Filled Circle
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kPrimaryColor.withOpacity(0.1),
                                  ),
                                  child: Center(
                                    // Using an "Open Box" icon usually signifies "Empty" better than a rocket
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Image.asset(
                                        "assets/images/box.png",
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
    
                            const SizedBox(height: 24),
    
                            Text(
                              "No stocktake history found!",
                              style: const TextStyle(
                                color: kGreyColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
    
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                context.read<StocktakeHistoryBloc>().add(
                                  LoadHistorySessionsEvent(),
                                );
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text("Refresh List"),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 55),
                          ],
                        ),
                      );
                    }
    
                    return AnimationLimiter(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                        separatorBuilder: (_, _) => const SizedBox(height: 7),
                        itemCount: state.sessions.length,
                        itemBuilder: (_, i) =>
                            _sessionTile(state.sessions[i], i),
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

  Widget _sessionTile(StocktakeHistorySessionRow s, int index) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: kPrimaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sent ${s.totalStocks} item(s)",
                          style: getSmartTitle(
                            color: kThirdColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fmt(s.createdAt),
                          style: const TextStyle(
                            color: kGreyColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: kGreyColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
