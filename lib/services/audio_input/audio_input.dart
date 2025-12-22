import 'dart:typed_data';
import 'package:record/record.dart';

class AudioInput {
  final _config = RecordConfig(
    numChannels: 1,
    echoCancel: true,
    noiseSuppress: true,
    encoder: AudioEncoder.aacLc,
    sampleRate: 16000,
  );

  final _recorder = AudioRecorder();

  Future<Stream<Uint8List>?> startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) return null;

    final audioInStream = await _recorder.startStream(_config)
      ..asBroadcastStream();

    return audioInStream;
  }
}
