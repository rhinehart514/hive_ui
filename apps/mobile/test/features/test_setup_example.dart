import 'package:flutter_test/flutter_test.dart';

// Simple interface to test
abstract class CounterRepository {
  Future<int> getCount();
  Future<void> increment();
  Future<void> decrement();
  Future<void> reset();
}

// Simple implementation for testing
class InMemoryCounterRepository implements CounterRepository {
  int _count = 0;
  
  @override
  Future<int> getCount() async => _count;
  
  @override
  Future<void> increment() async => _count++;
  
  @override
  Future<void> decrement() async => _count--;
  
  @override
  Future<void> reset() async => _count = 0;
}

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
  group('CounterService tests', () {
    late CounterRepository repository;
    late CounterService service;
    
    setUp(() {
      repository = InMemoryCounterRepository();
      service = CounterService(repository);
    });
    
    test('getCurrentCount returns the current count', () async {
      expect(await service.getCurrentCount(), equals(0));
    });
    
    test('incrementAndGet increases count and returns new value', () async {
      expect(await service.incrementAndGet(), equals(1));
      expect(await service.getCurrentCount(), equals(1));
    });
    
    test('decrementAndGet decreases count and returns new value', () async {
      // First increment to 1
      await service.incrementAndGet();
      // Then decrement to 0
      expect(await service.decrementAndGet(), equals(0));
      expect(await service.getCurrentCount(), equals(0));
    });
    
    test('resetCounter sets count to 0', () async {
      // Increment twice
      await service.incrementAndGet();
      await service.incrementAndGet();
      expect(await service.getCurrentCount(), equals(2));
      
      // Reset
      await service.resetCounter();
      expect(await service.getCurrentCount(), equals(0));
    });
  });
} 