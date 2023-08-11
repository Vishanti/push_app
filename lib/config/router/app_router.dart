import 'package:go_router/go_router.dart';
import 'package:push_app/presentation/screens/details_screen.dart';
import 'package:push_app/presentation/screens/home_screen.dart';

final appRouter = GoRouter(routes: [
  GoRoute(
    path: '/',
    builder: (_, __) => const HomeScreen(),
  ),
  GoRoute(
    path: '/push-details/:messageId',
    builder: (_, state) =>
        DetailsScreen(pushMessageId: state.pathParameters['messageId'] ?? ''),
  ),
]);
