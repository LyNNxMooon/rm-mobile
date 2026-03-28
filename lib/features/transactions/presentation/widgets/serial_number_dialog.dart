import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Model for available serial numbers
class SerialItem {
  final String serialNumber;
  final int ageInDays;
  final DateTime? warrantyExpiry;

  SerialItem({
    required this.serialNumber,
    required this.ageInDays,
    this.warrantyExpiry,
  });
}

/// Dialog for selecting/entering serial numbers for a stock item
class SerialNumberDialog extends StatefulWidget {
  final String barcode;
  final String description;
  final int targetQuantity;
  final List<SerialItem> availableSerials;
  final List<String>? initialSelected;

  const SerialNumberDialog({
    super.key,
    required this.barcode,
    required this.description,
    required this.targetQuantity,
    required this.availableSerials,
    this.initialSelected,
  });

  /// Shows the dialog and returns selected serial numbers (or null if cancelled)
  static Future<List<String>?> show({
    required BuildContext context,
    required String barcode,
    required String description,
    required int targetQuantity,
    required List<SerialItem> availableSerials,
    List<String>? initialSelected,
  }) {
    return showDialog<List<String>>(
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
  final TextEditingController _manualEntryController = TextEditingController();
  final Set<String> _selectedSerials = {};
  String _searchQuery = '';
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      _selectedSerials.addAll(widget.initialSelected!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualEntryController.dispose();
    super.dispose();
  }

  List<SerialItem> get _filteredSerials {
    if (_searchQuery.isEmpty) return widget.availableSerials;
    final query = _searchQuery.toLowerCase();
    return widget.availableSerials
        .where((s) => s.serialNumber.toLowerCase().contains(query))
        .toList();
  }

  bool get _canSelect => _selectedSerials.length < widget.targetQuantity;
  bool get _isValid => _selectedSerials.length == widget.targetQuantity;

  void _toggleSerial(String serial) {
    setState(() {
      if (_selectedSerials.contains(serial)) {
        _selectedSerials.remove(serial);
      } else if (_canSelect) {
        _selectedSerials.add(serial);
      }
    });
  }

  void _addManualSerial() {
    final serial = _manualEntryController.text.trim();
    if (serial.isNotEmpty && _canSelect) {
      setState(() {
        _selectedSerials.add(serial);
        _manualEntryController.clear();
        _showManualEntry = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    final dialogWidth = isTablet ? 720.0 : MediaQuery.of(context).size.width * 0.98;
    final dialogHeight = isTablet ? 750.0 : MediaQuery.of(context).size.height * 0.7;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15),
      backgroundColor: isDark ? colors.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Top Section (1 part) - Stock Header
            _buildHeader(colors, isDark, isTablet, uiScale),

            // Middle Section (2 parts) - Available Serials Table
            Expanded(
              flex: 2,
              child: _buildSerialsTable(colors, isDark, isTablet, uiScale),
            ),

            // Bottom Section (1 part) - Search, Manual Entry, Actions
            _buildBottomSection(colors, isDark, isTablet, uiScale),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    return Container(
      padding: EdgeInsets.all((isTablet ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Barcode & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: (isTablet ? 14 : 12) * uiScale,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: 4 * uiScale),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: (isTablet ? 15 : 13) * uiScale,
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
          // Selection Counter
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isTablet ? 14 : 10) * uiScale,
              vertical: (isTablet ? 10 : 8) * uiScale,
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
                    fontSize: (isTablet ? 11 : 10) * uiScale,
                    color: colors.onSurfaceMuted,
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  "${_selectedSerials.length} / ${widget.targetQuantity}",
                  style: TextStyle(
                    fontSize: (isTablet ? 18 : 16) * uiScale,
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

  Widget _buildSerialsTable(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    final filtered = _filteredSerials;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: (isTablet ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isTablet ? 12 : 8) * uiScale,
              vertical: (isTablet ? 10 : 8) * uiScale,
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
                SizedBox(width: 40 * uiScale), // Checkbox space
                Expanded(
                  flex: isTablet ? 3 : 2,
                  child: Text(
                    "Serial Number",
                    style: TextStyle(
                      fontSize: (isTablet ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: (isTablet ? 70 : 50) * uiScale,
                  child: Text(
                    "Age",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (isTablet ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: (isTablet ? 110 : 80) * uiScale,
                  child: Text(
                    "Warranty",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: (isTablet ? 13 : 11) * uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? "No serials available"
                          : "No matching serials",
                      style: TextStyle(
                        fontSize: (isTablet ? 14 : 12) * uiScale,
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
                        final item = filtered[index];
                        final isSelected = _selectedSerials.contains(item.serialNumber);
                        final isDisabled = !isSelected && !_canSelect;

                        return InkWell(
                          onTap: isDisabled ? null : () => _toggleSerial(item.serialNumber),
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (isTablet ? 12 : 8) * uiScale,
                                vertical: (isTablet ? 10 : 8) * uiScale,
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  SizedBox(
                                    width: 40 * uiScale,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: isDisabled
                                          ? null
                                          : (_) => _toggleSerial(item.serialNumber),
                                      activeColor: kPrimaryColor,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  // Serial Number
                                  Expanded(
                                    flex: isTablet ? 3 : 2,
                                    child: Text(
                                      item.serialNumber,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: (isTablet ? 13 : 11) * uiScale,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? kPrimaryColor
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Age
                                  SizedBox(
                                    width: (isTablet ? 70 : 50) * uiScale,
                                    child: Text(
                                      "${item.ageInDays}d",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: (isTablet ? 12 : 10) * uiScale,
                                        color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ),
                                  // Warranty
                                  SizedBox(
                                    width: (isTablet ? 110 : 80) * uiScale,
                                    child: Text(
                                      item.warrantyExpiry != null
                                          ? dateFormat.format(item.warrantyExpiry!)
                                          : "-",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: (isTablet ? 12 : 10) * uiScale,
                                        color: _isWarrantyExpired(item.warrantyExpiry)
                                            ? kErrorColor
                                            : (isDark ? Colors.white70 : Colors.blueGrey.shade600),
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

  bool _isWarrantyExpired(DateTime? warranty) {
    if (warranty == null) return false;
    return warranty.isBefore(DateTime.now());
  }

  Widget _buildBottomSection(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    return Container(
      padding: EdgeInsets.all((isTablet ? 16 : 12) * uiScale),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Container(
            height: (isTablet ? 44 : 40) * uiScale,
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
                    style: TextStyle(
                      fontSize: (isTablet ? 14 : 13) * uiScale,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search serials...',
                      hintStyle: TextStyle(
                        fontSize: (isTablet ? 14 : 13) * uiScale,
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

          // Manual Entry Area
          if (_showManualEntry) ...[
            Container(
              padding: EdgeInsets.all(10 * uiScale),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualEntryController,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: (isTablet ? 14 : 13) * uiScale,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter serial number',
                        hintStyle: TextStyle(
                          fontSize: (isTablet ? 14 : 13) * uiScale,
                          color: colors.onSurfaceMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addManualSerial(),
                    ),
                  ),
                  SizedBox(width: 8 * uiScale),
                  GestureDetector(
                    onTap: _addManualSerial,
                    child: Container(
                      padding: EdgeInsets.all(8 * uiScale),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18 * uiScale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 6 * uiScale),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showManualEntry = false;
                      _manualEntryController.clear();
                    }),
                    child: Container(
                      padding: EdgeInsets.all(8 * uiScale),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18 * uiScale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10 * uiScale),
          ],

          // Action Buttons Row
          Row(
            children: [
              // Create Serial Entry Button
              if (!_showManualEntry && _canSelect)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showManualEntry = true),
                   // icon: Icon(Icons.add, size: 18 * uiScale),
                    label: Text(
                      "Add",
                      style: TextStyle(fontSize: (isTablet ? 13 : 12) * uiScale),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      padding: EdgeInsets.symmetric(
                        vertical: (isTablet ? 12 : 10) * uiScale,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (!_showManualEntry && _canSelect)
                SizedBox(width: 10 * uiScale),

              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: (isTablet ? 12 : 10) * uiScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: (isTablet ? 14 : 13) * uiScale),
                  ),
                ),
              ),
              SizedBox(width: 10 * uiScale),

              // Confirm Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isValid
                      ? () => Navigator.of(context).pop(_selectedSerials.toList())
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
                      vertical: (isTablet ? 12 : 10) * uiScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: (isTablet ? 14 : 13) * uiScale,
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
