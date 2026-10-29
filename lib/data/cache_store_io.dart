import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'cache_store.dart';

CacheStore createStore() => IoCacheStore();

/// Stores each document as a JSON file; the file's modified time is the fetch
/// time, so no separate index can drift out of sync.
class IoCacheStore implements CacheStore {
  late Directory _root;
  bool _ready = false;
  final Map<String, CacheEntry> _memo = {};

  IoCacheStore([Directory? root]) {
    if (root != null) {
      _root = root;
      _ready = true;
    }
  }

  @override
  String? get filesRoot => _ready ? '${_root.path}/files' : null;

  @override
  Future<void> init() async {
    if (_ready) return;
    final base = await getApplicationSupportDirectory();
    _root = Directory('${base.path}/oneverse');
    await Directory('${_root.path}/cache').create(recursive: true);
    await Directory('${_root.path}/files').create(recursive: true);
    _ready = true;
  }

  File _file(String key) => File('${_root.path}/cache/${key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.json');

  @override
  Future<CacheEntry?> read(String key) async {
    final m = _memo[key];
    if (m != null) return m;
    final f = _file(key);
    if (!await f.exists()) return null;
    try {
      final e = CacheEntry(CacheStore.decode(await f.readAsString()), await f.lastModified());
      _memo[key] = e;
      return e;
    } catch (_) {
      await f.delete().catchError((_) => f);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data, {DateTime? fetchedAt}) async {
    final f = _file(key);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(CacheStore.encode(data), flush: true);
    await tmp.rename(f.path);
    final t = fetchedAt ?? DateTime.now();
    if (fetchedAt != null) await f.setLastModified(fetchedAt);
    _memo[key] = CacheEntry(data, t);
  }

  @override
  Future<void> delete(String key) async {
    _memo.remove(key);
    final f = _file(key);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<List<String>> keys(String prefix) async {
    final dir = Directory('${_root.path}/cache');
    if (!await dir.exists()) return [];
    final p = prefix.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return [
      await for (final f in dir.list())
        if (f is File && f.path.endsWith('.json'))
          if (f.uri.pathSegments.last.startsWith(p)) f.uri.pathSegments.last.replaceAll('.json', '')
    ];
  }

  @override
  Future<int> sizeOf(String prefix) async {
    final dir = Directory('${_root.path}/cache');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final f in dir.list()) {
      if (f is File && f.uri.pathSegments.last.startsWith(prefix)) total += await f.length();
    }
    return total;
  }
}
