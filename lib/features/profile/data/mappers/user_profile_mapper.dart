import 'package:hive_ui/features/profile/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';

/// Mapper class for converting between domain UserProfile and model UserProfile
class UserProfileMapper {
  /// Convert a model UserProfile to a domain UserProfile
  static domain.UserProfile mapToDomain(model.UserProfile modelProfile) {
    // Determine verification level based on verification status
    VerificationLevel verificationLevel = VerificationLevel.public;
    if (modelProfile.isVerifiedPlus) {
      verificationLevel = VerificationLevel.verifiedPlus;
    } else if (modelProfile.isVerified) {
      verificationLevel = VerificationLevel.verified;
    } else {
      verificationLevel = VerificationLevel.public;
    }
    
    // Determine account tier
    domain.AccountTier accountTier = domain.AccountTier.standard;
    if (modelProfile.isVerifiedPlus) {
      accountTier = domain.AccountTier.verifiedPlus;
    } else if (modelProfile.isVerified) {
      accountTier = domain.AccountTier.verified;
    }
    
    // Map to domain entity
    return domain.UserProfile(
      id: modelProfile.id,
      displayName: modelProfile.displayName,
      email: modelProfile.email,
      bio: modelProfile.bio,
      location: modelProfile.residence,
      photoUrl: modelProfile.profileImageUrl,
      interests: modelProfile.interests ?? [],
      isPublic: modelProfile.isPublic,
      verificationLevel: verificationLevel,
      createdAt: modelProfile.createdAt,
      updatedAt: modelProfile.updatedAt,
      accountTier: accountTier,
    );
  }
  
  /// Convert a domain UserProfile to a model UserProfile
  static model.UserProfile mapToModel(domain.UserProfile domainProfile) {
    // Handle fields that may not be in the domain entity but are required in the model
    return model.UserProfile(
      id: domainProfile.id,
      username: domainProfile.id, // Use ID as fallback
      displayName: domainProfile.displayName,
      email: domainProfile.email ?? '',
      bio: domainProfile.bio,
      residence: domainProfile.location ?? '',
      profileImageUrl: domainProfile.photoUrl,
      interests: domainProfile.interests,
      year: '', // No direct mapping
      major: '', // No direct mapping
      eventCount: 0, // No direct mapping
      spaceCount: 0, // No direct mapping
      friendCount: 0, // No direct mapping
      createdAt: domainProfile.createdAt ?? DateTime.now(),
      updatedAt: domainProfile.updatedAt ?? DateTime.now(),
      isPublic: domainProfile.isPublic,
      isVerified: domainProfile.verificationLevel == VerificationLevel.verified || 
                 domainProfile.verificationLevel == VerificationLevel.verifiedPlus,
      isVerifiedPlus: domainProfile.verificationLevel == VerificationLevel.verifiedPlus,
    );
  }
  
  /// Map a list of model UserProfiles to domain UserProfiles
  static List<domain.UserProfile> mapListToDomain(List<model.UserProfile> modelProfiles) {
    return modelProfiles.map(mapToDomain).toList();
  }
  
  /// Map a list of domain UserProfiles to model UserProfiles
  static List<model.UserProfile> mapListToModel(List<domain.UserProfile> domainProfiles) {
    return domainProfiles.map(mapToModel).toList();
  }
} 