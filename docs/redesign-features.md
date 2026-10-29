# One Verse redesign: features and highlights

The goal is a Quran listening app that feels like a top streaming app: simple, fast and steady, with every
choice one tap away. This list matches the interactive prototype.

## 1. Listening and reading

| Feature | Behaviour | Build notes |
|---|---|---|
| Streaming-style Home | Continue listening card, "For this moment" picks, reciter carousel with photos, quick picks, verse of the day | Picks come from local time and day (see section 5) |
| Verse list that follows | The list keeps the current ayah in view. A long ayah that does not fit scrolls through as it is recited. If the user scrolls, following pauses and a "Back to ayah N" button appears. | `ScrollController` driven by playback position; stop following on a user drag (`UserScrollNotification`) |
| Single-verse focus view | One ayah full screen, words lighting up, swipe or arrows for the next ayah, its own text size | Separate route; `PageView` of ayahs |
| Word-exact highlighting | The word being recited is highlighted, from real timestamps where they exist; the UI labels timing as "Word-exact" or "Estimated" | See `audio-timing-and-reciters.md`. Binary search the segment list on every position update. |
| Five Quran scripts | Madani (KFGQPC Hafs), IndoPak Nastaleeq, Tajweed colours, Uthmani (Amiri), Simple Naskh, each shown with a Bismillah preview | Each script is a text edition plus its own font; see `quran-scripts-and-fonts.md` |
| Correct ayah markers | The ayah number uses the Hafs font's own ornament in every script, so it never spills out of the circle | Append Arabic-Indic digits in the Hafs font |
| One-tap translation | A sticky chip bar on every surah: Saheeh, Asad, Urdu, Arabic only, + more | Store the choice; switching keeps the current ayah anchored on screen |

## 2. Player

- Now Playing with: what you hear (Arabic, Arabic + translation, translation), repeat ayah (off, 1×, 3×, ∞),
  speed (0.75–1.5×), sleep timer (minutes or end of surah), reciter, translation voice, script, share,
  download, up next, and an ayah strip for seeking.
- Reciter picker: photo grid, search, filters (Word sync, Murattal, Mujawwad, Teaching). One tap switches
  the voice without losing the place.
- Mini player on every screen.

## 3. Background playback and the notification card

When the app is in the background or the phone is locked, the system media notification shows the full
player: surah artwork, "Al-Mulk · Ayah 12", reciter, the start of the ayah's translation, a seek bar, and
Repeat, Previous, Play/Pause, Next, Stop.

Build with `audio_service` (media session, notification, lock screen, Bluetooth and headset buttons,
Android Auto) on top of the existing `just_audio`:

- `MediaItem` per ayah: `title` = "Al-Mulk · Ayah 12", `artist` = reciter, `artUri` = generated surah artwork
  saved as a PNG file, `extras` = surah and ayah.
- Custom actions for Repeat and Stop; `androidNotificationOngoing` while playing.
- Android 13+: request `POST_NOTIFICATIONS`; Android 14+: declare the `mediaPlayback` foreground service type.

## 4. Resume exactly where you stopped

If the user swipes the app away (or the OS kills it), reopening it shows "Welcome back" with the surah, ayah,
position inside the ayah, and every setting kept: reciter, mode, translation, script, speed and repeat.

- Save `{surah, ayah, positionMs, reciter, translationVoice, mode, textEdition, script, speed, repeat}`
  every few seconds while playing, on every ayah change, and in `AppLifecycleState.paused/detached`.
  `shared_preferences` is enough; Hive or Isar if the history grows.
- On cold start, read it before building Home and offer Resume. Never auto-play.
- Later this is exactly a Quran Foundation **reading session** (see `quran-foundation-api.md`).

## 5. Progress, streaks and reminders

**Progress tab**

- Today: a ring for minutes against a daily goal (default 20 minutes), ayahs today, streak, best streak.
- Minutes listened by Day (hours), Week, Month and Year, with totals and averages; tap a bar for its value.
- Month calendar coloured by minutes listened.
- Most listened reciters and surahs.

**Data model** (local first, same shape as the Quran Foundation activity days):

```
ListeningSession { startedAt, endedAt, seconds, surah, fromAyah, toAyah, reciter, mode }
DailyActivity   { date, seconds, ayahs, ranges[] }       // rebuilt from sessions
```

Count only real playback time (playing, not paused, not seeking), and close a session on pause or after
30 seconds without progress.

**Reminders** (`flutter_local_notifications` with exact or inexact alarms, timezone-aware):

- Daily reminder at a chosen time, deep-linking to "Continue Al-Mulk, ayah 12".
- Streak saver at 8 PM, only if today's goal is not met.
- Al-Kahf on Friday morning (and a gentle note on Thursday after maghrib).
- Al-Mulk before sleep, opening straight into the focus view.
- Special days: Ramadan, the last ten nights, Day of Arafah, Eid, each with a chosen surah, reciter and time.
  Use a Hijri calendar package and let the user adjust by a day for local moon sighting.

**Later, with accounts:** sign in with Quran Foundation OAuth2 and sync activity days, streaks, goals,
bookmarks, notes and preferences through its User APIs. Send activity days for listening sessions, and a
reading session for the last position.

## 6. Downloads

- Downloading a surah always includes the selected translation and script, for the complete surah, plus
  word timings when the reciter has them. Other translations and the translation voice are optional extras.
- Files stay organised as `Music/OneVerse/<language>/<reciter>/<surah>/` so content creators can find clips.
- Show total size before downloading and progress per item while downloading.

## 7. Suggested build order

1. Script and font pairing fix (it is a reading bug today), with the script picker.
2. Persisted session and resume.
3. `audio_service` notification and lock-screen controls.
4. New Home, verse list with follow mode, focus view, Now Playing.
5. Word timings (start with the CC0 Luhaidan data and Quran Foundation segments).
6. Progress tab, streaks and reminders.
7. Accounts and cloud sync with the Quran Foundation User APIs.
