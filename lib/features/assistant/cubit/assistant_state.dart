part of 'assistant_cubit.dart';

class AssistantState extends Equatable {
  const AssistantState({this.recording = false});

  final bool recording;

  AssistantState copyWith({bool? recording}) {
    return AssistantState(recording: recording ?? this.recording);
  }

  @override
  List<Object> get props => [recording];
}
