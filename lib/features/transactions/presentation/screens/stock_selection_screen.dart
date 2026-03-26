import 'package:flutter/material.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

/// Screen for selecting from multiple matched stock items
/// Displays a compact list view optimized for many items
class StockSelectionScreen extends StatefulWidget {
  final List<StockVO> matches;
  final String? searchQuery;

  const StockSelectionScreen({
    super.key,
    required this.matches,
    this.searchQuery,
  });

  @override
  State<StockSelectionScreen> createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final TextEditingController _filterController = TextEditingController();
  List<StockVO> _filteredMatches = [];

  @override
  void initState() {
    super.initState();
    _filteredMatches = widget.matches;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMatches = widget.matches;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredMatches = widget.matches.where((s) {
          return s.description.toLowerCase().contains(lowerQuery) ||
              s.barcode.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? colors.onSurface : kThirdColor,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Stock Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? colors.onSurface : kThirdColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.matches.length} items found',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _filterController,
              onChanged: _filterList,
              style: TextStyle(
                color: isDark ? colors.onSurface : kThirdColor,
              ),
              decoration: InputDecoration(
                hintText: 'Filter results...',
                hintStyle: TextStyle(
                  color: isDark ? colors.onSurfaceMuted : kGreyColor,
                ),
                prefixIcon: Icon(
                  Icons.filter_list,
                  color: isDark ? colors.onSurfaceMuted : kGreyColor,
                  size: 20,
                ),
                suffixIcon: _filterController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? colors.onSurfaceMuted : kGreyColor,
                          size: 20,
                        ),
                        onPressed: () {
                          _filterController.clear();
                          _filterList('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? colors.surfaceAlt : kSecondaryColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filteredMatches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: isDark ? colors.onSurfaceMuted : kGreyColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching items',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filteredMatches.length,
              itemBuilder: (context, index) {
                return _buildCompactStockItem(
                  context,
                  _filteredMatches[index],
                  isDark,
                  colors,
                );
              },
            ),
    );
  }

  Widget _buildCompactStockItem(
    BuildContext context,
    StockVO s,
    bool isDark,
    AppThemeColors colors,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? colors.surfaceAlt : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context, s),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Barcode chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surface
                      : kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.barcode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Description
              Expanded(
                child: Text(
                  s.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: s.quantity > 0
                      ? (isDark
                          ? kPrimaryColor.withOpacity(0.2)
                          : kPrimaryColor.withOpacity(0.1))
                      : (isDark
                          ? Colors.red.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatQty(s.quantity),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: s.quantity > 0 ? kPrimaryColor : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(num qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
}
