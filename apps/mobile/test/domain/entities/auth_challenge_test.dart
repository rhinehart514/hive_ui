import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/domain/entities/auth_challenge.dart';

void main() {
  group('AuthChallenge', () {
    test('create factory should initialize with pending status and correct expiry', () {
      const email = 'test@example.com';
      final challenge = AuthChallenge.create(email);
      
      expect(challenge.email, equals(email));
      expect(challenge.status, equals(AuthChallengeStatus.pending));
      expect(challenge.createdAt.isBefore(DateTime.now()), isTrue);
      
      // Expiry should be 15 minutes after creation
      final expectedExpiry = challenge.createdAt.add(
        const Duration(minutes: AuthChallenge.expiryDurationMinutes),
      );
      expect(challenge.expiresAt.isAtSameMomentAs(expectedExpiry), isTrue);
    });
    
    test('isExpired() should return true when current time is after expiresAt', () {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(minutes: 5));
      
      final challenge = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: pastExpiry.subtract(const Duration(minutes: 15)),
        expiresAt: pastExpiry,
      );
      
      expect(challenge.isExpired(), isTrue);
    });
    
    test('isExpired() should return false when current time is before expiresAt', () {
      final now = DateTime.now();
      final futureExpiry = now.add(const Duration(minutes: 5));
      
      final challenge = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: now,
        expiresAt: futureExpiry,
      );
      
      expect(challenge.isExpired(), isFalse);
    });
    
    test('markAsVerified() should change status to verified', () {
      final challenge = AuthChallenge.create('test@example.com');
      final verifiedChallenge = challenge.markAsVerified();
      
      expect(verifiedChallenge.status, equals(AuthChallengeStatus.verified));
      expect(verifiedChallenge.email, equals(challenge.email));
      expect(verifiedChallenge.createdAt, equals(challenge.createdAt));
      expect(verifiedChallenge.expiresAt, equals(challenge.expiresAt));
    });
    
    test('markAsExpired() should change status to expired', () {
      final challenge = AuthChallenge.create('test@example.com');
      final expiredChallenge = challenge.markAsExpired();
      
      expect(expiredChallenge.status, equals(AuthChallengeStatus.expired));
      expect(expiredChallenge.email, equals(challenge.email));
      expect(expiredChallenge.createdAt, equals(challenge.createdAt));
      expect(expiredChallenge.expiresAt, equals(challenge.expiresAt));
    });
    
    test('getRemainingSeconds() should return correct remaining time', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 10));
      
      final challenge = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
      );
      
      // Allow some flexibility in timing due to test execution time
      expect(challenge.getRemainingSeconds(), greaterThan(9 * 60 - 2));
      expect(challenge.getRemainingSeconds(), lessThan(10 * 60 + 2));
    });
    
    test('getRemainingSeconds() should return 0 when expired', () {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(minutes: 5));
      
      final challenge = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: pastExpiry.subtract(const Duration(minutes: 15)),
        expiresAt: pastExpiry,
      );
      
      expect(challenge.getRemainingSeconds(), equals(0));
    });
    
    test('copyWith() should correctly replace only specified fields', () {
      final original = AuthChallenge.create('test@example.com');
      final now = DateTime.now();
      
      final modified = original.copyWith(
        email: 'new@example.com',
        status: AuthChallengeStatus.verified,
      );
      
      expect(modified.email, equals('new@example.com'));
      expect(modified.status, equals(AuthChallengeStatus.verified));
      expect(modified.createdAt, equals(original.createdAt));
      expect(modified.expiresAt, equals(original.expiresAt));
    });
    
    test('equality should be based on all fields', () {
      final now = DateTime.now();
      final challenge1 = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
      );
      
      final challenge2 = AuthChallenge(
        email: 'test@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
      );
      
      final challenge3 = AuthChallenge(
        email: 'other@example.com',
        status: AuthChallengeStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
      );
      
      expect(challenge1, equals(challenge2));
      expect(challenge1, isNot(equals(challenge3)));
    });
  });
} 