import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';

import '../../../../constants/colors.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});

  final CustomerVO customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kSecondaryColor,
        elevation: 0,
        title: const Text(
          'Customer Details',
          style: TextStyle(color: kThirdColor, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kThirdColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection('Contact Information', [
              _buildInfoRow('Email', widget.customer.email),
              _buildInfoRow('Phone', widget.customer.phone),
              _buildInfoRow('Mobile', widget.customer.mobile),
              _buildInfoRow('Fax', widget.customer.fax),
            ]),
            const SizedBox(height: 16),
            _buildSection('Personal Information', [
              _buildInfoRow('Salutation', widget.customer.salutation),
              _buildInfoRow('Given Names', widget.customer.givenNames),
              _buildInfoRow('Surname', widget.customer.surname),
              _buildInfoRow('Position', widget.customer.position),
              _buildInfoRow('Company', widget.customer.company),
            ]),
            const SizedBox(height: 16),
            _buildSection('Address', [
              _buildInfoRow('Address 1', widget.customer.addr1),
              _buildInfoRow('Address 2', widget.customer.addr2),
              _buildInfoRow('Address 3', widget.customer.addr3),
              _buildInfoRow('Suburb', widget.customer.suburb),
              _buildInfoRow('State', widget.customer.state),
              _buildInfoRow('Postcode', widget.customer.postcode),
              _buildInfoRow('Country', widget.customer.country),
            ]),
            const SizedBox(height: 16),
            _buildSection('Account Information', [
              _buildInfoRow('Account', widget.customer.account ? 'Yes' : 'No'),
              _buildInfoRow('Barcode', widget.customer.barcode),
              _buildInfoRow('Credit Limit', '\$${widget.customer.limit.toStringAsFixed(2)}'),
              _buildInfoRow('Payment Days', widget.customer.days.toString()),
              _buildInfoRow('From EOM', widget.customer.fromEOM ? 'Yes' : 'No'),
              _buildInfoRow('ABN', widget.customer.abn),
              _buildInfoRow('Status', widget.customer.inactive ? 'Inactive' : 'Active'),
            ]),
            const SizedBox(height: 16),
            _buildSection('Additional Information', [
              _buildInfoRow('Grade', widget.customer.grade.toString()),
              _buildInfoRow('Custom 1', widget.customer.custom1),
              _buildInfoRow('Custom 2', widget.customer.custom2),
              _buildInfoRow('Overseas', widget.customer.overseas ? 'Yes' : 'No'),
              _buildInfoRow('External', widget.customer.external ? 'Yes' : 'No'),
              _buildInfoRow('Date Created', widget.customer.dateCreated),
              _buildInfoRow('Date Modified', widget.customer.dateModified),
            ]),
            if (widget.customer.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection('Notes', [
                _buildNotesField(widget.customer.notes),
              ]),
            ],
            if (widget.customer.comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection('Comments', [
                _buildNotesField(widget.customer.comments),
              ]),
            ],
            if (widget.customer.addresses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAddressesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.customer.surname.isNotEmpty
                    ? widget.customer.surname[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.customer.customerId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: kSecondaryColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kThirdColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGreyColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: kThirdColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: kThirdColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAddressesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kThirdColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Addresses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const Divider(height: 20),
          ...widget.customer.addresses.map((address) {
            final isDefault = address.addressNumber == widget.customer.defaultDeliveryAddress;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDefault ? kPrimaryColor.withOpacity(0.05) : kBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDefault ? kPrimaryColor : kGreyColor.withOpacity(0.2),
                  width: isDefault ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Address ${address.addressNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDefault ? kPrimaryColor : kThirdColor,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (address.addr1.isNotEmpty)
                    Text(address.addr1, style: const TextStyle(fontSize: 13)),
                  if (address.addr2.isNotEmpty)
                    Text(address.addr2, style: const TextStyle(fontSize: 13)),
                  if (address.addr3.isNotEmpty)
                    Text(address.addr3, style: const TextStyle(fontSize: 13)),
                  if (address.suburb.isNotEmpty || address.state.isNotEmpty || address.postcode.isNotEmpty)
                    Text(
                      [address.suburb, address.state, address.postcode]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (address.country.isNotEmpty)
                    Text(address.country, style: const TextStyle(fontSize: 13)),
                  if (address.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Phone: ${address.phone}', style: const TextStyle(fontSize: 12, color: kGreyColor)),
                  ],
                  if (address.mobile.isNotEmpty)
                    Text('Mobile: ${address.mobile}', style: const TextStyle(fontSize: 12, color: kGreyColor)),
                  if (address.email.isNotEmpty)
                    Text('Email: ${address.email}', style: const TextStyle(fontSize: 12, color: kGreyColor)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
