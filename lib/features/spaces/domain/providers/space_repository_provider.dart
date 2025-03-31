import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/space_repository_impl.dart';
import '../repositories/space_repository.dart';

/// Provider for the space repository
final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepositoryImpl();
}); 