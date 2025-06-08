import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/connectivity_monitor.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'connectivity_monitor_test.mocks.dart';

@GenerateMocks([Connectivity])
void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityPlusMonitor connectivityMonitor;
  late StreamController<List<ConnectivityResult>> connectivityStreamController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityMonitor = ConnectivityPlusMonitor(mockConnectivity);
    connectivityStreamController = StreamController<List<ConnectivityResult>>.broadcast();

    // Stub the stream getter
    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityStreamController.stream);
  });

  tearDown(() {
    connectivityMonitor.dispose(); // Ensure resources are cleaned up
    connectivityStreamController.close();
  });

  group('ConnectivityPlusMonitor Tests', () {
    test('init should check initial connectivity and start listening', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]); // Start online
      
      // Act
      await connectivityMonitor.init();
      
      // Assert
      verify(mockConnectivity.checkConnectivity()).called(1);
      // Verify listener is attached (implicit via stream setup)
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online));
      expect(connectivityMonitor.isOnline, isTrue);
    });

    test('init should handle initial offline status', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]); // Start offline
      
      // Act
      await connectivityMonitor.init();
      
      // Assert
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.offline));
      expect(connectivityMonitor.isOnline, isFalse);
    });
    
     test('init should default to online if checkConnectivity throws error', () async {
       // Arrange
       when(mockConnectivity.checkConnectivity()).thenThrow(Exception('Check failed'));
       
       // Act
       await connectivityMonitor.init();
       
       // Assert
       expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online)); // Default
       expect(connectivityMonitor.isOnline, isTrue);
     });

    test('connectionStatusChanges should emit offline when connectivity is lost', () async {
      // Arrange: Start online
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);
      await connectivityMonitor.init();
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online));

      // Act: Simulate connectivity change event to offline
      connectivityStreamController.add([ConnectivityResult.none]);

      // Assert: Expect status change via stream
      await expectLater(
        connectivityMonitor.connectionStatusChanges,
        emits(ConnectionStatus.offline),
      );
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.offline));
      expect(connectivityMonitor.isOnline, isFalse);
    });

    test('connectionStatusChanges should emit online when connectivity is gained', () async {
      // Arrange: Start offline
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      await connectivityMonitor.init();
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.offline));

      // Act: Simulate connectivity change event to online (wifi)
      connectivityStreamController.add([ConnectivityResult.wifi]);

      // Assert: Expect status change via stream
      await expectLater(
        connectivityMonitor.connectionStatusChanges,
        emits(ConnectionStatus.online),
      );
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online));
      expect(connectivityMonitor.isOnline, isTrue);
    });

    test('connectionStatusChanges should not emit if status does not change (online -> online)', () async {
      // Arrange: Start online (wifi)
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      await connectivityMonitor.init();
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online));

      // Act: Simulate connectivity change event to different online type (mobile)
      connectivityStreamController.add([ConnectivityResult.mobile]);

      // Assert: Expect NO status change event within a short time
      // We use .then() to ensure the event loop has a chance to process the stream
      var eventReceived = false;
      connectivityMonitor.connectionStatusChanges.listen((_) { eventReceived = true; });
      await Future.delayed(Duration.zero); // Allow stream event to propagate if any
      expect(eventReceived, isFalse);
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online)); // Still online
    });
    
    test('connectionStatusChanges should emit online if multiple connections exist', () async {
      // Arrange: Start offline
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      await connectivityMonitor.init();
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.offline));

      // Act: Simulate connectivity change event to multiple online types
      connectivityStreamController.add([ConnectivityResult.wifi, ConnectivityResult.mobile]);

      // Assert: Expect status change via stream
      await expectLater(
        connectivityMonitor.connectionStatusChanges,
        emits(ConnectionStatus.online),
      );
      expect(connectivityMonitor.currentStatus, equals(ConnectionStatus.online));
      expect(connectivityMonitor.isOnline, isTrue);
    });

    test('dispose cancels subscription', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      await connectivityMonitor.init(); // This sets up the subscription internally
      
      // Act
      await connectivityMonitor.dispose();
      
      // Assert
      // We can't directly verify the subscription cancellation easily without exposing it,
      // but we can check that adding events to the original controller no longer affects the monitor.
      final initialStatus = connectivityMonitor.currentStatus;
      connectivityStreamController.add([ConnectivityResult.none]); // Try to change status
      await Future.delayed(Duration.zero); // Allow potential event propagation
      expect(connectivityMonitor.currentStatus, equals(initialStatus)); // Status should not have changed
    });
  });
} 