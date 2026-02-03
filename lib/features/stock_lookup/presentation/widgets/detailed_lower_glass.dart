import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/price_calculator_dialog.dart';
import '../../../../constants/colors.dart';
import '../BLoC/stock_lookup_bloc.dart';
import '../BLoC/stock_lookup_events.dart';

class DetailedLowerGlass extends StatefulWidget {
  const DetailedLowerGlass({
    super.key,
    required this.sell,
    required this.exSell,
    required this.incCost,
    required this.exCost,
    required this.isGst,
    required this.description,
    required this.stockId,
  });

  final double sell;
  final double exSell;
  final double incCost;
  final double exCost;
  final bool isGst;
  final num stockId;
  final String description;

  @override
  State<DetailedLowerGlass> createState() => _DetailedLowerGlassState();
}

class _DetailedLowerGlassState extends State<DetailedLowerGlass> {
  late final TextEditingController _rrpController;
  late final TextEditingController _exRrpController;

  final FocusNode _rrpFocus = FocusNode();
  final FocusNode _exRrpFocus = FocusNode();

  @override
  void initState() {
    _rrpController = TextEditingController(
      text: widget.sell.toStringAsFixed(4),
    );
    _exRrpController = TextEditingController(
      text: widget.exSell.toStringAsFixed(4),
    );

    _rrpController.addListener(_onIncChanged);
    _exRrpController.addListener(_onExChanged);
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      _rrpController.dispose();
      _exRrpController.dispose();
      _rrpFocus.dispose();
      _exRrpFocus.dispose();
    }
    super.dispose();
  }

  void _onIncChanged() {
    if (!_rrpFocus.hasFocus) return;

    final text = _rrpController.text;
    if (text.isEmpty) return;

    final double incVal = double.tryParse(text) ?? 0.0;
    double exVal = 0.0;

    if (widget.isGst) {
      exVal = incVal / 1.1;
    } else {
      exVal = incVal;
    }

    _exRrpController.text = exVal.toStringAsFixed(4);
  }

  void _onExChanged() {
    if (!_exRrpFocus.hasFocus) return;

    final text = _exRrpController.text;
    if (text.isEmpty) return;

    final double exVal = double.tryParse(text) ?? 0.0;
    double incVal = 0.0;

    if (widget.isGst) {
      incVal = exVal * 1.1;
    } else {
      incVal = exVal;
    }

    _rrpController.text = incVal.toStringAsFixed(4);
  }

  void _openCalculator() async {
    final double? result = await showDialog<double>(
      context: context,
      builder: (context) => PriceCalculatorDialog(
        incCost: widget.incCost,
        exCost: widget.exCost,
        currentSell: double.tryParse(_rrpController.text) ?? 0.0,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // Set Inclusive Value
        _rrpController.text = result.toStringAsFixed(4);

        // Manually trigger the Ex Calculation since focus logic won't catch this
        if (widget.isGst) {
          _exRrpController.text = (result / 1.1).toStringAsFixed(4);
        } else {
          _exRrpController.text = result.toStringAsFixed(4);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: kSecondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(blurRadius: 20, color: kThirdColor.withOpacity(.1)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            "assets/images/rrp.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Inc RRP",
                        style: TextStyle(fontSize: 14, color: kSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        controller: _rrpController,
                        focusNode: _rrpFocus,
                        //keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                            203,
                            128,
                            128,
                            1.0,
                          ).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            "assets/images/rrp.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Exc RRP",
                        style: TextStyle(fontSize: 14, color: kSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: TextField(
                        controller: _exRrpController,
                        focusNode: _exRrpFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _openCalculator,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: _buttonDecoration(),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centered
                          children: [
                            Icon(
                              Icons.calculate,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "CALCULATOR",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final sellText = _exRrpController.text.trim();
                        final sellVal = double.tryParse(sellText);

                        if (sellVal == null) {
                          return;
                        }

                        context.read<StockUpdateBloc>().add(
                          SubmitStockUpdateEvent(
                            stockId: widget.stockId.toInt(),
                            description: widget.description,
                            sell: sellVal,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: _buttonDecoration(),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centered
                          children: [
                            BlocBuilder<StockUpdateBloc, StockUpdateState>(
                              builder: (context, state) {
                                if (state is StockUpdateLoading) {
                                  return CupertinoActivityIndicator(radius: 10,);
                                } else {
                                  return Icon(
                                    Icons.arrow_circle_up,
                                    color: kPrimaryColor,
                                    size: 20,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "UPDATE",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1),
      ),
    );
  }

  BoxDecoration _buttonDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kSecondaryColor.withOpacity(0.95),
          kSecondaryColor.withOpacity(0.70),
        ],
      ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: kSecondaryColor.withOpacity(0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: kThirdColor.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
