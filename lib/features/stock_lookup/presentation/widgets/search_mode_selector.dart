import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../entities/vos/search_mode.dart';

class SearchModeSelector extends StatelessWidget {
  final SearchMode currentMode;
  final ValueChanged<SearchMode> onModeChanged;

  const SearchModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  void _showModeMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<SearchMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      items: SearchMode.values.map((mode) {
        final isSelected = mode == currentMode;
        return PopupMenuItem<SearchMode>(
          value: mode,
          height: 48,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? kPrimaryColor : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                mode.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? kPrimaryColor : Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedMode) {
      if (selectedMode != null && selectedMode != currentMode) {
        onModeChanged(selectedMode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showModeMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Icon(
          Icons.keyboard_arrow_up_rounded,
          color: kPrimaryColor,
          size: 20,
        ),
      ),
    );
  }
}
