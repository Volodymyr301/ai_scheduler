import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioOutput {
  void init() async {
    await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);
  }

  void play(Uint8List audioChunk) async {
    final audioOutputStream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      format: BufferType.s16le,
    );

    var handle = await SoLoud.instance.play(audioOutputStream);

    SoLoud.instance.addAudioDataStream(audioOutputStream, audioChunk);

    SoLoud.instance.setDataIsEnded(audioOutputStream);

    SoLoud.instance.stop(handle);
  }
}
