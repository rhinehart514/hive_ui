import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/event_creation_request.dart';

/// State for create event provider
class CreateEventState {
  final bool isLoading;
  final String? errorMessage;
  final Event? createdEvent;
  final bool isNameAvailable;

  const CreateEventState({
    this.isLoading = false,
    this.errorMessage,
    this.createdEvent,
    this.isNameAvailable = true,
  });

  CreateEventState copyWith({
    bool? isLoading,
    String? errorMessage,
    Event? createdEvent,
    bool? isNameAvailable,
  }) {
    return CreateEventState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdEvent: createdEvent ?? this.createdEvent,
      isNameAvailable: isNameAvailable ?? this.isNameAvailable,
    );
  }
}

/// Create event notifier
class CreateEventNotifier extends StateNotifier<CreateEventState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CreateEventNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const CreateEventState());

  /// Create event in a space
  Future<void> createEvent(EventCreationRequest request) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validate request
      final validationError = request.validate();
      if (validationError != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: validationError,
        );
        return;
      }

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must be signed in to create an event',
        );
        return;
      }

      // Create event
      Event event;
      if (request.isClubEvent && request.clubId != null) {
        // Create club event
        event = Event.createClubEvent(
          title: request.title,
          description: request.description,
          location: request.location,
          startDate: request.startDate,
          endDate: request.endDate,
          clubId: request.clubId!,
          clubName: request.organizerName,
          creatorId: user.uid,
          category: request.category,
          organizerEmail: request.organizerEmail.isNotEmpty
              ? request.organizerEmail
              : user.email ?? '',
          visibility: request.visibility,
          tags: request.tags,
          imageUrl: request.imageUrl,
        );
      } else {
        // Create user event
        event = Event.createUserEvent(
          title: request.title,
          description: request.description,
          location: request.location,
          startDate: request.startDate,
          endDate: request.endDate,
          userId: user.uid,
          organizerName: request.organizerName.isNotEmpty
              ? request.organizerName
              : user.displayName ?? 'Anonymous',
          category: request.category,
          organizerEmail: request.organizerEmail.isNotEmpty
              ? request.organizerEmail
              : user.email ?? '',
          visibility: request.visibility,
          tags: request.tags,
          imageUrl: request.imageUrl,
        );
      }

      // Save to Firestore - for club events
      if (event.source == EventSource.club && request.clubId != null) {
        // Get the space type
        final spaceSnapshot = await _firestore
            .collectionGroup('spaces')
            .where('id', isEqualTo: request.clubId)
            .limit(1)
            .get();

        if (spaceSnapshot.docs.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Space not found',
          );
          return;
        }

        final spacePath = spaceSnapshot.docs.first.reference.path;
        final spaceRef = _firestore.doc(spacePath);

        // Save event to space events collection
        await spaceRef.collection('events').doc(event.id).set({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'location': event.location,
          'startDate': event.startDate.toIso8601String(),
          'endDate': event.endDate.toIso8601String(),
          'organizerEmail': event.organizerEmail,
          'organizerName': event.organizerName,
          'category': event.category,
          'status': event.status,
          'link': event.link,
          'imageUrl': event.imageUrl,
          'tags': event.tags,
          'source': 'club',
          'createdBy': event.createdBy,
          'lastModified': FieldValue.serverTimestamp(),
          'visibility': event.visibility,
          'attendees': event.attendees,
        });

        // Update space with event count
        await spaceRef.update({
          'eventCount': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        });
      } 
      // Save to Firestore - for user events
      else {
        await _firestore.collection('events').doc(event.id).set({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'location': event.location,
          'startDate': event.startDate.toIso8601String(),
          'endDate': event.endDate.toIso8601String(),
          'organizerEmail': event.organizerEmail,
          'organizerName': event.organizerName,
          'category': event.category,
          'status': event.status,
          'link': event.link,
          'imageUrl': event.imageUrl,
          'tags': event.tags,
          'source': 'user',
          'createdBy': event.createdBy,
          'lastModified': FieldValue.serverTimestamp(),
          'visibility': event.visibility,
          'attendees': event.attendees,
        });
      }

      // Update user's created events
      await _firestore.collection('users').doc(user.uid).update({
        'createdEvents': FieldValue.arrayUnion([event.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        isLoading: false,
        createdEvent: event,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const CreateEventState();
  }
}

/// Provider for create event state
final createEventProvider =
    StateNotifierProvider<CreateEventNotifier, CreateEventState>((ref) {
  return CreateEventNotifier();
}); 