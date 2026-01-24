import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../stocktake/presentation/BLoC/stocktake_bloc.dart';
import '../../../stocktake/presentation/BLoC/stocktake_events.dart';
import '../../../stocktake/presentation/widgets/delete_all_confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock Data (Replace with BLoC state later)
  String staffName = "John Doe";
  String staffID = "STF-001";
  double retentionDays = 7;
  bool backupToLan = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kGColor),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      _buildSectionTitle("Staff Profile"),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.badge_outlined,
                              "Staff ID",
                              staffID,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildInfoRow(
                              Icons.person_outline,
                              "Staff Name",
                              staffName,
                            ),
                            const SizedBox(height: 10),
                            _buildSignOutButton(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      _buildSectionTitle("Data & Backup"),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildSliderRow(),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildSwitchRow(
                              "Backup Stocktake to LAN Folder",
                              "Save a copy to server before clearing out committed stocktake data",
                              backupToLan,
                                  (val) => setState(() => backupToLan = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      _buildSectionTitle("Maintenance"),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildActionRow(
                              Icons.restore_page_outlined,
                              "Restore Data",
                              "Recover deleted stocktake from server",
                              Colors.blue,
                                  () {},
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildActionRow(
                              Icons.delete_forever_outlined,
                              "Delete All Current Stocktake",
                              "Clear all currently counted stocktake list permanently",
                              kErrorColor,
                                  () => _showDeleteConfirmation(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      Text(
                        "App Version 1.0.0 (AAAPOS Pty Ltd)",
                        style: TextStyle(
                          color: kSecondaryColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.navigateBack(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kSecondaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: kPrimaryColor,
              ),
            ),
          ),
          Text(
            "Settings",
            style: getSmartTitle(fontSize: 22, color: kSecondaryColor),
          ),
          const SizedBox(width: 40), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kSecondaryColor.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
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
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: kSecondaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: kSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: getSmartTitle(fontSize: 16, color: kSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            // Logout Logic
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: kErrorColor.withOpacity(0.2),
            side: BorderSide(color: kErrorColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            "Sign Off",
            style: TextStyle(
              fontSize: 16,
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Keep Backup Days",
                style: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${retentionDays.toInt()} Days",
                  style: const TextStyle(
                    color: kSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kPrimaryColor,
              inactiveTrackColor: kGreyColor.withOpacity(0.7),
              thumbColor: kSecondaryColor,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8.0,
                elevation: 4,
              ),
              overlayColor: kPrimaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: retentionDays,
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (val) => setState(() => retentionDays = val),
            ),
          ),
          Text(
            "Determines how long committed stocktake data is kept locally before auto-deletion.",
            style: TextStyle(
              color: kSecondaryColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16
                  ),
                  maxLines: 2, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: kSecondaryColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 3, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CupertinoSwitch(
            value: value,
            activeColor: kPrimaryColor,
            inactiveTrackColor: kGreyColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: kSecondaryColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: color
                    ),
                    maxLines: 1, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kSecondaryColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: kSecondaryColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StocktakeDeleteConfirmationDialog(
        onConfirm: () {
          LocalDbDAO.instance.deleteAllStocktake();
          context.read<FetchingStocktakeListBloc>().add(
            FetchStocktakeListEvent(),
          );
        },
      ),
    );
  }
}