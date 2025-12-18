import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../../../services/calendar/calendar.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit() : super(const CalendarState.initial());

  final CalendarService _calendar = CalendarService.instance;

  Future<void> loadUpcomingEvents({int maxResults = 50}) async {
    emit(const CalendarState.loading());
    try {
      final result = await _calendar.listUpcomingEvents(maxResults: maxResults);
      emit(CalendarState.loaded(
        items: result.events,
        nextPageToken: result.nextPageToken,
        hasMore: result.nextPageToken != null,
      ));
    } catch (e) {
      emit(CalendarState.failure(e.toString()));
    }
  }

  Future<void> loadMoreEvents() async {
    if (state.status == CalendarStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(CalendarState.loadingMore(
      items: state.events,
      nextPageToken: state.nextPageToken,
    ));

    try {
      final result = await _calendar.listUpcomingEvents(
        maxResults: 50,
        pageToken: state.nextPageToken,
      );

      emit(CalendarState.loaded(
        items: [...state.events, ...result.events],
        nextPageToken: result.nextPageToken,
        hasMore: result.nextPageToken != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CalendarStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void clear() {
    emit(const CalendarState.initial());
  }
}


