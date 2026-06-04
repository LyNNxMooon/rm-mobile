import 'package:flutter/material.dart';

import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Screen shown when the user taps "Finalise" on the unified Sales screen.
/// The user picks the transaction type (Account Sales / Sales Order /
/// Quotes / Lay-bys). Returns the picked title via [Navigator.pop], or
/// `null` if the user cancels.
///
/// The lower "Payments" section is intentionally disabled (Coming Soon).
class FinalisePickerScreen extends StatelessWidget {
  final bool isAccountCustomer;

  const FinalisePickerScreen({
    super.key,
    this.isAccountCustomer = false,
  });

  static Future<String?> show(
    BuildContext context, {
    bool isAccountCustomer = false,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            FinalisePickerScreen(isAccountCustomer: isAccountCustomer),
      ),
    );
  }

  static const Color _appBarColor = Color.fromRGBO(12, 58, 85, 1);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final types = <_TxType>[
      if (isAccountCustomer)
        const _TxType(
          label: 'Account',
          value: 'Account Sales',
          icon: Icons.contact_page_outlined,
          color: Color(0xFF0F52BA),
        ),
      const _TxType(
        label: 'Sales Order',
        value: 'Sales Order',
        icon: Icons.shopping_cart_outlined,
        color: Color(0xFF00C4CC),
      ),
      const _TxType(
        label: 'Quote',
        value: 'Quotes',
        icon: Icons.edit_document,
        color: Color(0xFF007AFF),
      ),
      const _TxType(
        label: 'Lay-by',
        value: 'Lay-bys',
        icon: Icons.folder_open_rounded,
        color: Color(0xFF788A9F),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromRGBO(7, 27, 54, 1),
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        title: const Text(
          'Finalise',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: useDesktopNav ? 32 : (isTablet ? 24 : 16),
            vertical: 16,
          ),
          child: Column(
            children: [
              _buildSection(
                context,
                title: 'Choose Transaction Type',
                titleSize: (isTablet && !useDesktopNav) ? 18 : 16,
                expandChild: false,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: useDesktopNav
                      ? 4
                      : (isTablet ? (isLandscape ? 4 : 3) : 2),
                  mainAxisSpacing: isTablet ? 16 : 12,
                  crossAxisSpacing: isTablet ? 16 : 12,
                  childAspectRatio: useDesktopNav
                      ? 2.6
                      : (isTablet ? (isLandscape ? 2.2 : 2.0) : 2.4),
                  children: types
                      .map((t) => _TypeCard(
                            type: t,
                            isDark: isDark,
                            isTablet: isTablet && !useDesktopNav,
                            onTap: () =>
                                Navigator.of(context).pop(t.value),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildSection(
                  context,
                  title: 'Payments',
                  titleSize: (isTablet && !useDesktopNav) ? 18 : 16,
                  child: _buildComingSoon(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    double titleSize = 16,
    bool expandChild = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (expandChild) Expanded(child: child) else child,
      ],
    );
  }

  Widget _buildComingSoon(bool isDark) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: Colors.white70,
                ),
                SizedBox(height: 12),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxType {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TxType({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _TypeCard extends StatelessWidget {
  final _TxType type;
  final bool isDark;
  final bool isTablet;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isDark,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double iconBox = isTablet ? 60 : 44;
    final double glyphSize = isTablet ? 30 : 22;
    final double gap = isTablet ? 16 : 12;
    final double labelSize = isTablet ? 18 : 14;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 14,
            vertical: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withOpacity(0.12), width: 1.5),
              left: BorderSide(
                  color: Colors.white.withOpacity(0.12), width: 1.5),
              right: BorderSide(
                  color: Colors.white.withOpacity(0.12), width: 0.42),
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.12), width: 0.42),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF42A5F5).withOpacity(0.40),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  type.icon,
                  color: const Color.fromRGBO(12, 58, 85, 1),
                  size: glyphSize,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
