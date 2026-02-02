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
    date_modified TEXT,
    freight INTEGER,
    tare_weight REAL,
    unitof_measure REAL,
    weighted INTEGER,
    track_serial INTEGER,
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
    is_synced INTEGER NOT NULL,
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



