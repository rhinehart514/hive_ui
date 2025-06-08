import 'package:flutter_test/flutter_test.dart';

// A simple class representing an authentication service
class AuthService {
  final AuthRepository repository;
  
  AuthService(this.repository);
  
  Future<User?> getCurrentUser() async {
    return repository.getCurrentUser();
  }
  
  Future<bool> login(String email, String password) async {
    try {
      final user = await repository.login(email, password);
      return user != null;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    await repository.logout();
  }
}

// Repository interface
abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User?> login(String email, String password);
  Future<void> logout();
}

// Simple User model
class User {
  final String id;
  final String email;
  final String name;
  
  User({required this.id, required this.email, required this.name});
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is User &&
    other.id == id &&
    other.email == email &&
    other.name == name;
  
  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}

// Fake implementation of AuthRepository for testing
class FakeAuthRepository implements AuthRepository {
  User? _currentUser;
  final Map<String, String> _validCredentials = {
    'test@example.com': 'password123'
  };
  
  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
  
  @override
  Future<User?> login(String email, String password) async {
    // Check if credentials are valid
    if (_validCredentials.containsKey(email) && 
        _validCredentials[email] == password) {
      _currentUser = User(
        id: '123',
        email: email,
        name: 'Test User'
      );
      return _currentUser;
    }
    
    return null;
  }
  
  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}

// Manual mock implementation
class MockAuthRepository implements AuthRepository {
  User? userToReturn;
  bool loginSucceeds = true;
  bool loginCalled = false;
  bool logoutCalled = false;
  String? lastEmailUsed;
  String? lastPasswordUsed;
  
  @override
  Future<User?> getCurrentUser() async {
    return userToReturn;
  }
  
  @override
  Future<User?> login(String email, String password) async {
    loginCalled = true;
    lastEmailUsed = email;
    lastPasswordUsed = password;
    
    return loginSucceeds ? 
      User(id: '123', email: email, name: 'Test User') : 
      null;
  }
  
  @override
  Future<void> logout() async {
    logoutCalled = true;
    userToReturn = null;
  }
  
  void resetCalls() {
    loginCalled = false;
    logoutCalled = false;
    lastEmailUsed = null;
    lastPasswordUsed = null;
  }
}

void main() {
  group('AuthService with FakeAuthRepository', () {
    late AuthRepository fakeRepository;
    late AuthService authService;
    
    setUp(() {
      fakeRepository = FakeAuthRepository();
      authService = AuthService(fakeRepository);
    });
    
    test('login returns true with valid credentials', () async {
      // Act
      final result = await authService.login('test@example.com', 'password123');
      
      // Assert
      expect(result, isTrue);
    });
    
    test('login returns false with invalid credentials', () async {
      // Act
      final result = await authService.login('test@example.com', 'wrongpassword');
      
      // Assert
      expect(result, isFalse);
    });
    
    test('getCurrentUser returns null before login', () async {
      // Act
      final user = await authService.getCurrentUser();
      
      // Assert
      expect(user, isNull);
    });
    
    test('getCurrentUser returns user after login', () async {
      // Arrange
      await authService.login('test@example.com', 'password123');
      
      // Act
      final user = await authService.getCurrentUser();
      
      // Assert
      expect(user, isNotNull);
      expect(user?.email, equals('test@example.com'));
    });
    
    test('logout clears current user', () async {
      // Arrange
      await authService.login('test@example.com', 'password123');
      
      // Act
      await authService.logout();
      final user = await authService.getCurrentUser();
      
      // Assert
      expect(user, isNull);
    });
  });
  
  group('AuthService with MockAuthRepository', () {
    late MockAuthRepository mockRepository;
    late AuthService authService;
    
    setUp(() {
      mockRepository = MockAuthRepository();
      authService = AuthService(mockRepository);
    });
    
    test('login calls repository with correct parameters', () async {
      // Arrange
      mockRepository.loginSucceeds = true;
      
      // Act
      final result = await authService.login('test@example.com', 'password123');
      
      // Assert
      expect(result, isTrue);
      expect(mockRepository.loginCalled, isTrue);
      expect(mockRepository.lastEmailUsed, equals('test@example.com'));
      expect(mockRepository.lastPasswordUsed, equals('password123'));
    });
    
    test('login returns false when repository returns null', () async {
      // Arrange
      mockRepository.loginSucceeds = false;
      
      // Act
      final result = await authService.login('test@example.com', 'password123');
      
      // Assert
      expect(result, isFalse);
    });
    
    test('logout calls repository', () async {
      // Act
      await authService.logout();
      
      // Assert
      expect(mockRepository.logoutCalled, isTrue);
    });
    
    test('getCurrentUser returns value from repository', () async {
      // Arrange
      final testUser = User(
        id: '456',
        email: 'another@example.com',
        name: 'Another User'
      );
      mockRepository.userToReturn = testUser;
      
      // Act
      final result = await authService.getCurrentUser();
      
      // Assert
      expect(result, equals(testUser));
    });
  });
} 