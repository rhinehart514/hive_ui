import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for SpacesFirestoreDataSource
final spacesDataSourceProvider = Provider<SpacesDataSource>((ref) {
  // Ensure Firebase is initialized
  ref.watch(firebaseCoreServiceProvider).isInitialized;
  return SpacesFirestoreDataSource();
});

/// Provider for SpacesRepository
final spacesRepositoryProvider = Provider.autoDispose<SpacesRepository>((ref) {
  // Ensure Firebase is initialized
  ref.watch(firebaseCoreServiceProvider).isInitialized;
  final dataSource = ref.watch(spacesDataSourceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return SpacesRepositoryImpl(dataSource, auth: auth);
});

/// Provider for the space repository (legacy)
/// @deprecated Use spacesRepositoryProvider instead
final spaceRepositoryProvider = Provider<SpacesRepository>((ref) {
  // Directly reuse the SpacesRepository implementation
  // since SpaceRepository was a typedef for SpacesRepository
  final repository = ref.watch(spacesRepositoryProvider);
  return repository;
}); 