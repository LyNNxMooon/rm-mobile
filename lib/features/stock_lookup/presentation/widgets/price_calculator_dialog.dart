import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';

class PriceCalculatorDialog extends StatefulWidget {
  final double incCost;
  final double exCost;
  final double currentSell;

  const PriceCalculatorDialog({
    super.key,
    required this.incCost,
    required this.exCost,
    required this.currentSell,
  });

  @override
  State<PriceCalculatorDialog> createState() => _PriceCalculatorDialogState();
}

class _PriceCalculatorDialogState extends State<PriceCalculatorDialog> {
  String _display = "0";
  double? _firstOperand;
  String? _operator;

  bool _shouldResetInput = false;

  bool _isCostSelected = false;
  bool _isExclusiveSelected = false;

  @override
  void initState() {
    super.initState();
    _display = _formatNumber(widget.currentSell);
  }

  String _formatNumber(double num) {
    String s = num.toStringAsFixed(4);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void _updateDisplayBasedOnSelection() {
    double valueToSet = 0.0;

    if (_isCostSelected) {
      if (_isExclusiveSelected) {
        valueToSet = widget.exCost;
      } else {
        valueToSet = widget.incCost;
      }

      setState(() {
        _display = _formatNumber(valueToSet);
        _firstOperand = null;
        _operator = null;
        _shouldResetInput = true;
      });
    }
  }

  void _onNumberTap(String number) {
    setState(() {
      if (_shouldResetInput) {
        _display = number == "." ? "0." : number;
        _shouldResetInput = false;
      } else {
        if (_display == "0" && number != ".") {
          _display = number;
        } else {
          if (number == "." && _display.contains(".")) return;
          _display += number;
        }
      }

      if (_isCostSelected) {
        _isCostSelected = false;
        _isExclusiveSelected = false;
      }
    });
  }

  void _onOperatorTap(String nextOp) {
    setState(() {
      final double currentVal = double.tryParse(_display) ?? 0.0;

      if (_firstOperand == null) {
        _firstOperand = currentVal;
      } else if (_operator != null && !_shouldResetInput) {
        _calculateIntermediate();
      } else {
        _firstOperand = currentVal;
      }

      _operator = nextOp;
      _shouldResetInput = true;
    });
  }

  void _calculateIntermediate() {
    if (_firstOperand == null || _operator == null) return;

    final double secondOperand = double.tryParse(_display) ?? 0.0;
    double result = 0.0;

    switch (_operator) {
      case "+":
        result = _firstOperand! + secondOperand;
        break;
      case "-":
        result = _firstOperand! - secondOperand;
        break;
      case "x":
        result = _firstOperand! * secondOperand;
        break;
      case "/":
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0.0;
        break;
    }

    _display = _formatNumber(result);
    _firstOperand = result;
  }

  void _onEqualsTap() {
    setState(() {
      if (_operator != null && _firstOperand != null) {
        _calculateIntermediate();
        _operator = null;
        _firstOperand = null;
        _shouldResetInput = true;
      }
    });
  }

  void _onPercentTap() {
    final double currentValue = double.tryParse(_display) ?? 0.0;

    setState(() {
      if (_firstOperand != null && _operator != null) {
        if (_operator == "+" || _operator == "-") {
          final result = _firstOperand! * (currentValue / 100);
          _display = _formatNumber(result);
        } else {
          final result = currentValue / 100;
          _display = _formatNumber(result);
        }
      } else {
        final result = currentValue / 100;
        _display = _formatNumber(result);
      }

      _shouldResetInput = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = "0";
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = false;
      _isCostSelected = false;
      _isExclusiveSelected = false;
    });
  }

  void _onBackspace() {
    if (_shouldResetInput && _operator == null) {
      _onClear();
      return;
    }

    if (_display.isNotEmpty && _display != "0") {
      setState(() {
        _display = _display.substring(0, _display.length - 1);
        if (_display.isEmpty || _display == "-") _display = "0";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sell Price (RRP) Calculator",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            "Cost Price",
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isCostSelected,
                          activeColor: kPrimaryColor,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setState(() {
                              _isCostSelected = val ?? false;
                              _updateDisplayBasedOnSelection();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            "Is Exclusive",
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isExclusiveSelected,
                          activeColor: kPrimaryColor,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setState(() {
                              _isExclusiveSelected = val ?? false;
                              if (_isExclusiveSelected) _isCostSelected = true;
                              _updateDisplayBasedOnSelection();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _display,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kThirdColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _actionBtn("C", _onClear, color: kErrorColor),
                      _opBtn("%", _onPercentTap),
                      _opBtn("/", () => _onOperatorTap("/")),
                      _actionBtn("?", _onBackspace, color: Colors.orange),
                      _numBtn("7"),
                      _numBtn("8"),
                      _numBtn("9"),
                      _opBtn("x", () => _onOperatorTap("x")),
                      _numBtn("4"),
                      _numBtn("5"),
                      _numBtn("6"),
                      _opBtn("-", () => _onOperatorTap("-")),
                      _numBtn("1"),
                      _numBtn("2"),
                      _numBtn("3"),
                      _opBtn("+", () => _onOperatorTap("+")),
                      _numBtn("0"),
                      _numBtn("."),
                      InkWell(
                        onTap: _onEqualsTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kSecondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "=",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kThirdColor,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (_operator != null) _onEqualsTap();
                          final val = double.tryParse(_display);
                          Navigator.pop(context, val);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numBtn(String label) {
    return InkWell(
      onTap: () => _onNumberTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kThirdColor,
          ),
        ),
      ),
    );
  }

  Widget _opBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: kSecondaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kThirdColor,
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    VoidCallback onTap, {
    Color color = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
