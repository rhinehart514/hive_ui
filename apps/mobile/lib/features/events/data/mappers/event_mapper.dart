import 'package:hive_ui/features/events/domain/entities/event.dart' as entity;
import 'package:hive_ui/models/event.dart' as model;

/// Mapper class to convert between Event model and Event entity
class EventMapper {
  /// Convert from model to entity
  static entity.Event toEntity(model.Event event) {
    return entity.Event(
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
      organizerEmail: event.organizerEmail,
      organizerName: event.organizerName,
      category: event.category,
      status: event.status,
      link: event.link,
      originalTitle: event.originalTitle,
      imageUrl: event.imageUrl,
      tags: event.tags,
      source: _mapEventSource(event.source),
      createdBy: event.createdBy,
      lastModified: event.lastModified,
      visibility: event.visibility,
      attendees: event.attendees,
      spaceId: event.spaceId,
      reposts: event.reposts,
      organizer: event.organizer != null ? _mapEventOrganizer(event.organizer!) : null,
      isAttending: event.isAttending,
      capacity: event.capacity,
      waitlist: event.waitlist,
      state: _mapEventLifecycleState(event.state),
      stateUpdatedAt: event.stateUpdatedAt,
      stateHistory: event.stateHistory.map(_mapEventStateHistoryEntry).toList(),
      published: event.published,
      isBoosted: event.isBoosted,
      boostTimestamp: event.boostTimestamp,
      isHoneyMode: event.isHoneyMode,
      honeyModeTimestamp: event.honeyModeTimestamp,
    );
  }

  /// Convert from entity to model
  static model.Event toModel(entity.Event event) {
    return model.Event(
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
      organizerEmail: event.organizerEmail,
      organizerName: event.organizerName,
      category: event.category,
      status: event.status,
      link: event.link,
      originalTitle: event.originalTitle,
      imageUrl: event.imageUrl,
      tags: event.tags,
      source: _mapEventSourceBack(event.source),
      createdBy: event.createdBy,
      lastModified: event.lastModified,
      visibility: event.visibility,
      attendees: event.attendees,
      spaceId: event.spaceId,
      reposts: event.reposts,
      organizer: event.organizer != null ? _mapEventOrganizerBack(event.organizer!) : null,
      isAttending: event.isAttending,
      capacity: event.capacity,
      waitlist: event.waitlist,
      state: _mapEventLifecycleStateBack(event.state),
      stateUpdatedAt: event.stateUpdatedAt,
      stateHistory: event.stateHistory.map(_mapEventStateHistoryEntryBack).toList(),
      published: event.published,
      isBoosted: event.isBoosted,
      boostTimestamp: event.boostTimestamp,
      isHoneyMode: event.isHoneyMode,
      honeyModeTimestamp: event.honeyModeTimestamp,
    );
  }

  /// Map EventSource from model to entity
  static entity.EventSource _mapEventSource(model.EventSource source) {
    switch (source) {
      case model.EventSource.external:
        return entity.EventSource.external;
      case model.EventSource.user:
        return entity.EventSource.user;
      case model.EventSource.club:
        return entity.EventSource.club;
    }
  }

  /// Map EventSource from entity to model
  static model.EventSource _mapEventSourceBack(entity.EventSource source) {
    switch (source) {
      case entity.EventSource.external:
        return model.EventSource.external;
      case entity.EventSource.user:
        return model.EventSource.user;
      case entity.EventSource.club:
        return model.EventSource.club;
    }
  }

  /// Map EventLifecycleState from model to entity
  static entity.EventLifecycleState _mapEventLifecycleState(model.EventLifecycleState state) {
    switch (state) {
      case model.EventLifecycleState.draft:
        return entity.EventLifecycleState.draft;
      case model.EventLifecycleState.published:
        return entity.EventLifecycleState.published;
      case model.EventLifecycleState.live:
        return entity.EventLifecycleState.live;
      case model.EventLifecycleState.completed:
        return entity.EventLifecycleState.completed;
      case model.EventLifecycleState.archived:
        return entity.EventLifecycleState.archived;
    }
  }

  /// Map EventLifecycleState from entity to model
  static model.EventLifecycleState _mapEventLifecycleStateBack(entity.EventLifecycleState state) {
    switch (state) {
      case entity.EventLifecycleState.draft:
        return model.EventLifecycleState.draft;
      case entity.EventLifecycleState.published:
        return model.EventLifecycleState.published;
      case entity.EventLifecycleState.live:
        return model.EventLifecycleState.live;
      case entity.EventLifecycleState.completed:
        return model.EventLifecycleState.completed;
      case entity.EventLifecycleState.archived:
        return model.EventLifecycleState.archived;
    }
  }

  /// Map EventOrganizer from model to entity
  static entity.EventOrganizer _mapEventOrganizer(model.EventOrganizer organizer) {
    return entity.EventOrganizer(
      id: organizer.id,
      name: organizer.name,
      isVerified: organizer.isVerified,
      imageUrl: organizer.imageUrl,
    );
  }

  /// Map EventOrganizer from entity to model
  static model.EventOrganizer _mapEventOrganizerBack(entity.EventOrganizer organizer) {
    return model.EventOrganizer(
      id: organizer.id,
      name: organizer.name,
      isVerified: organizer.isVerified,
      imageUrl: organizer.imageUrl,
    );
  }

  /// Map EventStateHistoryEntry from model to entity
  static entity.EventStateHistoryEntry _mapEventStateHistoryEntry(model.EventStateHistoryEntry entry) {
    return entity.EventStateHistoryEntry(
      state: _mapEventLifecycleState(entry.state),
      timestamp: entry.timestamp,
      updatedBy: entry.updatedBy,
      transitionType: entry.transitionType,
    );
  }

  /// Map EventStateHistoryEntry from entity to model
  static model.EventStateHistoryEntry _mapEventStateHistoryEntryBack(entity.EventStateHistoryEntry entry) {
    return model.EventStateHistoryEntry(
      state: _mapEventLifecycleStateBack(entry.state),
      timestamp: entry.timestamp,
      updatedBy: entry.updatedBy,
      transitionType: entry.transitionType,
    );
  }
} 