import 'package:flutter/material.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Screen for selecting from multiple matched customers
/// Displays a compact list view optimized for many items
class CustomerSelectionScreen extends StatefulWidget {
  final List<CustomerVO> matches;
  final String? searchQuery;

  const CustomerSelectionScreen({
    super.key,
    required this.matches,
    this.searchQuery,
  });

  @override
  State<CustomerSelectionScreen> createState() =>
      _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final TextEditingController _filterController = TextEditingController();
  List<CustomerVO> _filteredMatches = [];

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
        _filteredMatches = widget.matches.where((c) {
          return c.surname.toLowerCase().contains(lowerQuery) ||
              c.givenNames.toLowerCase().contains(lowerQuery) ||
              c.company.toLowerCase().contains(lowerQuery) ||
              c.barcode.toLowerCase().contains(lowerQuery) ||
              c.email.toLowerCase().contains(lowerQuery) ||
              c.phone.toLowerCase().contains(lowerQuery) ||
              c.mobile.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;

    // Desktop sizing
    final double titleFontSize = useDesktopNav ? 14.0 : 18.0;
    final double subtitleFontSize = useDesktopNav ? 11.0 : 12.0;
    final double toolbarHeight = useDesktopNav ? 56.0 : 70.0;
    final double filterBarHeight = useDesktopNav ? 52.0 : 68.0;
    final double filterHPadding = useDesktopNav ? 12.0 : 16.0;
    final double filterVPadding = useDesktopNav ? 8.0 : 12.0;
    final double filterFontSize = useDesktopNav ? 12.0 : 14.0;
    final double filterIconSize = useDesktopNav ? 18.0 : 20.0;
    final double filterRadius = useDesktopNav ? 6.0 : 10.0;
    final double backIconSize = useDesktopNav ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 0,
        toolbarHeight: toolbarHeight,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? colors.onSurface : kThirdColor,
            size: backIconSize,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Customer',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? colors.onSurface : kThirdColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.matches.length} customers found',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(filterBarHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
              child: Padding(
                padding: EdgeInsets.fromLTRB(filterHPadding, filterVPadding, filterHPadding, filterVPadding),
                child: TextField(
                  controller: _filterController,
                  onChanged: _filterList,
                  style: TextStyle(
                    color: isDark ? colors.onSurface : kThirdColor,
                    fontSize: filterFontSize,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Filter results...',
                    hintStyle: TextStyle(
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                      fontSize: filterFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.filter_list,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                      size: filterIconSize,
                    ),
                    suffixIcon: _filterController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark ? colors.onSurfaceMuted : kGreyColor,
                              size: filterIconSize,
                            ),
                            onPressed: () {
                              _filterController.clear();
                              _filterList('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? colors.surfaceAlt : kSecondaryColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: filterHPadding,
                      vertical: useDesktopNav ? 10 : 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(filterRadius),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(filterRadius),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(filterRadius),
                      borderSide: const BorderSide(color: kPrimaryColor),
                    ),
                  ),
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
                    size: useDesktopNav ? 40 : 48,
                    color: isDark ? colors.onSurfaceMuted : kGreyColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching customers',
                    style: TextStyle(
                      fontSize: useDesktopNav ? 14 : 16,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: useDesktopNav ? 12 : 12,
                    vertical: useDesktopNav ? 6 : 8,
                  ),
                  itemCount: _filteredMatches.length,
                  itemBuilder: (context, index) {
                    return _buildCompactCustomerItem(
                      context,
                      _filteredMatches[index],
                      isDark,
                      colors,
                      useDesktopNav,
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildCompactCustomerItem(
    BuildContext context,
    CustomerVO c,
    bool isDark,
    AppThemeColors colors,
    bool useDesktopNav,
  ) {
    final displayName = _buildDisplayName(c);

    // Desktop sizing
    final double cardMargin = useDesktopNav ? 3.0 : 4.0;
    final double cardRadius = useDesktopNav ? 6.0 : 8.0;
    final double cardPaddingH = useDesktopNav ? 10.0 : 12.0;
    final double cardPaddingV = useDesktopNav ? 8.0 : 10.0;
    final double barcodeFontSize = useDesktopNav ? 10.0 : 11.0;
    final double nameFontSize = useDesktopNav ? 12.0 : 14.0;
    final double companyFontSize = useDesktopNav ? 11.0 : 12.0;
    final double arrowSize = useDesktopNav ? 18.0 : 20.0;
    final double companyMaxWidth = useDesktopNav ? 100.0 : 120.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: cardMargin),
      color: isDark ? colors.surfaceAlt : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context, c),
        borderRadius: BorderRadius.circular(cardRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cardPaddingH, vertical: cardPaddingV),
          child: Row(
            children: [
              // Barcode chip
              if (c.barcode.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: useDesktopNav ? 5 : 6,
                    vertical: useDesktopNav ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.surface
                        : kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.barcode,
                    style: TextStyle(
                      fontSize: barcodeFontSize,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              if (c.barcode.isNotEmpty) SizedBox(width: useDesktopNav ? 8 : 10),
              // Name
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
              ),
              // Company (if different from name)
              if (c.company.isNotEmpty && displayName != c.company) ...[
                SizedBox(width: useDesktopNav ? 6 : 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: companyMaxWidth),
                  child: Text(
                    c.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: companyFontSize,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ),
              ],
              SizedBox(width: useDesktopNav ? 6 : 8),
              // Arrow
              Icon(
                Icons.chevron_right,
                size: arrowSize,
                color: isDark ? colors.onSurfaceMuted : kGreyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDisplayName(CustomerVO c) {
    final parts = <String>[];
    if (c.givenNames.isNotEmpty) parts.add(c.givenNames);
    if (c.surname.isNotEmpty) parts.add(c.surname);

    if (parts.isEmpty && c.company.isNotEmpty) {
      return c.company;
    }

    return parts.isEmpty ? "Unknown Customer" : parts.join(' ');
  }
}
