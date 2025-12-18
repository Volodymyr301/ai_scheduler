import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/authentication/cubit/authentication_cubit.dart';
import 'features/calendar/cubit/calendar_cubit.dart';
import 'router/app_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _authCubit = AuthenticationCubit();
  late final _router = AppRouter.create(_authCubit);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationCubit>.value(value: _authCubit),
        BlocProvider<CalendarCubit>(create: (_) => CalendarCubit()),
      ],
      child: MaterialApp.router(
        title: 'AI Scheduler',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: _router,
      ),
    );
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }
}
