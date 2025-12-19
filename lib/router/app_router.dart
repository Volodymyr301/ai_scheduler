import 'package:go_router/go_router.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../features/authentication/cubit/authentication_cubit.dart';
import '../features/calendar/view/calendar_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/navigation/view/bottom_navigation_scaffold.dart';
import '../features/event_details/view/event_details_screen.dart';

class AppRouter {
  static GoRouter create(AuthenticationCubit authCubit) {
    return GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return BottomNavigationScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  name: 'calendar',
                  builder: (context, state) => const CalendarScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/event-details',
          name: 'event-details',
          builder: (context, state) {
            final event = state.extra as gcal.Event;
            return EventDetailsScreen(event: event);
          },
        ),
      ],
    );
  }
}


