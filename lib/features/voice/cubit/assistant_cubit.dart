import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_scheduler/services/audio_input/audio_input.dart';
import 'package:ai_scheduler/services/web_socket/web_socket.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'assistant_state.dart';

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({required CustomWebSocketClient webSocketClient, required AudioInput audioInput})
    : _webSocketClient = webSocketClient,
      _audioInput = audioInput,
      super(AssistantState()) {
    _webSocketClient.openConnection();

    _responseStreamSubscription = _webSocketClient.stream?.listen(
      _receiveResponse,
      onError: (e) {
        print(e);
      },
      onDone: () {
        print('Done');
      },
    );
  }

  final CustomWebSocketClient _webSocketClient;
  final AudioInput _audioInput;

  Stream<Uint8List>? _audioStream;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  late final StreamSubscription<dynamic>? _responseStreamSubscription;

  startVoiceRecording() async {
    emit(state.copyWith(recording: true));
    _audioStream = await _audioInput.startRecording();

    _audioStreamSubscription = _audioStream?.listen(_sendVoiceData);
  }

  _sendVoiceData(Uint8List bytes) async {
    print('bytes: {$bytes}');

    _webSocketClient.sendMessage(bytes);
  }

  stopVoiceRecording() async {
    await _audioStreamSubscription?.cancel();

    _webSocketClient.sendMessage(jsonEncode({"type": "EOF"}));

    emit(state.copyWith(recording: false));
  }

  _receiveResponse(dynamic response) {
    print(response);
  }

  @override
  Future<void> close() async {
    await _responseStreamSubscription?.cancel();
    _webSocketClient.closeConnection();
    await _audioStreamSubscription?.cancel();

    return super.close();
  }
}
