import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/foundation.dart';

/// Runs ffmpeg on the phone through ffmpeg-kit.
Future<bool> runFfmpegKit(List<String> args) async {
  final session = await FFmpegKit.executeWithArguments(args);
  final ok = ReturnCode.isSuccess(await session.getReturnCode());
  if (!ok && kDebugMode) debugPrint('ffmpeg failed: ${await session.getAllLogsAsString()}');
  return ok;
}
