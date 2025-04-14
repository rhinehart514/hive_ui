# Feature Structure Template

This document describes the standard template structure for new features in the HIVE UI application. It replaces the old `template_feature` directory that was previously used as a reference.

## Clean Architecture Structure

New features should follow this directory structure:

```
features/
  ├── feature_name/
  │    ├── data/           
  │    │    ├── models/       # DTOs for feature data
  │    │    ├── repositories/ # Implementation of repositories 
  │    │    └── datasources/  # API and local data sources
  │    │
  │    ├── domain/            
  │    │    ├── entities/     # Core business entities
  │    │    ├── repositories/ # Repository interfaces
  │    │    └── usecases/     # Business logic
  │    │
  │    └── presentation/      
  │         ├── providers/    # State management
  │         ├── screens/      # Full page UI components
  │         └── widgets/      # Reusable UI components
```

## Implementation Guide

1. Create the directory structure shown above
2. Define domain entities and repository interfaces first
3. Implement data layer with repository implementations
4. Create presentation layer with providers and UI components
5. Create an export file `feature_name.dart` at the root of the feature directory

## Common Files

### Domain Layer

#### Repository Interface Example

```dart
// domain/repositories/my_feature_repository.dart
abstract class MyFeatureRepository {
  Future<List<MyEntity>> getItems();
  Future<MyEntity> getItemById(String id);
  Future<void> saveItem(MyEntity item);
  Future<void> deleteItem(String id);
}
```

#### Entity Example

```dart
// domain/entities/my_entity.dart
class MyEntity {
  final String id;
  final String name;
  final String description;
  
  const MyEntity({
    required this.id,
    required this.name,
    required this.description,
  });
}
```

#### UseCase Example

```dart
// domain/usecases/get_items_usecase.dart
class GetItemsUseCase {
  final MyFeatureRepository repository;
  
  GetItemsUseCase(this.repository);
  
  Future<List<MyEntity>> execute() async {
    return repository.getItems();
  }
}
```

### Data Layer

#### DTO Example

```dart
// data/models/my_model.dart
class MyModel {
  final String id;
  final String name;
  final String description;
  
  MyModel({
    required this.id,
    required this.name,
    required this.description,
  });
  
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
  
  MyEntity toEntity() {
    return MyEntity(
      id: id,
      name: name,
      description: description,
    );
  }
  
  factory MyModel.fromEntity(MyEntity entity) {
    return MyModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
  }
}
```

#### Repository Implementation Example

```dart
// data/repositories/my_feature_repository_impl.dart
class MyFeatureRepositoryImpl implements MyFeatureRepository {
  final MyFeatureDataSource dataSource;
  
  MyFeatureRepositoryImpl(this.dataSource);
  
  @override
  Future<List<MyEntity>> getItems() async {
    final models = await dataSource.getItems();
    return models.map((model) => model.toEntity()).toList();
  }
  
  @override
  Future<MyEntity> getItemById(String id) async {
    final model = await dataSource.getItemById(id);
    return model.toEntity();
  }
  
  @override
  Future<void> saveItem(MyEntity item) async {
    final model = MyModel.fromEntity(item);
    await dataSource.saveItem(model);
  }
  
  @override
  Future<void> deleteItem(String id) async {
    await dataSource.deleteItem(id);
  }
}
```

### Presentation Layer

#### Provider Example

```dart
// presentation/providers/my_feature_provider.dart
final myFeatureProvider = StateNotifierProvider<MyFeatureNotifier, MyFeatureState>((ref) {
  final repository = ref.read(myFeatureRepositoryProvider);
  return MyFeatureNotifier(repository);
});

class MyFeatureNotifier extends StateNotifier<MyFeatureState> {
  final MyFeatureRepository repository;
  
  MyFeatureNotifier(this.repository) : super(MyFeatureState.initial());
  
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await repository.getItems();
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

class MyFeatureState {
  final List<MyEntity> items;
  final bool isLoading;
  final String? error;
  
  const MyFeatureState({
    required this.items,
    required this.isLoading,
    this.error,
  });
  
  factory MyFeatureState.initial() {
    return MyFeatureState(
      items: [],
      isLoading: false,
    );
  }
  
  MyFeatureState copyWith({
    List<MyEntity>? items,
    bool? isLoading,
    String? error,
  }) {
    return MyFeatureState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
```

## Best Practices

1. Keep feature code self-contained
2. Follow SOLID principles
3. Write tests for business logic
4. Use immutable state with copyWith
5. Separate UI from business logic
6. Use proper error handling
7. Follow the established architecture patterns 