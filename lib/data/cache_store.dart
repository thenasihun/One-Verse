import 'dart:convert';

import 'cache_store_memory.dart' if (dart.library.io) 'cache_store_io.dart' as impl;

/// A cached JSON document and when it was last fetched from the network.
class CacheEntry {
  final Object? data;
  final DateTime fetchedAt;
  const CacheEntry(this.data, this.fetchedAt);

  Duration get age => DateTime.now().difference(fetchedAt);
}

/// Offline JSON storage. Everything the app shows is read from here first;
/// the network only refreshes it.
abstract class CacheStore {
  static CacheStore? _instance;
  static CacheStore get instance => _instance ??= impl.createStore();
  static set instance(CacheStore s) => _instance = s;

  Future<void> init();
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, Object? data, {DateTime? fetchedAt});
  Future<void> delete(String key);
  Future<List<String>> keys(String prefix);

  /// Root folder for downloaded binary files, or null where files are not
  /// supported (web).
  String? get filesRoot;

  /// Total bytes used by cached documents (approximate).
  Future<int> sizeOf(String prefix);

  static String encode(Object? data) => jsonEncode(data);
  static Object? decode(String s) => jsonDecode(s);
}
