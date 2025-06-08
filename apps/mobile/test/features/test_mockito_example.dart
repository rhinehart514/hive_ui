import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Simple interface to test
abstract class CounterRepository {
  Future<int> getCount();
  Future<void> increment();
  Future<void> decrement();
  Future<void> reset();
}

// Manual mock for testing
class MockCounterRepository extends Mock implements CounterRepository {}

// A simple service that uses the repository
class CounterService {
  final CounterRepository repository;
  
  CounterService(this.repository);
  
  Future<int> getCurrentCount() async {
    return repository.getCount();
  }
  
  Future<int> incrementAndGet() async {
    await repository.increment();
    return repository.getCount();
  }
  
  Future<int> decrementAndGet() async {
    await repository.decrement();
    return repository.getCount();
  }
  
  Future<void> resetCounter() async {
    await repository.reset();
  }
}

void main() {
  group('CounterService with mocks', () {
    late MockCounterRepository mockRepository;
    late CounterService service;
    
    setUp(() {
      mockRepository = MockCounterRepository();
      service = CounterService(mockRepository);
    });
    
    test('getCurrentCount returns value from repository', () async {
      // Setup the mock to return a specific value
      when(mockRepository.getCount()).thenAnswer((_) async => 42);
      
      // Verify the service returns the mocked value
      expect(await service.getCurrentCount(), equals(42));
      
      // Verify the repository method was called
      verify(mockRepository.getCount()).called(1);
    });
    
    test('incrementAndGet calls increment and getCount on repository', () async {
      // Setup the mock methods
      when(mockRepository.increment()).thenAnswer((_) async {});
      when(mockRepository.getCount()).thenAnswer((_) async => 5);
      
      // Call the service method
      final result = await service.incrementAndGet();
      
      // Verify the result
      expect(result, equals(5));
      
      // Verify the repository methods were called in the correct order
      verifyInOrder([
        mockRepository.increment(),
        mockRepository.getCount(),
      ]);
    });
    
    test('decrementAndGet calls decrement and getCount on repository', () async {
      // Setup the mock methods
      when(mockRepository.decrement()).thenAnswer((_) async {});
      when(mockRepository.getCount()).thenAnswer((_) async => 3);
      
      // Call the service method
      final result = await service.decrementAndGet();
      
      // Verify the result
      expect(result, equals(3));
      
      // Verify the repository methods were called in the correct order
      verifyInOrder([
        mockRepository.decrement(),
        mockRepository.getCount(),
      ]);
    });
    
    test('resetCounter calls reset on repository', () async {
      // Setup the mock method
      when(mockRepository.reset()).thenAnswer((_) async {});
      
      // Call the service method
      await service.resetCounter();
      
      // Verify the repository method was called
      verify(mockRepository.reset()).called(1);
    });
  });
} 