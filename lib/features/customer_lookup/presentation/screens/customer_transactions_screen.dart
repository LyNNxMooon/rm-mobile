import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
import 'package:rmmobile/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_states.dart';
import 'package:rmmobile/utils/formatting_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerTransactionsScreen extends StatefulWidget {
  final CustomerVO customer;

  const CustomerTransactionsScreen({super.key, required this.customer});

  @override
  State<CustomerTransactionsScreen> createState() =>
      _CustomerTransactionsScreenState();
}

class _CustomerTransactionsScreenState
    extends State<CustomerTransactionsScreen> with SingleTickerProviderStateMixin {
  bool _showIncTax = false;
  late TabController _tabController;
  int _selectedPageSize = 500;
  final List<int> _pageSizeOptions = [500, 1000, 3000, 5000];
  
  // Track which tabs have been loaded
  final Set<int> _loadedTabs = {0}; // Tab 0 (Purchases) is loaded on init
  
  // Pagination: current page per transaction type
  final Map<String, int> _currentPage = {
    'purchase': 1,
    'credit': 1,
    'invoice': 1,
    'ivpay': 1,
    'layby': 1,
    'lbpay': 1,
    'cso': 1,
    'soquote': 1,
    'sopay': 1,
  };
  
  // Map tab index to transaction type
  static const List<String> _transactionTypes = [
    'purchase',
    'credit',
    'invoice',
    'ivpay',
    'layby',
    'lbpay',
    'cso',
    'soquote',
    'sopay',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<CustomerTransactionsBloc>().add(
          LoadCustomerTransactionsEvent(customerId: widget.customer.customerId),
        );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final tabIndex = _tabController.index;
    
    // Only fetch if this tab hasn't been loaded yet
    if (!_loadedTabs.contains(tabIndex)) {
      _loadedTabs.add(tabIndex);
      context.read<CustomerTransactionsBloc>().add(
        LoadTransactionTypeEvent(
          customerId: widget.customer.customerId,
          transactionType: _transactionTypes[tabIndex],
          pageSize: _selectedPageSize,
        ),
      );
    }
  }

  void _onPageSizeChanged(int? newPageSize) {
    if (newPageSize == null || newPageSize == _selectedPageSize) return;
    
    setState(() {
      _selectedPageSize = newPageSize;
      // Reset all pages when page size changes
      _currentPage.updateAll((key, value) => 1);
    });
    
    // Refresh current tab with new page size
    final currentTabIndex = _tabController.index;
    context.read<CustomerTransactionsBloc>().add(
      UpdatePageSizeEvent(
        customerId: widget.customer.customerId,
        transactionType: _transactionTypes[currentTabIndex],
        pageSize: newPageSize,
      ),
    );
  }

  void _goToNextPage(String transactionType, int? cursor) {
    if (cursor == null) return;
    
    setState(() {
      _currentPage[transactionType] = _currentPage[transactionType]! + 1;
    });
    
    // Fetch next page from API using cursor
    context.read<CustomerTransactionsBloc>().add(
      LoadNextPageEvent(
        customerId: widget.customer.customerId,
        transactionType: transactionType,
        pageSize: _selectedPageSize,
        cursor: cursor,
      ),
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

    return Scaffold(
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
              color: isDark ? Colors.white : Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.customer.displayName,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.white).withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Page Size Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: DropdownButton<int>(
                  value: _selectedPageSize,
                  dropdownColor: isDark ? colors.surfaceAlt : Colors.white,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  underline: const SizedBox(),
                  isDense: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: _onPageSizeChanged,
                  items: _pageSizeOptions.map((int size) {
                    return DropdownMenuItem<int>(
                      value: size,
                      child: Text(
                        '$size',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                    return _pageSizeOptions.map((int size) {
                      return Center(
                        child: Text(
                          '$size',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: isDark ? Colors.white : Colors.white,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : Colors.white,
            unselectedLabelColor: (isDark ? Colors.white : Colors.white)
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

          CustomerTransactionsLocalData data;
          String? loadingType;
          
          if (state is CustomerTransactionsLoaded) {
            data = state.data;
          } else if (state is TransactionTypeLoading) {
            data = state.data;
            loadingType = state.loadingType;
          } else {
            data = CustomerTransactionsLocalData.empty();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContentContainer(
                transactionType: 'purchase',
                totalItems: data.purchases.length,
                typeLabel: 'sold items',
                pagination: data.getPagination('purchase'),
                header: _buildPurchasesTaxToggle(),
                child: _buildPurchasesData(data.purchases),
                isLoading: loadingType == 'purchase',
              ),
              _buildTabContentContainer(
                transactionType: 'credit',
                totalItems: data.credit.length,
                typeLabel: 'credit notes',
                pagination: data.getPagination('credit'),
                child: _buildCreditData(data.credit),
                isLoading: loadingType == 'credit',
              ),
              _buildTabContentContainer(
                transactionType: 'invoice',
                totalItems: data.invoices.length,
                typeLabel: 'invoices',
                pagination: data.getPagination('invoice'),
                child: _buildInvoicesData(data.invoices),
                isLoading: loadingType == 'invoice',
              ),
              _buildTabContentContainer(
                transactionType: 'ivpay',
                totalItems: data.ivPay.length,
                typeLabel: 'invoice payments',
                pagination: data.getPagination('ivpay'),
                child: _buildIVPayData(data.ivPay),
                isLoading: loadingType == 'ivpay',
              ),
              _buildTabContentContainer(
                transactionType: 'layby',
                totalItems: data.laybys.length,
                typeLabel: 'lay-bys',
                pagination: data.getPagination('layby'),
                child: _buildLaybysData(data.laybys),
                isLoading: loadingType == 'layby',
              ),
              _buildTabContentContainer(
                transactionType: 'lbpay',
                totalItems: data.lbPay.length,
                typeLabel: 'lay-by payments',
                pagination: data.getPagination('lbpay'),
                child: _buildLBPayData(data.lbPay),
                isLoading: loadingType == 'lbpay',
              ),
              _buildTabContentContainer(
                transactionType: 'cso',
                totalItems: data.cso.length,
                typeLabel: 'customer special orders',
                pagination: data.getPagination('cso'),
                child: _buildCSOData(data.cso),
                isLoading: loadingType == 'cso',
              ),
              _buildTabContentContainer(
                transactionType: 'soquote',
                totalItems: data.soQuote.length,
                typeLabel: 'sales orders/quotes',
                pagination: data.getPagination('soquote'),
                child: _buildSOQuoteData(data.soQuote),
                isLoading: loadingType == 'soquote',
              ),
              _buildTabContentContainer(
                transactionType: 'sopay',
                totalItems: data.soPay.length,
                typeLabel: 'SO payments',
                pagination: data.getPagination('sopay'),
                child: _buildSOPayData(data.soPay),
                isLoading: loadingType == 'sopay',
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Wrapper for Tab Content ---
  Widget _buildTabContentContainer({
    required String transactionType,
    required int totalItems,
    required String typeLabel,
    required TransactionPaginationInfo pagination,
    required Widget child,
    Widget? header,
    bool isLoading = false,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    
    final currentPage = _currentPage[transactionType] ?? 1;
    // Use hasMore from API response
    final hasMore = pagination.hasMore;
    
    final noteText = "Showing up to $totalItems $typeLabel from Non-Archived data.";
    
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomSafeArea),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceAlt : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            width: 1,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          noteText,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white70 : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Pagination controls - always show
                  _buildPaginationControls(
                    transactionType: transactionType,
                    currentPage: currentPage,
                    hasMore: hasMore,
                    nextCursor: pagination.nextCursor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            if (header != null) header,
              Divider(
                height: 1,
                color: isDark ? Colors.white24 : Colors.grey.shade200,
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

  Widget _buildPaginationControls({
    required String transactionType,
    required int currentPage,
    required bool hasMore,
    required int? nextCursor,
    required bool isDark,
  }) {
    final canGoNext = hasMore && nextCursor != null;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous button (always disabled - data already in local DB)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Icons.chevron_left,
              size: 18,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
          // Page indicator - just show current page number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              '$currentPage',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Next button
          InkWell(
            onTap: canGoNext ? () => _goToNextPage(transactionType, nextCursor) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: canGoNext
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white24 : Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Data Table Builder ---
  Widget _buildDataTable(List<String> columns, List<List<String>> rows) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return DataTable(
      headingRowColor: MaterialStateProperty.resolveWith(
        (states) =>
            isDark ? colors.surfaceAlt.withOpacity(0.9) : Colors.grey.shade50,
      ),
      dataRowMinHeight: isDark ? 44 : 48,
      dataRowMaxHeight: isDark ? 44 : 50,
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      dataTextStyle: TextStyle(
        color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey.shade800,
        fontSize: 13,
      ),
      dataRowColor: isDark
          ? MaterialStateProperty.resolveWith(
              (states) => colors.surface.withOpacity(0.06),
            )
          : null,
      columnSpacing: 24,
      horizontalMargin: 16,
      border: TableBorder(
        horizontalInside: BorderSide(
          width: isDark ? 0.1 : 1,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
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
                _showIncTax ? (row['price_inc'] ?? row['price']) : row['price'],
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
              _asString(row['salesorder_no']),
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
              _asString(row['salesorder_no']),
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
    return FormattingUtils.formatCurrencyWithDecimals(parsed.toDouble(), 2);
  }

  String _formatNumber(Object? value) {
    if (value == null) return "-";
    final num? parsed = value is num ? value : num.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed % 1 == 0) return parsed.toInt().toString();
    return parsed.toStringAsFixed(2);
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
            color: isDark ? Colors.white38 : Colors.grey.shade300,
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
                  color: isDark ? Colors.white : Colors.black87,
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