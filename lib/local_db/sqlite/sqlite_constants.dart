const dbName = 'rm-mobile.db';

const stocksTableCreationQuery = '''
  CREATE TABLE Stocks (
    stock_id REAL,
    shopfront TEXT,
    Barcode TEXT,
    description TEXT,
    dept_name TEXT,
    dept_id INTEGER,
    custom1 TEXT,
    custom2 TEXT,
    longdesc TEXT,
    supplier TEXT,
    cat1 TEXT,
    cat2 TEXT,
    cat3 TEXT, 
    cost REAL,
    sell REAL,
    inactive INTEGER,
    quantity REAL,
    layby_qty REAL,
    salesorder_qty REAL,
    date_created TEXT,
    order_threshold REAL,
    order_quantity REAL,
    allow_fractions INTEGER,
    package INTEGER,
    static_quantity INTEGER,
    picture_file_name TEXT,
    imageUrl TEXT,
    goods_tax TEXT,
    sales_tax TEXT,
    sales_prompt TEXT,
    date_modified TEXT,
    freight INTEGER,
    tare_weight REAL,
    unitof_measure REAL,
    weighted INTEGER,
    track_serial INTEGER,
    last_sale_date TEXT,
    allow_renaming INTEGER,
    pricing_rules TEXT,
    is_package INTEGER,
    package_components TEXT,
    cost_ex REAL,
    cost_inc REAL,
    sell_ex REAL,
    sell_inc REAL,
    pricing_grades_stock TEXT,
    pricing_grades_categories TEXT,
    pricing_grades_global TEXT,
    is_on_promotion INTEGER,
    promotion TEXT,
    serial_numbers TEXT,
    PRIMARY KEY (stock_id, shopfront)
  )
''';

const stocktakeTableCreationQuery = '''
  CREATE TABLE Stocktake (
    stock_id INTEGER, 
    shopfront TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    inStock INTEGER NOT NULL,
    stocktake_date TEXT NOT NULL,
    date_modified TEXT NOT NULL,
    description TEXT NOT NULL,
    barcode TEXT NOT NULL,
    PRIMARY KEY (stock_id, shopfront)
  )
''';

const appConfigTableCreationQuery = '''
          CREATE TABLE AppConfig (
            key TEXT PRIMARY KEY, 
            value TEXT
          )
        ''';

const networkCredentialsTableCreationQuery = '''
  CREATE TABLE NetworkCredentials (
    ip_address TEXT PRIMARY KEY, 
    is_auth_required INTEGER DEFAULT 0,
    username TEXT, 
    password TEXT
  )
''';

const savedPathsTableCreationQuery = '''
  CREATE TABLE SavedNetworkPaths (
    path TEXT PRIMARY KEY,
    added_at INTEGER,
    shopfront TEXT,
    host_name TEXT
  )
''';

const stocktakeHistorySessionCreationQuery = '''
CREATE TABLE StocktakeHistorySession (
  session_id TEXT PRIMARY KEY,
  shopfront TEXT NOT NULL,
  mobile_device_id TEXT NOT NULL,
  mobile_device_name TEXT NOT NULL,
  total_stocks INTEGER NOT NULL,
  date_started TEXT NOT NULL,
  date_ended TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''';

const stocktakeHistoryItemsCreationQuery = '''
CREATE TABLE StocktakeHistoryItems (
  session_id TEXT NOT NULL,
  stock_id INTEGER NOT NULL,
  shopfront TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  inStock INTEGER NOT NULL,
  stocktake_date TEXT NOT NULL,
  date_modified TEXT NOT NULL,
  description TEXT NOT NULL,
  barcode TEXT NOT NULL,
  PRIMARY KEY (session_id, stock_id, shopfront),
  FOREIGN KEY (session_id) REFERENCES StocktakeHistorySession(session_id)
)
''';

const String kHistoryRetentionDaysKey = "history_retention_days";
const String kHistoryLastCleanupKey = "history_last_cleanup_utc";
const String kHostIpAddressKey = "host_ip_address";
const String kHostPortKey = "host_port";
const String kApiKey = "api_key";
const String kHostNameKey = "host_name";
const String kShopfrontIdKey = "shopfront_id";
const String kRMVersionKey = "rm_version";
const String kShopfrontReminderKey = "shopfront_reminder";
const String kCustomerMaxIdPrefix = "customer_max_id_";
const String kShopfrontNameKey = "shopfront_name";
const String kDeviceIdKey = "device_id";
const String kSecurityEnabledKey = "security_enabled";
const String kStaffIdKey = "staff_id";
const String kStaffNoKey = "staff_no";
const String kStaffPasswordKey = "staff_password";
const String kStaffNameKey = "staff_name";
const String kStaffGroupIdsKey = "staff_group_ids_json";
const String kStaffGroupNamesKey = "staff_group_names_json";
const String kStaffGrantedPermissionsKey = "staff_granted_permissions_json";
const String kStaffRestrictedPermissionsKey =
    "staff_restricted_permissions_json";
const String kWelcomeSeenKey = "welcome_seen";
const String kTermsAcceptedKey = "terms_accepted";
const String kSalesScanIndividualUnitsKey = "sales_scan_individual_units";
const String kSalesSkipSellPriceKey = "sales_skip_sell_price";
const String kSalesOneDisplayLinePerItemKey =
  "sales_one_display_line_per_item";
const String kSalesPromptForEmailKey = "sales_prompt_for_email";
const String kSalesAutoRemindLowStockKey = "sales_auto_remind_low_stock";
const String kSalesPreventAddIfNoStockKey = "sales_prevent_add_if_no_stock";
const String kSalesPreventFinaliseIfOutOfStockKey = "sales_prevent_finalise_if_out_of_stock";
const String kSalesDisplayCustomerMessagesKey = "sales_display_customer_messages";
const String kSalesScanIndividualUnitsForFractionalKey = "sales_scan_individual_units_for_fractional";
const String kSalesPromptScanIndividualFractionalKey = "sales_prompt_scan_individual_fractional";
const String kSalesIsCompactViewKey = "sales_is_compact_view";
const String kSalesHideBarcodeKey = "sales_hide_barcode";
const String kSalesHideCategoriesKey = "sales_hide_categories";
const String kSalesHideTaxCodeKey = "sales_hide_tax_code";
const String kSalesFinaliseButtonOnRightKey = "sales_finalise_button_on_right";
const String kSalesFinaliseInMenuKey = "sales_finalise_in_menu";
const String kAutoRemindServerConnectionKey = "auto_remind_server_connection";

const customersTableCreationQuery = '''
  CREATE TABLE Customers (
    customer_id INTEGER,
    shopfront TEXT,
    barcode TEXT,
    grade INTEGER,
    notes TEXT,
    comments TEXT,
    status INTEGER,
    custom1 TEXT,
    custom2 TEXT,
    inactive INTEGER,
    date_modified TEXT,
    surname TEXT,
    given_names TEXT,
    position TEXT,
    company TEXT,
    salutation TEXT,
    account INTEGER,
    opened_id INTEGER,
    owner_id INTEGER,
    "limit" REAL,
    days INTEGER,
    from_eom INTEGER,
    addr1 TEXT,
    addr2 TEXT,
    addr3 TEXT,
    suburb TEXT,
    state TEXT,
    postcode TEXT,
    country TEXT,
    phone TEXT,
    fax TEXT,
    mobile TEXT,
    email TEXT,
    abn TEXT,
    overseas INTEGER,
    external INTEGER,
    date_created TEXT,
    is_barcode_printed INTEGER,
    document_delivery_type INTEGER,
    group_email_exclusion_id INTEGER,
    default_delivery_address INTEGER,
    PRIMARY KEY (customer_id, shopfront)
  )
''';

const customerAddressesTableCreationQuery = '''
  CREATE TABLE CustomerAddresses (
    address_id INTEGER,
    customer_id INTEGER,
    shopfront TEXT,
    address_number INTEGER,
    addr1 TEXT,
    addr2 TEXT,
    addr3 TEXT,
    suburb TEXT,
    state TEXT,
    postcode TEXT,
    country TEXT,
    phone TEXT,
    fax TEXT,
    mobile TEXT,
    email TEXT,
    PRIMARY KEY (address_id, customer_id, shopfront)
  )
''';

const customerPurchasesTableCreationQuery = '''
  CREATE TABLE CustomerPurchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    docket_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    product TEXT,
    qty REAL,
    price REAL,
    price_inc REAL,
    stock_id INTEGER,
    goods_tax TEXT
  )
''';

const customerCreditTableCreationQuery = '''
  CREATE TABLE CustomerCredit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    credit_id INTEGER,
    source INTEGER,
    credit_type TEXT,
    amount REAL
  )
''';

const customerInvoicesTableCreationQuery = '''
  CREATE TABLE CustomerInvoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    invoice_no INTEGER,
    inv_total REAL,
    amount_owing REAL
  )
''';

const customerIvPayTableCreationQuery = '''
  CREATE TABLE CustomerIvPay (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    invoice_no INTEGER,
    payment_no INTEGER,
    trn TEXT,
    discount REAL,
    amount_paid REAL
  )
''';

const customerLaybysTableCreationQuery = '''
  CREATE TABLE CustomerLaybys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    layby_no INTEGER,
    last_payment TEXT,
    total REAL,
    amount_owing REAL
  )
''';

const customerLbPayTableCreationQuery = '''
  CREATE TABLE CustomerLbPay (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    layby_no INTEGER,
    payment_no INTEGER,
    amount_paid REAL,
    payment_type TEXT
  )
''';

const customerCsoTableCreationQuery = '''
  CREATE TABLE CustomerCso (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    product TEXT,
    sell REAL,
    qty REAL,
    status TEXT,
    stock_id INTEGER
  )
''';

const customerSoQuoteTableCreationQuery = '''
  CREATE TABLE CustomerSoQuote (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    salesorder_no INTEGER,
    type TEXT,
    status TEXT,
    total REAL,
    owing REAL
  )
''';

const customerSoPayTableCreationQuery = '''
  CREATE TABLE CustomerSoPay (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id INTEGER,
    customer_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    date TEXT,
    salesorder_no INTEGER,
    payment_no INTEGER,
    amount_paid REAL,
    payment_type TEXT
  )
''';

const pendingStockUpdatesTableCreationQuery = '''
  CREATE TABLE PendingStockUpdates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shopfront TEXT NOT NULL,
    stock_id INTEGER NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    has_conflict INTEGER NOT NULL DEFAULT 0,
    error_message TEXT
  )
''';

const pendingCustomerUpdatesTableCreationQuery = '''
  CREATE TABLE PendingCustomerUpdates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shopfront TEXT NOT NULL,
    customer_id INTEGER NOT NULL,
    action TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    has_conflict INTEGER NOT NULL DEFAULT 0,
    error_message TEXT
  )
''';

const pendingCustomerUpdateAddressesTableCreationQuery = '''
  CREATE TABLE pending_customer_update_addresses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pending_update_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    customer_id INTEGER NOT NULL,
    address_id INTEGER NOT NULL,
    address_number INTEGER NOT NULL,
    addr1 TEXT,
    addr2 TEXT,
    addr3 TEXT,
    suburb TEXT,
    state TEXT,
    postcode TEXT,
    country TEXT,
    phone TEXT,
    fax TEXT,
    mobile TEXT,
    email TEXT
  )
''';

const pendingCustomerCreationsTableCreationQuery = '''
  CREATE TABLE PendingCustomerCreations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shopfront TEXT NOT NULL,
    customer_id INTEGER NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    error_message TEXT
  )
''';

const pendingCustomerCreationAddressesTableCreationQuery = '''
  CREATE TABLE pending_customer_creation_addresses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pending_creation_id INTEGER NOT NULL,
    shopfront TEXT NOT NULL,
    customer_id INTEGER NOT NULL,
    address_id INTEGER NOT NULL,
    address_number INTEGER NOT NULL,
    addr1 TEXT,
    addr2 TEXT,
    addr3 TEXT,
    suburb TEXT,
    state TEXT,
    postcode TEXT,
    country TEXT,
    phone TEXT,
    fax TEXT,
    mobile TEXT,
    email TEXT
  )
''';

const saleSessionsTableCreationQuery = '''
  CREATE TABLE SaleSessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_type TEXT NOT NULL,
    shopfront TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    cart_items_json TEXT,
    customer_id INTEGER,
    customer_barcode TEXT,
    customer_name TEXT,
    staff_id INTEGER,
    subtotal REAL DEFAULT 0,
    discount REAL DEFAULT 0,
    total_inc REAL DEFAULT 0,
    total_ex REAL DEFAULT 0,
    total_gp REAL DEFAULT 0,
    payment_amounts_json TEXT,
    survey_value TEXT,
    comment_value TEXT,
    drawer TEXT,
    delivery_address_json TEXT,
    email_audit_json TEXT
  )
''';

const taxCodesTableCreationQuery = '''
  CREATE TABLE TaxCodes (
    code TEXT NOT NULL,
    shopfront TEXT NOT NULL,
    export_code TEXT NOT NULL,
    description TEXT NOT NULL,
    percentage REAL NOT NULL,
    tax_type INTEGER NOT NULL,
    sales_ac TEXT,
    goods_ac TEXT,
    tax_id INTEGER NOT NULL,
    date_modified TEXT NOT NULL,
    PRIMARY KEY (code, shopfront)
  )
''';

const String kSalesCustomKey = "sales_custom";
const String kAutoChargeSaleKey = "auto_charge_sale";
const String kAutoChargeSaleStockKey = "auto_charge_sale_stock";
const String kAutoChargeSalePercentKey = "auto_charge_sale_percent";


// ---------------------------------------------------------------------------
// DB INDEXES (For drastically faster search performance)
// ---------------------------------------------------------------------------

// Stock Indexes
const createIdxStocksBarcode = 'CREATE INDEX IF NOT EXISTS idx_stocks_barcode ON Stocks(shopfront, Barcode)';
const createIdxStocksBarcodeNoCase =
  'CREATE INDEX IF NOT EXISTS idx_stocks_barcode_nocase ON Stocks(shopfront, Barcode COLLATE NOCASE)';
const createIdxStocksDesc = 'CREATE INDEX IF NOT EXISTS idx_stocks_desc ON Stocks(shopfront, description)';
const createIdxStocksDescNoCase =
  'CREATE INDEX IF NOT EXISTS idx_stocks_desc_nocase ON Stocks(shopfront, description COLLATE NOCASE)';
const createIdxStocksCustom1 = 'CREATE INDEX IF NOT EXISTS idx_stocks_custom1 ON Stocks(shopfront, custom1)';
const createIdxStocksCustom2 = 'CREATE INDEX IF NOT EXISTS idx_stocks_custom2 ON Stocks(shopfront, custom2)';

// Customer Indexes
const createIdxCustBarcode = 'CREATE INDEX IF NOT EXISTS idx_cust_barcode ON Customers(shopfront, barcode)';
const createIdxCustBarcodeNoCase =
  'CREATE INDEX IF NOT EXISTS idx_cust_barcode_nocase ON Customers(shopfront, barcode COLLATE NOCASE)';
const createIdxCustSurname = 'CREATE INDEX IF NOT EXISTS idx_cust_surname ON Customers(shopfront, surname)';
const createIdxCustGivenNames = 'CREATE INDEX IF NOT EXISTS idx_cust_given_names ON Customers(shopfront, given_names)';
const createIdxCustCompany = 'CREATE INDEX IF NOT EXISTS idx_cust_company ON Customers(shopfront, company)';
const createIdxCustPhone = 'CREATE INDEX IF NOT EXISTS idx_cust_phone ON Customers(shopfront, phone)';
const createIdxCustMobile = 'CREATE INDEX IF NOT EXISTS idx_cust_mobile ON Customers(shopfront, mobile)';
const createIdxCustFax = 'CREATE INDEX IF NOT EXISTS idx_cust_fax ON Customers(shopfront, fax)';
const createIdxCustEmail = 'CREATE INDEX IF NOT EXISTS idx_cust_email ON Customers(shopfront, email)';
const createIdxCustSuburb = 'CREATE INDEX IF NOT EXISTS idx_cust_suburb ON Customers(shopfront, suburb)';
const createIdxCustState = 'CREATE INDEX IF NOT EXISTS idx_cust_state ON Customers(shopfront, state)';
const createIdxCustPostcode = 'CREATE INDEX IF NOT EXISTS idx_cust_postcode ON Customers(shopfront, postcode)';
const createIdxCustCustom1 = 'CREATE INDEX IF NOT EXISTS idx_cust_custom1 ON Customers(shopfront, custom1)';
const createIdxCustCustom2 = 'CREATE INDEX IF NOT EXISTS idx_cust_custom2 ON Customers(shopfront, custom2)';

// Stocktake Indexes
const createIdxStocktakeBarcode =
  'CREATE INDEX IF NOT EXISTS idx_stocktake_barcode ON Stocktake(shopfront, barcode)';
const createIdxStocktakeDescription =
  'CREATE INDEX IF NOT EXISTS idx_stocktake_description ON Stocktake(shopfront, description)';
const createIdxStocktakeDate =
  'CREATE INDEX IF NOT EXISTS idx_stocktake_date ON Stocktake(shopfront, stocktake_date)';