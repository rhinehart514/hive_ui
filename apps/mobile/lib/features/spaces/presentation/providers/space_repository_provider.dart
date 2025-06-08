import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/repositories/space_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';

/// Provider for the space repository
final spaceRepositoryProvider = Provider<SpacesRepository>((ref) {
  final dataSource = SpacesFirestoreDataSource();
  return SpaceRepositoryImpl(dataSource);
}); 