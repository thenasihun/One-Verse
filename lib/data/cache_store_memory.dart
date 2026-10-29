import 'cache_store.dart';

CacheStore createStore() => MemoryCacheStore();

/// In-memory store used on the web build and in tests.
class MemoryCacheStore implements CacheStore {
  final Map<String, CacheEntry> _m = {};

  @override
  String? get filesRoot => null;

  @override
  Future<void> init() async {}

  @override
  Future<CacheEntry?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, Object? data, {DateTime? fetchedAt}) async =>
      _m[key] = CacheEntry(data, fetchedAt ?? DateTime.now());

  @override
  Future<void> delete(String key) async => _m.remove(key);

  @override
  Future<List<String>> keys(String prefix) async => _m.keys.where((k) => k.startsWith(prefix)).toList();

  @override
  Future<int> sizeOf(String prefix) async => _m.entries
      .where((e) => e.key.startsWith(prefix))
      .fold<int>(0, (t, e) => t + CacheStore.encode(e.value.data).length);
}
