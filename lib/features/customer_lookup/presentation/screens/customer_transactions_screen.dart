import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/theme_colors.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_transactions_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_transactions_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_transactions_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerTransactionsScreen extends StatefulWidget {
  final CustomerVO customer;

  const CustomerTransactionsScreen({super.key, required this.customer});

  @override
  State<CustomerTransactionsScreen> createState() =>
      _CustomerTransactionsScreenState();
}

class _CustomerTransactionsScreenState
    extends State<CustomerTransactionsScreen> {
  bool _showIncTax = false;
  @override
  void initState() {
    super.initState();
    context.read<CustomerTransactionsBloc>().add(
          LoadCustomerTransactionsEvent(customerId: widget.customer.customerId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
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
        backgroundColor: isDark ? colors.bg : const Color(0xFFEFEFF4),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120.0), // Custom height for Appbar + Tabbar
          child: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: isDark ? colors.heroGradient : kGColor,
              ),
            ),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? colors.onHero : Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    color: isDark ? colors.onHero : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.customer.displayName,
                  style: TextStyle(
                    color: (isDark ? colors.onHero : Colors.white)
                        .withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: isDark ? colors.onHero : Colors.white,
              indicatorWeight: 3,
              labelColor: isDark ? colors.onHero : Colors.white,
              unselectedLabelColor: (isDark ? colors.onHero : Colors.white)
                  .withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              tabs: tabs.map((String name) => Tab(text: name)).toList(),
            ),
          ),
        ),
        body: BlocBuilder<CustomerTransactionsBloc, CustomerTransactionsState>(
          builder: (context, state) {
            if (state is CustomerTransactionsLoading ||
                state is CustomerTransactionsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CustomerTransactionsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: kErrorColor, fontSize: 13),
                ),
              );
            }

            final data = state is CustomerTransactionsLoaded
                ? state.data
                : CustomerTransactionsLocalData.empty();

            return TabBarView(
              children: [
                _buildTabContentContainer(
                  note: "Showing 20 last sold items from Non-Archived Data.",
                  header: _buildPurchasesTaxToggle(),
                  child: _buildPurchasesData(data.purchases),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last credit notes from Non-Archived Data.",
                  child: _buildCreditData(data.credit),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last invoices from Non-Archived Data.",
                  child: _buildInvoicesData(data.invoices),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last invoice payments from Non-Archived Data.",
                  child: _buildIVPayData(data.ivPay),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last lay-bys from Non-Archived Data.",
                  child: _buildLaybysData(data.laybys),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last lay-by payments from Non-Archived Data.",
                  child: _buildLBPayData(data.lbPay),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last customer special orders from Non-Archived Data.",
                  child: _buildCSOData(data.cso),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last sales orders and quotes from Non-Archived Data.",
                  child: _buildSOQuoteData(data.soQuote),
                ),
                _buildTabContentContainer(
                  note: "Showing 10 last sales order payments from Non-Archived Data.",
                  child: _buildSOPayData(data.soPay),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Wrapper for Tab Content ---
  Widget _buildTabContentContainer({
    required String note,
    required Widget child,
    Widget? header,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? colors.divider : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? colors.cardShadow
                  : Colors.black.withOpacity(0.03),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                    note,
                    style: TextStyle(
                      color: isDark ? colors.onSurface : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                ),
              ),
            ),
            if (header != null) header,
              Divider(
                height: 1,
                color: isDark ? colors.divider : Colors.grey.shade200,
              ),
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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return DataTable(
      headingRowColor: MaterialStateProperty.resolveWith(
        (states) => isDark ? colors.surfaceAlt : Colors.grey.shade50,
      ),
      dataRowMaxHeight: 50,
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? colors.onSurface : Colors.black87,
        fontSize: 13,
      ),
      dataTextStyle: TextStyle(
        color: isDark ? colors.onSurfaceMuted : Colors.grey.shade800,
        fontSize: 13,
      ),
      columnSpacing: 24,
      horizontalMargin: 16,
      border: TableBorder(
        horizontalInside: BorderSide(
          width: 1,
          color: isDark ? colors.divider : Colors.grey.shade200,
        ),
      ),
      columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
      rows: rows.map((rowData) {
        return DataRow(
          cells: rowData.map((data) => DataCell(Text(data))).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildPurchasesData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Product", "Qty*", "Price*"],
        "No purchases found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Product", "Qty*", "Price*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['product']),
              _formatNumber(row['qty']),
              _formatMoney(
                _applyPurchaseTax(
                  row['price'],
                  row['goods_tax'] ?? row['goodsTax'],
                ),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildCreditData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Credit Id*", "Source*", "Credit Type*", "Amount*"],
        "No credit notes found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Credit Id*", "Source*", "Credit Type*", "Amount*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['credit_id']),
              _asString(row['source']),
              _asString(row['credit_type']),
              _formatMoney(row['amount']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildInvoicesData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date", "Invoice No", "Inv Total", "Amount Owing"],
        "No invoices found.",
      );
    }
    return _buildDataTable(
      ["Date", "Invoice No", "Inv Total", "Amount Owing"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['invoice_no']),
              _formatMoney(row['inv_total']),
              _formatMoney(row['amount_owing']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildIVPayData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Invoice No*", "Payment No*", "Trn*", "Discount*", "Amount Paid*"],
        "No invoice payments found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Invoice No*", "Payment No*", "Trn*", "Discount*", "Amount Paid*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['invoice_no']),
              _asString(row['payment_no']),
              _asString(row['trn']),
              _formatMoney(row['discount']),
              _formatMoney(row['amount_paid']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildLaybysData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date", "Lay-by No", "Last Payment", "Total", "Amount Owing"],
        "No lay-bys found.",
      );
    }
    return _buildDataTable(
      ["Date", "Lay-by No", "Last Payment", "Total", "Amount Owing"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['layby_no']),
              _formatDate(row['last_payment']),
              _formatMoney(row['total']),
              _formatMoney(row['amount_owing']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildLBPayData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Lay-by No*", "Payment No*", "Amount Paid*", "Payment Type*"],
        "No lay-by payments found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Lay-by No*", "Payment No*", "Amount Paid*", "Payment Type*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['layby_no']),
              _asString(row['payment_no']),
              _formatMoney(row['amount_paid']),
              _asString(row['payment_type']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildCSOData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Product", "Sell*", "Qty*", "Status*"],
        "No customer special orders found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Product", "Sell*", "Qty*", "Status*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['product']),
              _formatMoney(row['sell']),
              _formatNumber(row['qty']),
              _asString(row['status']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildSOQuoteData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date", "Sales Order No", "Type", "Status", "Total", "Owing"],
        "No sales orders or quotes found.",
      );
    }
    return _buildDataTable(
      ["Date", "Sales Order No", "Type", "Status", "Total", "Owing"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['sales_order_no']),
              _asString(row['type']),
              _asString(row['status']),
              _formatMoney(row['total']),
              _formatMoney(row['owing']),
            ],
          )
          .toList(),
    );
  }

  Widget _buildSOPayData(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyTable(
        ["Date*", "Sales Order No*", "Payment No*", "Amount Paid*", "Payment Type*"],
        "No sales order payments found.",
      );
    }
    return _buildDataTable(
      ["Date*", "Sales Order No*", "Payment No*", "Amount Paid*", "Payment Type*"],
      items
          .map(
            (row) => [
              _formatDate(row['date']),
              _asString(row['sales_order_no']),
              _asString(row['payment_no']),
              _formatMoney(row['amount_paid']),
              _asString(row['payment_type']),
            ],
          )
          .toList(),
    );
  }

  String _asString(Object? value) {
    if (value == null) return "-";
    final text = value.toString();
    return text.trim().isEmpty ? "-" : text;
  }

  String _formatDate(Object? value) {
    if (value == null) return "-";
    final raw = value.toString();
    if (raw.trim().isEmpty) return "-";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  String _formatMoney(Object? value) {
    if (value == null) return "-";
    final num? parsed = value is num ? value : num.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(parsed);
  }

  String _formatNumber(Object? value) {
    if (value == null) return "-";
    final num? parsed = value is num ? value : num.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed % 1 == 0) return parsed.toInt().toString();
    return parsed.toStringAsFixed(2);
  }

  num _applyPurchaseTax(Object? price, Object? goodsTax) {
    final num? parsed = price is num ? price : num.tryParse(price.toString());
    if (parsed == null) return 0;
    if (!_showIncTax) return parsed;
    final String taxCode = (goodsTax ?? "").toString().toUpperCase();
    if (taxCode != "GST") return parsed;
    return parsed * 1.1;
  }

  Widget _buildPurchasesTaxToggle() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? colors.divider : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            _buildTaxOption(
              label: "Ex Tax",
              value: false,
              isDark: isDark,
              colors: colors,
            ),
            const SizedBox(width: 6),
            _buildTaxOption(
              label: "Inc Tax",
              value: true,
              isDark: isDark,
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxOption({
    required String label,
    required bool value,
    required bool isDark,
    required AppThemeColors colors,
  }) {
    final bool selected = _showIncTax == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _showIncTax = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? colors.surface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<bool>(
                value: value,
                groupValue: _showIncTax,
                onChanged: (next) {
                  if (next == null) return;
                  setState(() {
                    _showIncTax = next;
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: kPrimaryColor,
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? colors.onSurface : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTable(List<String> columns, String message) {
    final emptyRow = List<String>.generate(
      columns.length,
      (index) => index == 0 ? message : "-",
    );
    return _buildDataTable(columns, [emptyRow]);
  }
}