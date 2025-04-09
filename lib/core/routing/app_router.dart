import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_admin_page.dart';

/// Routes for settings and profile management
final List<RouteBase> _profileRoutes = [
  // ... existing routes ...
  GoRoute(
    path: 'verification/admin',
    name: 'verification_admin',
    builder: (context, state) => const VerificationAdminPage(),
  ),
  // ... existing routes ...
]; 