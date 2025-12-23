import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import '../authentication/authentication.dart';

class CalendarEventsResult {
  final List<gcal.Event> events;
  final String? nextPageToken;

  CalendarEventsResult({required this.events, this.nextPageToken});
}

class CalendarService {
  CalendarService._();

  static final CalendarService instance = CalendarService._();

  Future<gcal.CalendarApi> _api() async {
    final http.Client client = await AuthenticationService.instance.authenticatedClient();
    return gcal.CalendarApi(client);
  }

  Future<CalendarEventsResult> listUpcomingEvents({
    int maxResults = 50,
    DateTime? timeMin,
    bool singleEvents = true,
    String orderBy = 'startTime',
    String? pageToken,
  }) async {
    final api = await _api();
    final now = DateTime.now().toUtc();
    final events = await api.events.list(
      'primary',
      maxResults: maxResults,
      singleEvents: singleEvents,
      orderBy: orderBy,
      timeMin: (timeMin ?? now).toUtc(),
      pageToken: pageToken,
    );
    return CalendarEventsResult(events: events.items ?? <gcal.Event>[], nextPageToken: events.nextPageToken);
  }

  Future<gcal.Event> addEvent(gcal.Event event) async {
    final api = await _api();
    final updatedEvent = await api.events.insert(event, 'primary');
    return updatedEvent;
  }

  Future<gcal.Event> updateEvent(gcal.Event event) async {
    final api = await _api();
    final updatedEvent = await api.events.update(event, 'primary', event.id!);
    return updatedEvent;
  }
}
