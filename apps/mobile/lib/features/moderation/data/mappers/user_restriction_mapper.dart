import 'package:hive_ui/features/moderation/data/models/user_restriction_model.dart';
import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';

/// Mapper for converting between UserRestrictionEntity and UserRestrictionModel
class UserRestrictionMapper {
  /// Convert from model to entity
  static UserRestrictionEntity fromModel(UserRestrictionModel model) {
    return UserRestrictionEntity(
      id: model.id,
      userId: model.userId,
      isActive: model.isActive,
      reason: model.reason,
      restrictedBy: model.restrictedBy,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
      notes: model.notes,
      restrictionHistory: model.restrictionHistory?.map((item) => fromPreviousRestrictionModel(item)).toList(),
    );
  }
  
  /// Convert from entity to model
  static UserRestrictionModel toModel(UserRestrictionEntity entity) {
    return UserRestrictionModel(
      id: entity.id,
      userId: entity.userId,
      isActive: entity.isActive,
      reason: entity.reason,
      restrictedBy: entity.restrictedBy,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      notes: entity.notes,
      restrictionHistory: entity.restrictionHistory?.map((item) => toPreviousRestrictionModel(item)).toList(),
    );
  }
  
  /// Convert PreviousRestrictionModel to PreviousRestriction
  static PreviousRestriction fromPreviousRestrictionModel(PreviousRestrictionModel model) {
    return PreviousRestriction(
      createdAt: model.createdAt,
      endedAt: model.endedAt,
      reason: model.reason,
      restrictedBy: model.restrictedBy,
      removedBy: model.removedBy,
      removalReason: model.removalReason,
    );
  }
  
  /// Convert PreviousRestriction to PreviousRestrictionModel
  static PreviousRestrictionModel toPreviousRestrictionModel(PreviousRestriction entity) {
    return PreviousRestrictionModel(
      createdAt: entity.createdAt,
      endedAt: entity.endedAt,
      reason: entity.reason,
      restrictedBy: entity.restrictedBy,
      removedBy: entity.removedBy,
      removalReason: entity.removalReason,
    );
  }
} 