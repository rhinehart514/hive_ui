// Export all permission-related widgets and components for easy imports

// Presentation widgets
export 'presentation/widgets/permission_gate.dart';
export 'presentation/widgets/role_badge.dart';
export 'presentation/widgets/verification_status_badge.dart';

// Providers
export 'providers/permission_providers.dart';

// Domain entities (re-export from core for convenience)
export 'package:hive_ui/core/services/role_checker.dart' show UserRole;
export 'package:hive_ui/features/profile/domain/entities/verification_status.dart'; 