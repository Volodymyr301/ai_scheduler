import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_scheduler/features/voice/models/server_response_dto.dart' show ResponseDto;
import 'package:ai_scheduler/services/audio_input/audio_input.dart';
import 'package:ai_scheduler/services/calendar/calendar.dart' show CalendarService;
import 'package:ai_scheduler/services/web_socket/web_socket.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';

part 'assistant_state.dart';

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({
    required CustomWebSocketClient webSocketClient,
    required AudioInput audioInput,
    required CalendarService calendar,
  }) : _webSocketClient = webSocketClient,
       _audioInput = audioInput,
       _calendar = calendar,
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
  final CalendarService _calendar;

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

  _receiveResponse(dynamic response) async {
    ResponseDto parsedResponse = ResponseDto.fromJson(jsonDecode(response));

    debugPrint(response);

    if (parsedResponse.status != 'ok') return;
    if (parsedResponse.result.intent != "calendar_add") return;

    for (var eventData in parsedResponse.result.params) {
      Event event = Event(
        summary: eventData.summary,
        start: EventDateTime(dateTime: eventData.start),
        end: EventDateTime(dateTime: eventData.end),
        description: eventData.description,
        location: eventData.location,
      );
      _calendar.addEvent(event);
    }
  }

  @override
  Future<void> close() async {
    await _responseStreamSubscription?.cancel();
    _webSocketClient.closeConnection();
    await _audioStreamSubscription?.cancel();

    return super.close();
  }
}
