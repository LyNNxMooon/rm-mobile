import 'package:alert_info/alert_info.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stock_take_list_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/enums.dart';
import '../BLoC/stocktake_events.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/custom_btn.dart';
import '../widgets/scanner.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

//Common Variables
final Debouncer debouncer = Debouncer();
const duration = Duration(milliseconds: 250);
bool isTorchOn = false;
bool isManualCount = true;
bool isScan = false;
final MobileScannerController scannerController = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates,
  returnImage: false,
);
final TextEditingController qtyController = TextEditingController();

//Screen Starts here
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _bcController = TextEditingController();

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      scannerController.dispose();
      qtyController.dispose();
      _bcController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kBgColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      StocktakeAppbarSession(),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25.0,
                          vertical: 12.0,
                        ),
                        child: ScanModeSelector(
                          onModeChanged: (newMode) {
                            setState(
                              () => isManualCount =
                                  (newMode == ScanMode.manualCount),
                            );
                          },
                        ),
                      ),

                      Scanner(constraints: constraints),

                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 25,
                        ),
                        height: 35,
                        child: CustomTextField(
                          hintText: 'Manual Barcode Entry',
                          controller: _bcController,
                          function: (value) {},
                        ),
                      ),

                      Expanded(child: _buildProductDetailsPanel()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductDetailsPanel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 25, right: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),

              boxShadow: [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Stock Barcode",
                      style: getSmartTitle(fontSize: 16, color: kThirdColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "In System: ...",
                        style: TextStyle(fontSize: 12, color: kPrimaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _stockDetailsListTile(
                  color: Colors.green,
                  title: "Description",
                  icon: Icons.description,
                  value: "RM - Stock Description",
                ),
                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.orangeAccent,
                  title: "Categories",
                  icon: Icons.category_outlined,
                  value: "- / -",
                ),

                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.blue,
                  title: "Custom 1",
                  icon: Icons.format_paint,
                  value: "-",
                ),
                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.deepOrange,
                  title: "Custom 2",
                  icon: Icons.settings,
                  value: "-",
                ),
                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.purple,
                  title: "Lay-By",
                  icon: Icons.numbers,
                  value: "-",
                ),
                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.yellow,
                  title: "Sales Order",
                  icon: Icons.history,
                  value: "-",
                ),

                const SizedBox(height: 5),
                _stockDetailsListTile(
                  color: Colors.lightBlue,
                  title: "Total",
                  icon: Icons.check,
                  value: "-",
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),

              boxShadow: [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Text("Counted Qty : ", style: TextStyle(color: kGreyColor)),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 35,
                    width: 100,
                    child: CustomTextField(
                      controller: qtyController,
                      hintText: "Qty",
                      keyboardType: TextInputType.number,
                      isEnabled: isManualCount,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomStocktakeBtn(
                function: () {
                  context.read<FetchingStocktakeListBloc>().add(
                    FetchStocktakeListEvent(),
                  );
                  context.navigateToNext(StockTakeListScreen());
                },
                icon: Icons.list,
                bgColor: kPrimaryColor,
                name: "LIST",
              ),

              CustomStocktakeBtn(
                function: () {
                  setState(() {
                    isScan = !isScan;
                  });
                },
                icon: Icons.qr_code_scanner,
                bgColor: kPrimaryColor,
                name: isScan ? "CLOSE" : "SCAN",
              ),

              BlocListener<StocktakeBloc, StocktakeStates>(
                listener: (context, state) {
                  if (state is StocktakeError) {
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(message: state.message),
                    );
                  }

                  if (state is StockTaken) {
                    qtyController.clear();
                    AlertInfo.show(
                      context: context,
                      text: 'Successfully Counted!',
                      typeInfo: TypeInfo.success,
                      backgroundColor: kSecondaryColor,
                      iconColor: kPrimaryColor,
                      textColor: kThirdColor,
                    );
                  }
                },
                child: CustomStocktakeBtn(
                  function: () async {
                    HapticFeedback.vibrate();
                    await _audioPlayer.play(AssetSource('assets/audio/beep.mp3'));
                  },
                  icon: Icons.add_shopping_cart,
                  bgColor: Colors.lightGreen,
                  name: "SAVE",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockDetailsListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 15, color: color),
            ),

            const SizedBox(width: 8),

            Text(title, style: TextStyle(fontSize: 10, color: kGreyColor)),
          ],
        ),

        Text(value, style: TextStyle(fontSize: 10)),
      ],
    );
  }
}
