import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';

class CustomerTransactionsScreen extends StatelessWidget {
  final CustomerVO customer;

  const CustomerTransactionsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Define the tabs based on the provided images
    final List<String> tabs = [
      "Purchases",
      "Credit",
      "Invoices",
      "IV Pay",
      "Lay-bys",
      "LB Pay",
      "CSO",
      "SO/Quote",
      "SO Pay"
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFEFF4), // Matching the deep grey background
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120.0), // Custom height for Appbar + Tabbar
          child: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: kGColor),
            ),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  customer.displayName,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              tabs: tabs.map((String name) => Tab(text: name)).toList(),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContentContainer(
              note: "Showing 20 last sold items from Non-Archived Data.",
              child: _buildPurchasesData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last credit notes from Non-Archived Data.",
              child: _buildCreditData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last invoices from Non-Archived Data.",
              child: _buildInvoicesData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last invoice payments from Non-Archived Data.",
              child: _buildIVPayData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last lay-bys from Non-Archived Data.",
              child: _buildLaybysData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last lay-by payments from Non-Archived Data.",
              child: _buildLBPayData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last customer special orders from Non-Archived Data.",
              child: _buildCSOData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last sales orders and quotes from Non-Archived Data.",
              child: _buildSOQuoteData(),
            ),
            _buildTabContentContainer(
              note: "Showing 10 last sales order payments from Non-Archived Data.",
              child: _buildSOPayData(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Wrapper for Tab Content ---
  Widget _buildTabContentContainer({required String note, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                note,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Data Table Builder ---
  Widget _buildDataTable(List<String> columns, List<List<String>> rows) {
    return DataTable(
      headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey.shade50),
      dataRowMaxHeight: 50,
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 13,
      ),
      dataTextStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 13,
      ),
      columnSpacing: 24,
      horizontalMargin: 16,
      border: TableBorder(
        horizontalInside: BorderSide(width: 1, color: Colors.grey.shade200),
      ),
      columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
      rows: rows.map((rowData) {
        return DataRow(
          cells: rowData.map((data) => DataCell(Text(data))).toList(),
        );
      }).toList(),
    );
  }

  // --- Mock Data Generators based on Images ---

  Widget _buildPurchasesData() {
    return _buildDataTable(
      ["Date*", "Product", "Qty*", "Price*"],
      [
        ["08/03/2026 14:22", "Cast Iron Skillet", "1", "\$64.00"],
        ["07/03/2026 11:05", "Saucepan Set - Non Stick", "1", "\$90.90"],
        ["05/03/2026 09:18", "Chef Knife 8\"", "2", "\$38.00"],
        ["02/03/2026 16:41", "Bamboo Cutting Board", "1", "\$22.50"],
        ["28/02/2026 13:07", "Frying Pan", "1", "\$45.45"],
        ["24/02/2026 10:52", "Stainless Pot 5L", "1", "\$78.00"],
        ["20/02/2026 15:33", "Kettle", "1", "\$90.91"],
        ["18/02/2026 10:38", "Kettle", "-1", "\$90.91"],
        ["12/02/2026 12:09", "Measuring Cups", "1", "\$12.00"],
        ["08/02/2026 17:20", "Mixing Bowl Set", "1", "\$26.00"],
      ],
    );
  }

  Widget _buildCreditData() {
    return _buildDataTable(
      ["Date*", "Credit Id*", "Source*", "Credit Type*", "Amount*"],
      [
        ["06/03/2026", "CR-1012", "INV-108", "Return", "\$32.00"],
        ["04/03/2026", "CR-1010", "INV-106", "Return", "\$18.50"],
        ["01/03/2026", "CR-1008", "INV-104", "Return", "\$45.45"],
        ["27/02/2026", "CR-1006", "Manual", "Adjustment", "\$10.00"],
        ["22/02/2026", "CR-1004", "INV-101", "Return", "\$22.00"],
        ["18/02/2026", "CR-1001", "INV-94", "Return", "\$45.45"],
        ["12/02/2026", "CR-0996", "Manual", "Adjustment", "\$15.00"],
        ["05/02/2026", "CR-0992", "INV-88", "Return", "\$30.00"],
        ["28/01/2026", "CR-0987", "Manual", "Adjustment", "\$12.50"],
        ["15/01/2026", "CR-0982", "Manual", "Adjustment", "\$10.00"],
      ],
    );
  }

  Widget _buildInvoicesData() {
    return _buildDataTable(
      ["Date", "Invoice No", "Inv Total", "Amount Owing"],
      [
        ["08/03/2026 14:22", "110", "\$64.00", "\$0.00"],
        ["07/03/2026 11:05", "109", "\$90.90", "\$90.90"],
        ["05/03/2026 09:18", "108", "\$76.00", "\$0.00"],
        ["02/03/2026 16:41", "107", "\$22.50", "\$22.50"],
        ["28/02/2026 13:07", "106", "\$45.45", "\$0.00"],
        ["24/02/2026 10:52", "105", "\$78.00", "\$78.00"],
        ["20/02/2026 15:33", "104", "\$90.91", "\$0.00"],
        ["18/02/2026 10:38", "94", "\$49.99", "\$49.99"],
        ["12/12/2025 16:08", "54", "\$100.00", "\$100.00"],
        ["12/12/2025 16:05", "50", "\$100.00", "\$0.00"],
      ],
    );
  }

  Widget _buildIVPayData() {
    return _buildDataTable(
      ["Date*", "Invoice No*", "Payment No*", "Trn*", "Discount*", "Amount Paid*"],
      [
        ["08/03/2026 14:30", "110", "12", "IP", "\$0.00", "\$64.00"],
        ["07/03/2026 11:12", "109", "11", "IP", "\$0.00", "\$45.00"],
        ["05/03/2026 09:25", "108", "10", "IP", "\$0.00", "\$76.00"],
        ["02/03/2026 16:50", "107", "9", "IP", "\$0.00", "\$22.50"],
        ["28/02/2026 13:15", "106", "8", "IP", "\$0.00", "\$45.45"],
        ["24/02/2026 11:02", "105", "7", "IP", "\$0.00", "\$30.00"],
        ["20/02/2026 15:41", "104", "6", "IP", "\$0.00", "\$90.91"],
        ["12/12/2025 16:12", "54", "5", "IP", "\$0.00", "-\$40.00"],
        ["12/12/2025 16:10", "54", "4", "IP", "\$0.00", "\$40.00"],
        ["12/12/2025 16:07", "50", "3", "IP", "\$0.00", "\$100.00"],
      ],
    );
  }

  Widget _buildLaybysData() {
    return _buildDataTable(
      ["Date", "Lay-by No", "Last Payment", "Total", "Amount Owing"],
      [
        ["06/03/2026", "LB-214", "07/03/2026", "\$820.00", "\$320.00"],
        ["01/03/2026", "LB-204", "05/03/2026", "\$500.00", "\$250.00"],
        ["25/02/2026", "LB-201", "28/02/2026", "\$220.00", "\$120.00"],
        ["14/02/2026", "LB-198", "18/02/2026", "\$160.00", "\$40.00"],
        ["05/02/2026", "LB-196", "10/02/2026", "\$90.00", "\$30.00"],
        ["22/01/2026", "LB-194", "28/01/2026", "\$140.00", "\$0.00"],
        ["08/01/2026", "LB-191", "15/01/2026", "\$260.00", "\$60.00"],
        ["15/12/2025", "LB-188", "15/12/2025", "\$120.00", "\$0.00"],
        ["02/12/2025", "LB-184", "10/12/2025", "\$340.00", "\$140.00"],
        ["20/11/2025", "LB-182", "25/11/2025", "\$80.00", "\$0.00"],
      ],
    );
  }

  Widget _buildLBPayData() {
    return _buildDataTable(
      ["Date*", "Lay-by No*", "Payment No*", "Amount Paid*", "Payment Type*"],
      [
        ["07/03/2026", "LB-214", "2", "\$250.00", "EFT"],
        ["05/03/2026", "LB-204", "1", "\$250.00", "Credit Card"],
        ["28/02/2026", "LB-201", "2", "\$60.00", "Cash"],
        ["18/02/2026", "LB-198", "3", "\$80.00", "EFT"],
        ["10/02/2026", "LB-196", "2", "\$30.00", "Cash"],
        ["28/01/2026", "LB-194", "1", "\$140.00", "Card"],
        ["15/01/2026", "LB-191", "1", "\$200.00", "Credit Card"],
        ["15/12/2025", "LB-188", "2", "\$60.00", "Cash"],
        ["15/11/2025", "LB-188", "1", "\$60.00", "Cash"],
        ["25/11/2025", "LB-182", "1", "\$80.00", "EFT"],
      ],
    );
  }

  Widget _buildCSOData() {
    return _buildDataTable(
      ["Date*", "Product", "Sell*", "Qty*", "Status*"],
      [
        ["06/03/2026", "Special Aquarium Filter", "\$150.00", "1", "Ordered"],
        ["28/02/2026", "Custom Fish Tank 50L", "\$300.00", "1", "Received"],
        ["22/02/2026", "LED Tank Light 60cm", "\$120.00", "1", "Received"],
        ["18/02/2026", "CO2 Regulator Kit", "\$210.00", "1", "Ordered"],
        ["12/02/2026", "Aquarium Heater 200W", "\$45.00", "2", "Received"],
        ["05/02/2026", "Aqua Soil 9L", "\$65.00", "1", "Backorder"],
        ["29/01/2026", "Canister Filter 1000L", "\$280.00", "1", "Ordered"],
        ["20/01/2026", "Water Test Kit", "\$35.00", "1", "Received"],
        ["12/01/2026", "Glass Cleaner", "\$12.00", "3", "Received"],
        ["05/01/2026", "Air Pump", "\$40.00", "1", "Received"],
      ],
    );
  }

  Widget _buildSOQuoteData() {
    return _buildDataTable(
      ["Date", "Sales Order No", "Type", "Status", "Total", "Owing"],
      [
        ["07/03/2026", "SO-5010", "Order", "Open", "\$920.00", "\$920.00"],
        ["02/03/2026", "SO-5002", "Order", "Open", "\$450.00", "\$450.00"],
        ["28/02/2026", "QT-8891", "Quote", "Accepted", "\$1,200.00", "\$0.00"],
        ["24/02/2026", "SO-4994", "Order", "Packed", "\$310.00", "\$0.00"],
        ["20/02/2026", "QT-8880", "Quote", "Pending", "\$680.00", "\$680.00"],
        ["14/02/2026", "SO-4986", "Order", "Shipped", "\$540.00", "\$0.00"],
        ["08/02/2026", "QT-8872", "Quote", "Accepted", "\$1,050.00", "\$0.00"],
        ["02/02/2026", "SO-4972", "Order", "Open", "\$230.00", "\$230.00"],
        ["25/01/2026", "SO-4964", "Order", "Closed", "\$410.00", "\$0.00"],
        ["18/01/2026", "QT-8859", "Quote", "Declined", "\$760.00", "\$0.00"],
      ],
    );
  }

  Widget _buildSOPayData() {
    return _buildDataTable(
      ["Date*", "Sales Order No*", "Payment No*", "Amount Paid*", "Payment Type*"],
      [
        ["07/03/2026", "SO-5010", "2", "\$300.00", "EFT"],
        ["05/03/2026", "SO-5002", "1", "\$150.00", "EFT"],
        ["24/02/2026", "SO-4994", "2", "\$310.00", "Credit Card"],
        ["20/02/2026", "SO-4986", "3", "\$140.00", "Cash"],
        ["14/02/2026", "SO-4986", "2", "\$400.00", "EFT"],
        ["08/02/2026", "SO-4972", "1", "\$230.00", "Card"],
        ["02/02/2026", "SO-4964", "2", "\$200.00", "EFT"],
        ["25/01/2026", "SO-4964", "1", "\$210.00", "Cash"],
        ["18/01/2026", "SO-4951", "1", "\$500.00", "Credit Card"],
        ["10/01/2026", "SO-4802", "1", "\$800.00", "Credit Card"],
      ],
    );
  }
}