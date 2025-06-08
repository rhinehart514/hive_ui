// HIVE vBETA Spaces System - Foundation Types
// Based on mobile app SpaceEntity and our confirmed decisions

export type SpaceType = 
  | 'academic'        // Class/major/department spaces
  | 'residential'     // Dorm/living spaces  
  | 'org'            // Student organizations
  | 'community'      // General interest groups
  | 'hive_exclusive' // HIVE-created spaces

export type SpaceLifecycleState = 
  | 'created'   // Just created, no builder yet
  | 'active'    // Has approved builder + tools placed
  | 'dormant'   // No tool interactions for 14+ days (preview state)
  | 'archived'  // Manually archived

export type SpaceClaimStatus = 
  | 'unclaimed'   // Pre-seeded space with no leader
  | 'pending'     // Builder application submitted, awaiting approval
  | 'claimed'     // Has approved builder(s)
  | 'not_required' // HIVE-exclusive spaces

export type BuilderRole = 
  | 'primary'     // Original builder or main leader
  | 'secondary'   // Additional builders (max 4 total)

export type ToolVisibility = 
  | 'all'         // Visible to all space members
  | 'builders_only' // Only builders can see/use

export interface SpaceMetrics {
  spaceId: string;
  memberCount: number;
  activeMembers: number;
  weeklyEvents: number;
  monthlyEngagements: number;
  lastActivity: Date;
  hasNewContent: boolean;
  isTrending: boolean;
  isSurging: boolean; // NEW: Tool hit SurgeMeter threshold
  activeMembers24h: string[];
  activityScores: Record<string, number>;
  engagementScore: number;
  connectedFriends: string[];
  needsIntroduction: boolean;
}

export interface Tool {
  id: string;
  name: string;
  description: string;
  type: 'preset' | 'custom';
  templateId?: string; // Reference to one of 5 templates
  elements: ToolElement[];
  visibility: ToolVisibility;
  createdBy: string; // Builder user ID
  spaceId: string;
  isActive: boolean;
  placedAt: Date;
  lastInteraction?: Date;
  interactionCount: number;
  surgeScore: number; // Track for SurgeMeter
  customConfig?: Record<string, any>;
}

export interface ToolElement {
  id: string;
  type: string; // 'text_input' | 'poll' | 'event_card' | 'file_upload' | etc.
  config: Record<string, any>;
  position: number; // Order in tool
  isRequired: boolean;
}

// vBETA: 5 Core Tool Templates
export interface ToolTemplate {
  id: string;
  name: string;
  description: string;
  category: 'social' | 'productivity' | 'coordination' | 'feedback';
  defaultElements: ToolElement[];
  isCustomizable: boolean;
  previewImage?: string;
}

export interface BuilderRequest {
  id: string;
  userId: string;
  spaceId: string;
  requestType: 'standard' | 'org_officer' | 'ra' | 'orientation_leader';
  justification: string;
  experienceLevel: 'beginner' | 'intermediate' | 'advanced';
  proposedTools: string[]; // Template IDs they want to use
  status: 'pending' | 'approved' | 'denied';
  submittedAt: Date;
  reviewedAt?: Date;
  reviewedBy?: string; // Admin user ID
  adminNotes?: string;
  
  // Special handling flags
  requiresExtraAttention: boolean; // For RAs and Orientation Leaders
  isOrgOfficer: boolean; // Pre-seeded org officer
}

export interface Space {
  id: string;
  name: string;
  description: string;
  spaceType: SpaceType;
  lifecycleState: SpaceLifecycleState;
  claimStatus: SpaceClaimStatus;
  
  // Basic Info
  iconCodePoint: number; // Material icon reference
  imageUrl?: string;
  bannerUrl?: string;
  tags: string[];
  
  // Members & Builders
  memberCount: number;
  members: string[]; // User IDs
  builders: Array<{
    userId: string;
    role: BuilderRole;
    approvedAt: Date;
    requestId: string;
  }>; // Max 4 builders for vBETA
  
  // Activity Tracking  
  lastActivityAt?: Date;
  metrics: SpaceMetrics;
  
  // Tools Integration - CORE FOR HIVELAB
  defaultTools: Tool[]; // Post, Chat, Events, Join - always present
  customTools: Tool[]; // Builder-created tools
  templateToolsUsed: string[]; // Track which templates are popular
  
  // Permissions & Settings
  isPrivate: boolean;
  isPreSeeded: boolean; // Came from UB data, not user-created
  rssEventSource?: string; // For academic/org spaces
  
  // Administrative
  createdAt: Date;
  updatedAt: Date;
  customData: Record<string, any>;
  
  // vBETA Constraints
  hiveExclusive: boolean; // HIVE-created vs student-driven
}

// Space Discovery & Recommendation Types
export interface SpaceRecommendation {
  spaceId: string;
  reason: 'major_match' | 'dorm_match' | 'interest_match' | 'friend_activity';
  confidence: number; // 0-1
  matchingCriteria: string[];
}

export interface SpaceDiscoveryFilters {
  spaceTypes: SpaceType[];
  lifecycleStates: SpaceLifecycleState[];
  hasActivity: boolean;
  needsBuilders: boolean;
  searchQuery?: string;
  tags?: string[];
}

// Admin Dashboard Types for Manual Builder Approval
export interface AdminDashboardData {
  pendingBuilderRequests: BuilderRequest[];
  flaggedRequests: BuilderRequest[]; // RAs, Orientation Leaders  
  spaceActivity: Array<{
    spaceId: string;
    spaceName: string;
    lifecycleState: SpaceLifecycleState;
    lastActivity: Date;
    builderCount: number;
    memberCount: number;
    toolCount: number;
  }>;
  surgingTools: Tool[]; // Tools hitting SurgeMeter threshold
  platformMetrics: {
    totalSpaces: number;
    activeSpaces: number;
    totalBuilders: number;
    totalTools: number;
    weeklyToolPlacements: number;
  };
}

// Space Activation Logic - Based on our decisions
export interface SpaceActivationTrigger {
  trigger: 'first_tool_placed'; // Confirmed: First builder places any tool
  sustainmentRule: 'fourteen_day_dormancy'; // No tool interactions for 14 days → dormant
  surgeDetection: 'platform_surge_meter'; // Tool hits platform-wide threshold
}

export default Space; 