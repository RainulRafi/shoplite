import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const List<List<String>> _migrations = [
    // সংস্করণ ১: Cart
    [
      '''
      CREATE TABLE cart_items(
        owner_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        brand TEXT,
        thumbnail TEXT NOT NULL,
        list_price_cents INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        discount_percent REAL NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 1),
        max_quantity INTEGER NOT NULL CHECK (max_quantity >= 1),
        added_at INTEGER NOT NULL,
        PRIMARY KEY (owner_id, product_id)
      )
      ''',
      '''
      CREATE TABLE cart_meta(
        owner_id TEXT PRIMARY KEY,
        coupon_code TEXT
      )
      ''',
    ],

    [
      '''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id TEXT NOT NULL,
        label TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        division TEXT NOT NULL,
        district TEXT NOT NULL,
        area TEXT NOT NULL,
        line1 TEXT NOT NULL,
        postal_code TEXT,
        note TEXT,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
        updated_at INTEGER NOT NULL
      )
      ''',
      'CREATE INDEX idx_addresses_owner ON addresses(owner_id)',
      'CREATE UNIQUE INDEX uq_addresses_one_default '
          'ON addresses(owner_id) WHERE is_default = 1',
      '''
      CREATE TABLE wishlist_items(
        owner_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        brand TEXT,
        thumbnail TEXT NOT NULL,
        list_price_cents INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        discount_percent REAL NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (owner_id, product_id)
      )
      ''',
      '''
      CREATE TABLE profile_overrides(
        owner_id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
      ''',
      '''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
      ''',
    ],

    [
      '''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id TEXT NOT NULL,
        order_number TEXT NOT NULL UNIQUE,
        idempotency_key TEXT NOT NULL UNIQUE,
        placed_at INTEGER NOT NULL,
        cancelled_at INTEGER,
        delivery_method TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        list_total_cents INTEGER NOT NULL,
        item_discount_cents INTEGER NOT NULL,
        subtotal_cents INTEGER NOT NULL,
        coupon_code TEXT,
        coupon_discount_cents INTEGER NOT NULL,
        shipping_cents INTEGER NOT NULL,
        total_cents INTEGER NOT NULL,
        ship_label TEXT NOT NULL,
        ship_name TEXT NOT NULL,
        ship_phone TEXT NOT NULL,
        ship_division TEXT NOT NULL,
        ship_district TEXT NOT NULL,
        ship_area TEXT NOT NULL,
        ship_line1 TEXT NOT NULL,
        ship_postal_code TEXT,
        ship_note TEXT
      )
      ''',
      'CREATE INDEX idx_orders_owner ON orders(owner_id, placed_at DESC)',
      '''
      CREATE TABLE order_items(
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        brand TEXT,
        thumbnail TEXT NOT NULL,
        list_price_cents INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        discount_percent REAL NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 1),
        PRIMARY KEY (order_id, product_id),
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
      ''',
    ],

    [
      '''
      CREATE TABLE recently_viewed(
        owner_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        brand TEXT,
        thumbnail TEXT NOT NULL,
        list_price_cents INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        discount_percent REAL NOT NULL,
        viewed_at INTEGER NOT NULL,
        PRIMARY KEY (owner_id, product_id)
      )
      ''',
      'CREATE INDEX idx_recently_viewed_time ON recently_viewed(owner_id, viewed_at DESC)',

      '''
      CREATE TABLE search_history(
        owner_id TEXT NOT NULL,
        term_key TEXT NOT NULL,
        term TEXT NOT NULL,
        searched_at INTEGER NOT NULL,
        PRIMARY KEY (owner_id, term_key)
      )
      ''',
    ],

    [
      '''
      CREATE TABLE my_reviews(
        owner_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        product_title TEXT NOT NULL,
        thumbnail TEXT NOT NULL,
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (owner_id, product_id)
      )
      ''',
      '''
      CREATE TABLE notification_reads(
        owner_id TEXT NOT NULL,
        notification_key TEXT NOT NULL,
        PRIMARY KEY (owner_id, notification_key)
      )
      ''',
    ],
  ];

  static int get schemaVersion => _migrations.length;

  static Future<void> configure(Database db) =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> onCreate(Database db, int version) =>
      _migrate(db, 0, version);

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) =>
      _migrate(db, oldVersion, newVersion);

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from; v < to; v++) {
      for (final sql in _migrations[v]) {
        await db.execute(sql);
      }
    }
  }

  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'shoplite.db'),
      version: schemaVersion,
      onConfigure: configure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }
}
