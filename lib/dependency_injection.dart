import 'package:ai_scheduler/services/audio_input/audio_input.dart';
import 'package:ai_scheduler/services/audio_output/audio_output.dart';
import 'package:injector/injector.dart';

void registerDependencies() {
  final injector = Injector.appInstance;

  injector.registerSingleton<AudioInput>(() {
    return AudioInput();
  });

  injector.registerSingleton<AudioOutput>(() {
    return AudioOutput();
  });
}
