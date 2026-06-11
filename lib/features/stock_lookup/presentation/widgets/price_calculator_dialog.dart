import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/responsive_utils.dart';

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
  late final TextEditingController _displayController;

  bool _shouldResetInput = false;

  bool _isCostSelected = false;
  bool _isExclusiveSelected = false;
  bool _percentMode = false;
  double? _percentBase;

  @override
  void initState() {
    super.initState();
    _display = _formatNumber(widget.currentSell);
    _displayController = TextEditingController(text: _display);
    _displayController.addListener(_onDisplayChanged);
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  String _formatNumber(double num) {
    String s = num.toStringAsFixed(4);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void _onDisplayChanged() {
    final raw = _displayController.text;
    if (raw.isEmpty) {
      _display = "0";
      return;
    }

    final sanitized = _sanitizeNumber(raw);
    if (sanitized != raw) {
      _displayController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    _display = sanitized.isEmpty ? "0" : sanitized;

    if (_isCostSelected) {
      _isCostSelected = false;
      _isExclusiveSelected = false;
    }
  }

  String _sanitizeNumber(String value) {
    if (value.isEmpty) return value;
    final buffer = StringBuffer();
    bool dotSeen = false;
    for (final ch in value.split('')) {
      if (ch == '.') {
        if (dotSeen) continue;
        dotSeen = true;
        buffer.write(ch);
      } else if (RegExp(r'[0-9]').hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  void _setDisplay(String value) {
    _display = value;
    if (_displayController.text != value) {
      _displayController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
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
        _setDisplay(_formatNumber(valueToSet));
        _firstOperand = null;
        _operator = null;
        _percentMode = false;
        _percentBase = null;
        _shouldResetInput = true;
      });
    }
  }

  void _onNumberTap(String number) {
    setState(() {
      if (_shouldResetInput) {
        _setDisplay(number == "." ? "0." : number);
        _shouldResetInput = false;
      } else {
        if (_display == "0" && number != ".") {
          _setDisplay(number);
        } else {
          if (number == "." && _display.contains(".")) return;
          _setDisplay("$_display$number");
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
      _percentMode = false;
      _percentBase = null;
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

    _setDisplay(_formatNumber(result));
    _firstOperand = result;
  }

  void _onEqualsTap() {
    setState(() {
      if (_percentMode && _percentBase != null) {
        final double percent = double.tryParse(_display) ?? 0.0;
        final result = _percentBase! * (percent / 100);
        _setDisplay(_formatNumber(result));
        _percentMode = false;
        _percentBase = null;
        _shouldResetInput = true;
        return;
      }
      if (_operator != null && _firstOperand != null) {
        _calculateIntermediate();
        _operator = null;
        _firstOperand = null;
        _shouldResetInput = true;
      }
    });
  }

  void _onPercentTap() {
    setState(() {
      final double currentValue = double.tryParse(_display) ?? 0.0;

      if (_firstOperand != null && _operator != null) {
        if (_operator == "+" || _operator == "-") {
          final result = _firstOperand! * (currentValue / 100);
          _setDisplay(_formatNumber(result));
        } else {
          final result = currentValue / 100;
          _setDisplay(_formatNumber(result));
        }
        _shouldResetInput = true;
        return;
      }

      _percentBase = currentValue;
      _percentMode = true;
      _firstOperand = null;
      _operator = null;
      _setDisplay("0");
      _shouldResetInput = true;
    });
  }

  void _onClear() {
    setState(() {
      _setDisplay("0");
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = false;
      _isCostSelected = false;
      _isExclusiveSelected = false;
      _percentMode = false;
      _percentBase = null;
    });
  }

  void _onBackspace() {
    if (_display.isEmpty || _display == "0") return;
    setState(() {
      final updated = _display.substring(0, _display.length - 1);
      _setDisplay(updated.isEmpty || updated == "-" ? "0" : updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color textColor = isDark ? colors.onSurface : kThirdColor;
    final Color surface = isDark ? const Color(0xFF212121) : Colors.white;
    final Color surfaceAlt = isDark ? colors.surfaceAlt : Colors.grey[100]!;
    final Color divider = isDark ? colors.divider : Colors.grey[300]!;
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final double dialogWidth = isTablet
        ? (media.size.width * 0.56).clamp(360.0, 520.0)
        : (media.size.width * 0.9).clamp(280.0, 400.0);

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.88 - media.viewInsets.bottom,
          maxWidth: dialogWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
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
                          title: Text(
                            "Cost Price",
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
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
                          title: Text(
                            "Is Exclusive",
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
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
                  TextField(
                    controller: _displayController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: divider),
                      ),
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
                      _opBtn("÷", () => _onOperatorTap("/")),
                      _iconActionBtn(Icons.backspace_outlined, _onBackspace),
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
                            color: surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "=",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
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
                          child: Icon(
                            Icons.check,
                            color: isDark ? colors.onHero : Colors.white,
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

  Widget _numBtn(String label) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: () => _onNumberTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? colors.divider : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? colors.cardShadow : Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? colors.onSurface : kThirdColor,
          ),
        ),
      ),
    );
  }

  Widget _opBtn(String label, VoidCallback onTap) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceAlt : kSecondaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? colors.onSurface : kThirdColor,
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

  Widget _iconActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: Colors.orange),
      ),
    );
  }
}
