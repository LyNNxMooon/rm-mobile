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
  // Calculator State
  String _display = "0";
  double? _firstOperand;
  String? _operator;

  // Flags to manage input state
  bool _shouldResetInput = false;

  // Checkbox State
  bool _isCostSelected = false;
  bool _isExclusiveSelected = false;

  @override
  void initState() {
    super.initState();
    _display = _formatNumber(widget.currentSell);
  }

  // Helper to remove trailing .0
  String _formatNumber(double num) {
    String s = num.toStringAsFixed(4);
    // Remove trailing zeros
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  // --- Checkbox Logic ---
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

        // Reset calculation state since we are loading a preset
        _firstOperand = null;
        _operator = null;
        _shouldResetInput = true; // Next typing replaces this value
      });
    }
  }

  // --- Real Calculator Logic ---
  void _onNumberTap(String number) {
    setState(() {
      if (_shouldResetInput) {
        // Start fresh (e.g. after pressing + or =)
        _display = number == "." ? "0." : number;
        _shouldResetInput = false;
      } else {
        // Append to current number
        if (_display == "0" && number != ".") {
          _display = number;
        } else {
          // Prevent multiple dots
          if (number == "." && _display.contains(".")) return;
          _display += number;
        }
      }

      // Uncheck boxes if user manually edits
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
        // First part of equation: "5 +"
        _firstOperand = currentVal;
      } else if (_operator != null && !_shouldResetInput) {
        // Chained calculation: "5 + 5 +" -> Calculate 10, then set up for next +
        _calculateIntermediate();
      } else {
        // Operator changed (e.g. user pressed + then decided on -)
        // or we just finished an equals and are using that result
        _firstOperand = currentVal;
      }

      _operator = nextOp;
      _shouldResetInput = true; // Ready for second number
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
        if (secondOperand != 0) {
          result = _firstOperand! / secondOperand;
        } else {
          result = 0.0; // Avoid NaN
        }
        break;
    }

    // Update state for next step
    _display = _formatNumber(result);
    _firstOperand = result; // Result becomes the new first operand
  }

  void _onEqualsTap() {
    setState(() {
      if (_operator != null && _firstOperand != null) {
        _calculateIntermediate();
        // Clear operator so next number starts fresh equation unless operator is pressed
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
        // CASE 1: Contextual Calculation (e.g., "100 + 10")

        if (_operator == "+" || _operator == "-") {
          // For Addition/Subtraction, calculate % OF the first operand.
          // Example: 100 + 10%
          // We calculate: 100 * 0.10 = 10.
          // The display becomes "10".
          // Pressing "=" afterwards will do: 100 + 10 = 110.
          double result = _firstOperand! * (currentValue / 100);
          _display = _formatNumber(result);
        } else {
          // For Multiplication/Division, standard behavior is factor conversion.
          // Example: 100 * 10% -> 100 * 0.1
          double result = currentValue / 100;
          _display = _formatNumber(result);
        }
      } else {
        // CASE 2: Standalone (e.g., "50 %")
        // Just convert to decimal: 0.5
        double result = currentValue / 100;
        _display = _formatNumber(result);
      }

      // We flag this as a completed input so typing a new number starts fresh
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
    // If we just calculated something, backspace usually clears all
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              "Price Calculator",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const Divider(),

            // Checkboxes
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

            // Display Screen
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

            // Calculator Grid
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
                _actionBtn("⌫", _onBackspace, color: Colors.orange),

                _numBtn("7"), _numBtn("8"), _numBtn("9"),
                _opBtn("x", () => _onOperatorTap("x")),

                _numBtn("4"), _numBtn("5"), _numBtn("6"),
                _opBtn("-", () => _onOperatorTap("-")),

                _numBtn("1"), _numBtn("2"), _numBtn("3"),
                _opBtn("+", () => _onOperatorTap("+")),

                _numBtn("0"), _numBtn("."),

                // Equals Button
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

                // OK / Done Button
                InkWell(
                  onTap: () {
                    // If user left an operation pending (e.g. "5 + 5" then hits OK), calculate it first
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
    );
  }

  // --- Widgets (Unchanged) ---
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
