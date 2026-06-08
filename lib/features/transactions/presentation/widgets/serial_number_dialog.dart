import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/serial_number_vo.dart';
import '../../../../utils/responsive_utils.dart';

class _SerialRow {
  SerialNumberVO entry;
  bool selected;
  final TextEditingController numberController;

  _SerialRow({
    required this.entry,
    required this.selected,
  }) : numberController = TextEditingController(text: entry.number);
}

/// Dialog for selecting/entering serial numbers for a stock item
class SerialNumberDialog extends StatefulWidget {
  final String barcode;
  final String description;
  final int targetQuantity;
  final List<SerialNumberVO> availableSerials;
  final List<SerialNumberVO>? initialSelected;

  const SerialNumberDialog({
    super.key,
    required this.barcode,
    required this.description,
    required this.targetQuantity,
    required this.availableSerials,
    this.initialSelected,
  });

  /// Shows the dialog and returns selected serial numbers (or null if cancelled)
  static Future<List<SerialNumberVO>?> show({
    required BuildContext context,
    required String barcode,
    required String description,
    required int targetQuantity,
    required List<SerialNumberVO> availableSerials,
    List<SerialNumberVO>? initialSelected,
  }) {
    return showDialog<List<SerialNumberVO>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SerialNumberDialog(
        barcode: barcode,
        description: description,
        targetQuantity: targetQuantity,
        availableSerials: availableSerials,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<SerialNumberDialog> createState() => _SerialNumberDialogState();
}

class _SerialNumberDialogState extends State<SerialNumberDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<_SerialRow> _rows = [];
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final initialSelected = widget.initialSelected ?? const <SerialNumberVO>[];

    for (final serial in widget.availableSerials) {
      final isSelected = _isInitiallySelected(serial, initialSelected);
      _rows.add(_SerialRow(entry: serial, selected: isSelected));
    }

    for (final selected in initialSelected) {
      final alreadyAdded = _rows.any((row) => _matchesSerial(row.entry, selected));
      if (!alreadyAdded) {
        _rows.add(_SerialRow(entry: selected, selected: true));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final row in _rows) {
      row.numberController.dispose();
    }
    super.dispose();
  }

  List<_SerialRow> get _filteredRows {
    if (_searchQuery.isEmpty) return _rows;
    final query = _searchQuery.toLowerCase();
    return _rows
        .where((row) => row.entry.number.toLowerCase().contains(query))
        .toList();
  }

  int get _selectedCount => _rows.where((row) => row.selected).length;
  bool get _canSelect => _selectedCount < widget.targetQuantity;
  bool get _isValid =>
      _selectedCount == widget.targetQuantity &&
      _rows.where((row) => row.selected).every((row) => row.entry.hasNumber);

  void _toggleSerial(_SerialRow row) {
    setState(() {
      if (row.selected) {
        row.selected = false;
      } else if (_canSelect) {
        row.selected = true;
      }
    });
  }

  void _addEmptyRow() {
    setState(() {
      final shouldSelect = _canSelect;
      const entry = SerialNumberVO();
      _rows.insert(0, _SerialRow(entry: entry, selected: shouldSelect));
    });
  }

  bool _isInitiallySelected(
    SerialNumberVO candidate,
    List<SerialNumberVO> selected,
  ) {
    return selected.any((entry) => _matchesSerial(candidate, entry));
  }

  bool _matchesSerial(SerialNumberVO left, SerialNumberVO right) {
    if (left.serialAuditId != null && right.serialAuditId != null) {
      return left.serialAuditId == right.serialAuditId;
    }
    return left.number.trim().isNotEmpty && left.number == right.number;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  String _formatDate(DateTime date) => _dateFormat.format(date);

  List<SerialNumberVO> _buildSelectedSerials() {
    return _rows
        .where((row) => row.selected && row.entry.hasNumber)
        .map((row) {
          final number = row.numberController.text.trim();
          return row.entry.copyWith(number: number);
        })
        .toList();
  }

  Future<void> _pickWarrantyDate(_SerialRow row) async {
    final initialDate = _parseDate(row.entry.warrantyDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        row.entry = row.entry.copyWith(warrantyDate: _formatDate(picked));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = useDesktopNav
        ? 0.92
        : (isTablet
            ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
            : 1.0);

    final dialogWidth = useDesktopNav ? 620.0 : (isTablet ? 720.0 : MediaQuery.of(context).size.width * 0.98);
    final dialogHeight = useDesktopNav ? 550.0 : (isTablet ? 750.0 : MediaQuery.of(context).size.height * 0.7);
    final bool isLargeLayout = isTablet || useDesktopNav;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 40 : 15),
      backgroundColor: isDark ? const Color(0xFF212121) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(colors, isDark, isLargeLayout, uiScale),
            Expanded(
              flex: 2,
              child: _buildSerialsTable(colors, isDark, isLargeLayout, uiScale),
            ),
            _buildBottomSection(colors, isDark, isLargeLayout, uiScale),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors, bool isDark, bool isLargeLayout, double uiScale) {
    return Container(
      padding: EdgeInsets.all((isLargeLayout ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: (isLargeLayout ? 14 : 12) * uiScale,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: 4 * uiScale),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: (isLargeLayout ? 15 : 13) * uiScale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * uiScale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isLargeLayout ? 14 : 10) * uiScale,
              vertical: (isLargeLayout ? 10 : 8) * uiScale,
            ),
            decoration: BoxDecoration(
              color: _isValid
                  ? const Color(0xFF30B24C).withOpacity(0.15)
                  : (isDark ? colors.surfaceAlt : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isValid
                    ? const Color(0xFF30B24C)
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Selected",
                  style: TextStyle(
                    fontSize: (isLargeLayout ? 11 : 10) * uiScale,
                    color: colors.onSurfaceMuted,
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  "$_selectedCount / ${widget.targetQuantity}",
                  style: TextStyle(
                    fontSize: (isLargeLayout ? 18 : 16) * uiScale,
                    fontWeight: FontWeight.bold,
                    color: _isValid
                        ? const Color(0xFF30B24C)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialsTable(AppThemeColors colors, bool isDark, bool isLargeLayout, double uiScale) {
    final filtered = _filteredRows;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: (isLargeLayout ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isLargeLayout ? 12 : 8) * uiScale,
              vertical: (isLargeLayout ? 10 : 8) * uiScale,
            ),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 40 * uiScale),
                Expanded(
                  flex: isLargeLayout ? 3 : 2,
                  child: Text(
                    "Serial Number",
                    style: TextStyle(
                      fontSize: (isLargeLayout ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: (isLargeLayout ? 70 : 50) * uiScale,
                  child: Text(
                    "Age",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (isLargeLayout ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: (isLargeLayout ? 110 : 80) * uiScale,
                  child: Text(
                    "Warranty",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: (isLargeLayout ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? "No serials available"
                          : "No matching serials",
                      style: TextStyle(
                        fontSize: (isLargeLayout ? 14 : 12) * uiScale,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 4 * uiScale),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final row = filtered[index];
                        final isSelected = row.selected;
                        final isDisabled = !isSelected && !_canSelect;

                        return InkWell(
                          onTap: isDisabled ? null : () => _toggleSerial(row),
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (isLargeLayout ? 12 : 8) * uiScale,
                                vertical: (isLargeLayout ? 10 : 8) * uiScale,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40 * uiScale,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: isDisabled
                                          ? null
                                          : (_) => _toggleSerial(row),
                                      activeColor: kPrimaryColor,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  Expanded(
                                    flex: isLargeLayout ? 3 : 2,
                                    child: TextField(
                                      controller: row.numberController,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: (isLargeLayout ? 13 : 11) * uiScale,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? kPrimaryColor
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          row.entry = row.entry.copyWith(number: value.trim());
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: (isLargeLayout ? 70 : 50) * uiScale,
                                    child: Text(
                                      row.entry.ageInDays != null
                                          ? "${row.entry.ageInDays}"
                                          : "-",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: (isLargeLayout ? 12 : 10) * uiScale,
                                        color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: (isLargeLayout ? 110 : 80) * uiScale,
                                    child: InkWell(
                                      onTap: () => _pickWarrantyDate(row),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              row.entry.warrantyDate.isNotEmpty
                                                  ? row.entry.warrantyDate
                                                  : "-",
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: (isLargeLayout ? 12 : 10) * uiScale,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.blueGrey.shade600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: (isLargeLayout ? 18 : 16) * uiScale,
                                            color: colors.onSurfaceMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(AppThemeColors colors, bool isDark, bool isLargeLayout, double uiScale) {
    return Container(
      padding: EdgeInsets.all((isLargeLayout ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: (isLargeLayout ? 44 : 40) * uiScale,
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * uiScale),
                  child: Icon(
                    Icons.search,
                    size: 20 * uiScale,
                    color: colors.onSurfaceMuted,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    // Disable autocorrect and predictive text
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(
                      fontSize: (isLargeLayout ? 14 : 13) * uiScale,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search serials...',
                      hintStyle: TextStyle(
                        fontSize: (isLargeLayout ? 14 : 13) * uiScale,
                        color: colors.onSurfaceMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10 * uiScale),
                      child: Icon(
                        Icons.close,
                        size: 18 * uiScale,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10 * uiScale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addEmptyRow,
                  label: Text(
                    "Add",
                    style: TextStyle(fontSize: (isLargeLayout ? 13 : 12) * uiScale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                    padding: EdgeInsets.symmetric(
                      vertical: (isLargeLayout ? 12 : 10) * uiScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    padding: EdgeInsets.symmetric(
                      vertical: (isLargeLayout ? 12 : 10) * uiScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: (isLargeLayout ? 14 : 13) * uiScale),
                  ),
                ),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isValid
                      ? () => Navigator.of(context).pop(_buildSelectedSerials())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    disabledForegroundColor: isDark
                        ? Colors.white38
                        : Colors.grey.shade500,
                    padding: EdgeInsets.symmetric(
                      vertical: (isLargeLayout ? 12 : 10) * uiScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: (isLargeLayout ? 14 : 13) * uiScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
