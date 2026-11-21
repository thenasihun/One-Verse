/// A part of a playlist: ayahs [from]..[to] of [surah].
class PlaylistItem {
  final int surah, from, to;
  const PlaylistItem(this.surah, this.from, this.to);

  Map<String, dynamic> toJson() => {'s': surah, 'f': from, 't': to};
  factory PlaylistItem.fromJson(Map<String, dynamic> j) => PlaylistItem(j['s'] as int, j['f'] as int, j['t'] as int);
}

/// The listener's own list: surahs or passages in their order, recited by one
/// reciter, with an optional reminder on chosen days.
class Playlist {
  final String id;
  String name;
  String? reciterId; // null: whoever is chosen in the player
  List<PlaylistItem> items;
  bool remind;
  int remindAt; // minutes after midnight
  Set<int> days; // DateTime.monday..DateTime.sunday
  bool repeat; // start again after the last item

  Playlist({
    required this.id,
    required this.name,
    this.reciterId,
    List<PlaylistItem>? items,
    this.remind = false,
    this.remindAt = 6 * 60,
    Set<int>? days,
    this.repeat = false,
  })  : items = items ?? [],
        days = days ?? {1, 2, 3, 4, 5, 6, 7};

  bool get daily => days.length == 7;

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'r': reciterId,
        'i': [for (final it in items) it.toJson()],
        'rm': remind,
        'at': remindAt,
        'd': days.toList()..sort(),
        'rp': repeat,
      };

  /// A copy with a new id, e.g. to make a variation of a list.
  Playlist copy({required String id, String? name}) => Playlist(
        id: id,
        name: name ?? '${this.name} (copy)',
        reciterId: reciterId,
        items: List.of(items),
        remind: false,
        remindAt: remindAt,
        days: Set.of(days),
        repeat: repeat,
      );

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: j['n'] as String,
        reciterId: j['r'] as String?,
        items: [for (final i in (j['i'] as List)) PlaylistItem.fromJson(Map<String, dynamic>.from(i as Map))],
        remind: (j['rm'] as bool?) ?? false,
        remindAt: (j['at'] as int?) ?? 6 * 60,
        days: {for (final d in (j['d'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])) d as int},
        repeat: (j['rp'] as bool?) ?? false,
      );
}

/// Ready-made lists offered when there are none yet.
const playlistTemplates = <(String, List<PlaylistItem>, int)>[
  ('Morning', [PlaylistItem(36, 1, 83), PlaylistItem(55, 1, 78)], 6 * 60 + 15),
  ('Before sleep', [PlaylistItem(67, 1, 30), PlaylistItem(32, 1, 30), PlaylistItem(2, 285, 286)], 22 * 60),
  ('Friday', [PlaylistItem(18, 1, 110)], 7 * 60 + 30),
  ('Protection', [PlaylistItem(1, 1, 7), PlaylistItem(2, 255, 255), PlaylistItem(112, 1, 4), PlaylistItem(113, 1, 5), PlaylistItem(114, 1, 6)], 20 * 60),
];
