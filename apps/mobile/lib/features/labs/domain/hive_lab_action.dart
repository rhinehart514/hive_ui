import 'package:equatable/equatable.dart';

/// Domain entity representing an action in the HiveLab system
class HiveLabAction extends Equatable {
  /// Unique identifier for the action
  final String id;
  
  /// Title of the action
  final String title;
  
  /// Description of what the action does
  final String description;
  
  /// Type of action (e.g., "feature", "experiment", "feedback", "survey")
  final HiveLabActionType type;
  
  /// Icon type to display (affects color and icon selection)
  final HiveLabActionIconType iconType;
  
  /// How high to prioritize this action in the FAB menu (1-5, 5 being highest)
  final int priority;
  
  /// Whether this is a premium action (requires Verified+ status)
  final bool isPremium;
  
  /// Time when this action becomes available
  final DateTime? availableFrom;
  
  /// Time when this action expires
  final DateTime? expiresAt;
  
  /// Any extra data associated with this action
  final Map<String, dynamic>? extraData;

  /// Constructor
  const HiveLabAction({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.iconType = HiveLabActionIconType.idea,
    this.priority = 3,
    this.isPremium = false,
    this.availableFrom,
    this.expiresAt,
    this.extraData,
  });

  /// Check if the action is currently available based on time constraints
  bool isAvailable() {
    final now = DateTime.now();
    
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false;
    }
    
    if (expiresAt != null && now.isAfter(expiresAt!)) {
      return false;
    }
    
    return true;
  }
  
  @override
  List<Object?> get props => [
    id, 
    title, 
    description, 
    type, 
    iconType, 
    priority, 
    isPremium, 
    availableFrom, 
    expiresAt
  ];
}

/// Types of HiveLab actions
enum HiveLabActionType {
  /// For submitting new ideas
  ideaSubmission,
  
  /// For participating in experimental features
  experiment,
  
  /// For providing general feedback
  feedback,
  
  /// For participating in surveys
  survey,
  
  /// For joining a specific lab project
  labProject,
  
  /// For voting on existing ideas
  ideaVoting,
  
  /// For testing beta features
  betaTesting,
}

/// Icon types for the HiveLab actions
enum HiveLabActionIconType {
  /// Light bulb icon - for ideas
  idea,
  
  /// Lab flask icon - for experiments
  experiment,
  
  /// Chat bubble - for feedback
  feedback,
  
  /// Poll/chart - for surveys
  survey,
  
  /// Group/team - for collaborative projects
  team,
  
  /// Beta symbol - for beta testing
  beta,
} 