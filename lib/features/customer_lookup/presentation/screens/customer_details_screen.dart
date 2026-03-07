import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../constants/colors.dart';

// Assuming you have this gradient defined in your constants
const kGColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F8ABE), Color(0xFF05203C)],
);

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});

  final CustomerVO customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffDetailBloc>().add(
            LoadStaffDetailsEvent(
              openedId: widget.customer.openedId,
              ownerId: widget.customer.ownerId,
            ),
          );
    });
  }

  double _uiScale(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
  }

  double _font(BuildContext context, double size) => size * _uiScale(context);

  
  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return "";

    List<String> nameParts = trimmedName.split(RegExp(r'\s+'));

    if (nameParts.length == 1) {
      String word = nameParts[0];
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    } else {
      String firstLetter = nameParts.first[0];
      String lastLetter = nameParts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatStaffDisplay(StaffDetailInfo? staff) {
    if (staff == null) return "-";
    final String fullName =
        "${staff.givenNames} ${staff.surname}".trim();
    final String barcode = staff.staffNo.trim();

    if (barcode.isEmpty && fullName.isEmpty) return "-";
    if (barcode.isEmpty) return fullName;
    if (fullName.isEmpty) return barcode;
    return "$barcode - $fullName";
  }

  void _showLaunchError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _dialNumber(String number) async {
    final String trimmed = number.trim();
    if (trimmed.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: trimmed);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showLaunchError("No phone app found for this device.");
    }
  }

  Future<void> _emailTo(String email) async {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) return;

    final Uri mailtoUri = Uri(scheme: 'mailto', path: trimmed);
    final bool launched = await launchUrl(
      mailtoUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showLaunchError("No email app found for this device.");
    }
  }

  Future<void> _openMapForAddress(String addressQuery) async {
    final String trimmed = addressQuery.trim();
    if (trimmed.isEmpty) return;

    final Uri primaryUri = Platform.isIOS
        ? Uri(
            scheme: 'https',
            host: 'maps.apple.com',
            queryParameters: <String, String>{'q': trimmed},
          )
        : Uri(
            scheme: 'geo',
            path: '0,0',
            queryParameters: <String, String>{'q': trimmed},
          );

    final bool launched = await launchUrl(
      primaryUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      final Uri fallbackUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/',
        queryParameters: <String, String>{'api': '1', 'query': trimmed},
      );
      final bool fallbackLaunched = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );

      if (!fallbackLaunched) {
        _showLaunchError("No maps app found for this device.");
      }
    }
  }

  void _showSecondaryAddressesDialog() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  elevation: 10,
  backgroundColor: Colors.white, // Or a slightly off-white like Color(0xFFF9FAFB) if you prefer
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Dialog Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Matches the scaffold background of the details screen
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  "Secondary Addresses",
                  style: TextStyle(
                    fontSize: _font(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            // Close Button in header instead of actions
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
      
      // Dialog Content (Scrollable list of addresses)
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(widget.customer.addresses.length, (index) {
              final address = widget.customer.addresses[index];
              final List<String> addressParts = [
                address.addr1,
                address.addr2,
                address.addr3,
                "${address.suburb} ${address.state} ${address.postcode}".trim(),
                address.country,
              ].where((s) => s.isNotEmpty).toList();
              final String addressQuery = addressParts.join(', ');
              final bool showMapIcon =
                  address.addressNumber == 2 || address.addressNumber == 3;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Number Badge + Map Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Address ${address.addressNumber}",
                            style: TextStyle(
                              fontSize: _font(context, 12),
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                        if (showMapIcon)
                          InkWell(
                            onTap: () => _openMapForAddress(addressQuery),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.map,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Address Lines
                    if (address.addr1.isNotEmpty) ...[
                      Text(address.addr1, style: TextStyle(fontSize: baseSize, color: Colors.black87)),
                    ],
                    if (address.addr2.isNotEmpty) ...[
                      Text(address.addr2, style: TextStyle(fontSize: baseSize, color: Colors.black87)),
                    ],
                    if (address.addr3.isNotEmpty) ...[
                      Text(address.addr3, style: TextStyle(fontSize: baseSize, color: Colors.black87)),
                    ],
                    if (address.suburb.isNotEmpty || address.state.isNotEmpty || address.postcode.isNotEmpty) ...[
                      Text(
                        "${address.suburb} ${address.state} ${address.postcode}".trim(),
                        style: TextStyle(fontSize: baseSize, color: Colors.black87),
                      ),
                    ],
                    if (address.country.isNotEmpty) ...[
                      Text(address.country, style: TextStyle(fontSize: baseSize, color: Colors.black87)),
                    ],
                    
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Contact Info within this address
                    if (address.phone.isNotEmpty) ...[
                      _buildDialogContactRow(Icons.phone_outlined, address.phone, smallSize),
                    ],
                    if (address.mobile.isNotEmpty) ...[
                      _buildDialogContactRow(Icons.phone_iphone_outlined, address.mobile, smallSize),
                    ],
                    if (address.email.isNotEmpty) ...[
                      _buildDialogContactRow(Icons.email_outlined, address.email, smallSize),
                    ],
                    
                    // Show a message if no contact info exists for this address to avoid empty space
                    if (address.phone.isEmpty && address.mobile.isEmpty && address.email.isEmpty) ...[
                       Text("No contact details for this address.", style: TextStyle(fontSize: smallSize, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ],
  ),
);
      },
    );
  }

  String _getGradeLabel(int grade) {
    switch (grade) {
      case 0: return "Grade (Default)";
      case 1: return "Grade (A)";
      case 2: return "Grade (B)";
      case 3: return "Grade (C)";
      case 4: return "Grade (D)";
      default: return "Grade ($grade)";
    }
  }

  Widget _buildDialogContactRow(IconData icon, String text, double fontSize) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A slightly deeper grey helps the white cards pop and look solid
      backgroundColor: const Color(0xFFF3EFE8), 
      body: Stack(
        children: [
          // Background Gradient Container (Top Half)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(gradient: kGColor),
          ),
          
          // Custom App Bar Elements (Overlay)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        label: const Text(
                          "Customers", 
                          style: TextStyle(color: Colors.white, fontSize: 16)
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                      const Text(
                        "Profile",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 80), 
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 12),
                        _buildContactDetailsCard(),
                        const SizedBox(height: 12),
                        _buildAddressCard(),
                        const SizedBox(height: 12),
                        _buildFinancialCard(),
                        const SizedBox(height: 12),
                        _buildPersonalCard(),
                        const SizedBox(height: 12),
                        _buildAdditionalInfoCard(),
                        if (widget.customer.notes.isNotEmpty || widget.customer.comments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildNotesCard(),
                        ],
                        const SizedBox(height: 12),
                        _buildMetadataCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card Builders ---

  Widget _buildHeaderCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    final double badgeSize = _font(context, 12);
    final double avatarSize = _font(context, 24);
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // <--- ADDED THIS to align chips & content to the left
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[400]!, Colors.grey[500]!],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(widget.customer.displayName),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Name and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.customer.displayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Active/Inactive Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.customer.inactive ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.customer.inactive ? 'Inactive' : 'Active',
                            style: TextStyle(
                              color: widget.customer.inactive ? Colors.red[700] : Colors.green[700],
                              fontSize: badgeSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.customer.company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.customer.company,
                        style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      "Customer ID: ${widget.customer.customerId}",
                      style: TextStyle(fontSize: smallSize, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Permanent Chips Row (Uses Wrap so it doesn't overflow)
          Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPillBadge(
                widget.customer.account ? "Account" : "Cash", 
                Colors.green, 
                widget.customer.account
              ),
              _buildPillBadge(
                _getGradeLabel(widget.customer.grade), 
                Colors.blue, 
                true // Always active for visibility
              ),
              _buildPillBadge(
                widget.customer.overseas ? "Overseas" : "Local", 
                Colors.orange, 
                widget.customer.overseas
              ),
              _buildPillBadge(
                widget.customer.status ? "Status" : "Non-Status",
                widget.customer.status ? Colors.green : Colors.amber,
                true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          
          // Quick Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.phone_outlined, "Call", () {
                final String resolvedNumber = widget.customer.phone.trim().isNotEmpty
                    ? widget.customer.phone
                    : widget.customer.mobile;
                _dialNumber(resolvedNumber);
              }),
              _buildActionButton(Icons.email_outlined, "Email", () {
                _emailTo(widget.customer.email);
              }),
              _buildActionButton(Icons.edit, "Edit", () {
                // TODO: wire email edit flow
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text, MaterialColor themeColor, bool isActive) {
    final double badgeSize = _font(context, 11);
    // If not active, it falls back to a muted grey styling
    final bgColor = isActive ? themeColor[50] : Colors.grey[100];
    final textColor = isActive ? themeColor[700] : Colors.grey[600];
    final borderColor = isActive ? themeColor[200] : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor!, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: badgeSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    final double baseSize = _font(context, 14);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey[800]),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: baseSize,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetailsCard() {
    return _buildSectionCard(
      title: "Contact Details",
      children: [
        _buildIconDataRow(Icons.phone_outlined, "Phone", widget.customer.phone),
        _buildIconDataRow(Icons.phone_iphone_outlined, "Mobile", widget.customer.mobile),
        _buildIconDataRow(Icons.email_outlined, "Email", widget.customer.email),
        _buildIconDataRow(Icons.print_outlined, "Fax", widget.customer.fax),
      ],
    );
  }

  Widget _buildAddressCard() {
    final double baseSize = _font(context, 14);
    final List<String> primaryAddressParts = [
      widget.customer.addr1,
      widget.customer.addr2,
      widget.customer.addr3,
      "${widget.customer.suburb} ${widget.customer.state} ${widget.customer.postcode}".trim(),
      widget.customer.country,
    ].where((s) => s.isNotEmpty).toList();

    String primaryAddressStr = primaryAddressParts.join('\n');
    final String primaryAddressQuery = primaryAddressParts.join(', ');

    if (primaryAddressStr.isEmpty) primaryAddressStr = "No primary address provided.";

    return _buildSectionCard(
      title: "Addresses",
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.business_outlined, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                primaryAddressStr,
                style: TextStyle(
                  fontSize: baseSize,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            InkWell(
              onTap: () => _openMapForAddress(primaryAddressQuery),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map, color: Colors.redAccent),
              ),
            ),
          ],
        ),
        if (widget.customer.addresses.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          InkWell(
            onTap: () => _showSecondaryAddressesDialog(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Secondary Addresses",
                  style: TextStyle(
                    fontSize: baseSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "View All Addr",
                      style: TextStyle(
                        fontSize: baseSize,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildFinancialCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return _buildSectionCard(
      title: "Financial & Account",
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Credit Limit",
                    style: TextStyle(fontSize: smallSize, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "\$${widget.customer.limit.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: baseSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment Terms",
                    style: TextStyle(fontSize: smallSize, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${widget.customer.days} Days ${widget.customer.fromEOM ? 'EOM' : ''}",
                    style: TextStyle(
                      fontSize: baseSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<StaffDetailBloc, StaffDetailState>(
          builder: (context, state) {
            String openedBy = "-";
            String ownerAccount = "-";

            if (state is StaffDetailLoading) {
              openedBy = "Loading...";
              ownerAccount = "Loading...";
            } else if (state is StaffDetailLoaded) {
              openedBy = _formatStaffDisplay(state.openedBy);
              ownerAccount = _formatStaffDisplay(state.ownerAccount);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Opened By",
                        style: TextStyle(
                          fontSize: smallSize,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        openedBy,
                        style: TextStyle(
                          fontSize: baseSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Owner Account",
                        style: TextStyle(
                          fontSize: smallSize,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ownerAccount,
                        style: TextStyle(
                          fontSize: baseSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonalCard() {
    return _buildSectionCard(
      title: "Personal Details",
      children: [
        _buildDataRow("Salutation", widget.customer.salutation),
        _buildDataRow("Given Names", widget.customer.givenNames),
        _buildDataRow("Surname", widget.customer.surname),
        _buildDataRow("Position", widget.customer.position),
      ],
    );
  }

  String _defaultDeliveryAddressLabel() {
    final int defaultId = widget.customer.defaultDeliveryAddress;
    if (defaultId == 0 || defaultId == 1) return 'Addr1';
    if (defaultId == 2) return 'Addr2';
    if (defaultId == 3) return 'Addr3';
    return '-';
  }

  String _documentDeliveryLabel() {
    switch (widget.customer.documentDeliveryType) {
      case 0:
        return 'Print';
      case 1:
        return 'Email';
      case 2:
        return 'Print & Email';
      default:
        return '-';
    }
  }
  
  Widget _buildAdditionalInfoCard() {
    return _buildSectionCard(
      title: "Additional Info",
      children: [
        _buildDataRow("ABN", widget.customer.abn.isEmpty ? "-" : widget.customer.abn),
        _buildDataRow("Default Delivery", _defaultDeliveryAddressLabel()),
        _buildDataRow("Documents", _documentDeliveryLabel()),
        _buildDataRow("Custom 1", widget.customer.custom1),
        _buildDataRow("Custom 2", widget.customer.custom2),
      ],
    );
  }

  Widget _buildNotesCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return _buildSectionCard(
      title: "Notes & Comments",
      children: [
        if (widget.customer.notes.isNotEmpty) ...[
          Text(
            "Internal Notes:",
            style: TextStyle(
              fontSize: smallSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.notes,
            style: TextStyle(fontSize: baseSize, color: Colors.black87),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.customer.comments.isNotEmpty) ...[
          Text(
            "Comments:",
            style: TextStyle(
              fontSize: smallSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.comments,
            style: TextStyle(fontSize: baseSize, color: Colors.black87),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return _buildBaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Metadata",
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Created: ${_formatDate(widget.customer.dateCreated)}",
                style: TextStyle(fontSize: smallSize, color: Colors.grey[600]),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 22), 
              Text(
                "Modified: ${_formatDate(widget.customer.dateModified)}",
                style: TextStyle(fontSize: smallSize, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sub-components ---

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    final double baseSize = _font(context, 14);
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Icon(Icons.edit, size: 16, color: kPrimaryColor), 
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBaseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F0),
        borderRadius: BorderRadius.circular(12),
        // Adding a subtle stroke to give that "solid card" look from modern UI
        border: Border.all(color: const Color(0xFFC9B9A6), width: 0.57), 
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B2012).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconDataRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: baseSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: TextStyle(fontSize: baseSize, color: Colors.blue),
              textAlign: TextAlign.right,
            ), 
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataRow(String label, String value) {
     if (value.isEmpty) return const SizedBox.shrink();
      final double baseSize = _font(context, 14);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                value,
                style: TextStyle(fontSize: baseSize, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
  }
}