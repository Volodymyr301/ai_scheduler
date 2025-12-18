part of 'calendar_cubit.dart';

enum CalendarStatus { initial, loading, loaded, loadingMore, failure }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<gcal.Event> events;
  final String? error;
  final String? nextPageToken;
  final bool hasMore;

  const CalendarState({
    required this.status,
    this.events = const <gcal.Event>[],
    this.error,
    this.nextPageToken,
    this.hasMore = true,
  });

  const CalendarState.initial() : this(status: CalendarStatus.initial);
  const CalendarState.loading() : this(status: CalendarStatus.loading);
  const CalendarState.failure(String message)
      : this(status: CalendarStatus.failure, error: message);
  const CalendarState.loaded({
    required List<gcal.Event> items,
    String? nextPageToken,
    bool hasMore = true,
  }) : this(
          status: CalendarStatus.loaded,
          events: items,
          nextPageToken: nextPageToken,
          hasMore: hasMore,
        );
  const CalendarState.loadingMore({
    required List<gcal.Event> items,
    String? nextPageToken,
  }) : this(
          status: CalendarStatus.loadingMore,
          events: items,
          nextPageToken: nextPageToken,
          hasMore: true,
        );

  CalendarState copyWith({
    CalendarStatus? status,
    List<gcal.Event>? events,
    String? error,
    String? nextPageToken,
    bool? hasMore,
  }) {
    return CalendarState(
      status: status ?? this.status,
      events: events ?? this.events,
      error: error ?? this.error,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, events.length, error, nextPageToken, hasMore];
}


