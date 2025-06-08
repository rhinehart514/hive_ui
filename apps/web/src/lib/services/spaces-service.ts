// HIVE vBETA Spaces Service - Web Implementation
// Handles space discovery, builder management, and tool coordination

import { 
  Space, 
  SpaceDiscoveryFilters, 
  SpaceRecommendation, 
  BuilderRequest, 
  Tool,
  SpaceLifecycleState,
  AdminDashboardData 
} from '../types/spaces';
import { User } from '../types/auth';

// Firestore paths (matching mobile app patterns)
const FIRESTORE_PATHS = {
  spaces: 'spaces',
  users: 'users', 
  builderRequests: 'builder_requests',
  tools: 'tools',
  spaceMembers: 'space_members'
} as const;

export class SpacesService {
  
  // SPACE DISCOVERY & RECOMMENDATIONS
  
  /**
   * Get personalized space recommendations based on user profile
   * Matches mobile app auto-join logic
   */
  static async getSpaceRecommendations(user: User): Promise<SpaceRecommendation[]> {
    const recommendations: SpaceRecommendation[] = [];
    
    // Major-based recommendations (academic spaces)
    if (user.major) {
      const majorSpaces = await this.findSpacesByType('academic', {
        tags: [user.major.toLowerCase()],
        lifecycleStates: ['active', 'created']
      });
      
      majorSpaces.forEach(space => {
        recommendations.push({
          spaceId: space.id,
          reason: 'major_match',
          confidence: 0.9,
          matchingCriteria: [user.major!]
        });
      });
    }
    
    // Residential matching (dorm spaces)
    if (user.residentialStatus && user.residentialStatus !== 'off_campus') {
      const dormSpaces = await this.findSpacesByType('residential', {
        tags: [user.residentialStatus],
        lifecycleStates: ['active', 'created']  
      });
      
      dormSpaces.forEach(space => {
        recommendations.push({
          spaceId: space.id,
          reason: 'dorm_match', 
          confidence: 0.8,
          matchingCriteria: [user.residentialStatus!]
        });
      });
    }
    
    // Year-based recommendations (class cohorts)
    if (user.graduationYear) {
      const yearSpaces = await this.findSpacesByType('community', {
        tags: [`class_of_${user.graduationYear}`],
        lifecycleStates: ['active', 'created']
      });
      
      yearSpaces.forEach(space => {
        recommendations.push({
          spaceId: space.id,
          reason: 'interest_match',
          confidence: 0.6,
          matchingCriteria: [`Class of ${user.graduationYear}`]
        });
      });
    }
    
    return recommendations.sort((a, b) => b.confidence - a.confidence);
  }
  
  /**
   * Discover spaces with filters
   */
  static async discoverSpaces(filters: SpaceDiscoveryFilters): Promise<Space[]> {
    // Implementation would query Firestore with filters
    // For now, return mock data structure
    return [];
  }
  
  /**
   * Find spaces by type with additional filters
   */
  private static async findSpacesByType(
    spaceType: string, 
    additionalFilters: Partial<SpaceDiscoveryFilters>
  ): Promise<Space[]> {
    // Mock implementation - would query Firestore
    return [];
  }
  
  // BUILDER REQUEST MANAGEMENT
  
  /**
   * Submit builder request for a space
   * Implements our manual approval workflow
   */
  static async submitBuilderRequest(
    userId: string,
    spaceId: string,
    requestData: Partial<BuilderRequest>
  ): Promise<{ success: boolean; requestId?: string; error?: string }> {
    
    try {
      // Check if user already has pending/approved request for this space
      const existingRequest = await this.getExistingBuilderRequest(userId, spaceId);
      if (existingRequest) {
        return { 
          success: false, 
          error: 'You already have a request for this space' 
        };
      }
      
      // Check builder limit (max 4 per space for vBETA)
      const space = await this.getSpaceById(spaceId);
      if (space && space.builders.length >= 4) {
        return {
          success: false,
          error: 'This space already has the maximum number of builders (4)'
        };
      }
      
      const builderRequest: BuilderRequest = {
        id: generateId(),
        userId,
        spaceId,
        requestType: requestData.requestType || 'standard',
        justification: requestData.justification || '',
        experienceLevel: requestData.experienceLevel || 'beginner',
        proposedTools: requestData.proposedTools || [],
        status: 'pending',
        submittedAt: new Date(),
        
        // Flag special cases for manual attention
        requiresExtraAttention: ['ra', 'orientation_leader'].includes(requestData.requestType || ''),
        isOrgOfficer: requestData.requestType === 'org_officer'
      };
      
      // Save to Firestore
      await this.saveBuilderRequest(builderRequest);
      
      // Send notification to admins if requires extra attention
      if (builderRequest.requiresExtraAttention) {
        await this.notifyAdminsOfSpecialRequest(builderRequest);
      }
      
      return { success: true, requestId: builderRequest.id };
      
    } catch (error) {
      return { 
        success: false, 
        error: 'Failed to submit builder request. Please try again.' 
      };
    }
  }
  
  /**
   * Admin function to approve/deny builder requests
   */
  static async reviewBuilderRequest(
    requestId: string,
    adminUserId: string,
    decision: 'approved' | 'denied',
    adminNotes?: string
  ): Promise<{ success: boolean; error?: string }> {
    
    try {
      const request = await this.getBuilderRequestById(requestId);
      if (!request) {
        return { success: false, error: 'Request not found' };
      }
      
      // Update request status
      const updatedRequest: BuilderRequest = {
        ...request,
        status: decision,
        reviewedAt: new Date(),
        reviewedBy: adminUserId,
        adminNotes: adminNotes || ''
      };
      
      await this.updateBuilderRequest(updatedRequest);
      
      // If approved, add user as builder to space
      if (decision === 'approved') {
        await this.addBuilderToSpace(request.spaceId, request.userId, requestId);
        
        // Check if this is the first builder - triggers space activation
        const space = await this.getSpaceById(request.spaceId);
        if (space && space.lifecycleState === 'created' && space.builders.length === 1) {
          await this.updateSpaceLifecycle(request.spaceId, 'active');
        }
      }
      
      // Notify user of decision
      await this.notifyUserOfBuilderDecision(request.userId, decision, request.spaceId);
      
      return { success: true };
      
    } catch (error) {
      return { success: false, error: 'Failed to review request' };
    }
  }
  
  // TOOL MANAGEMENT
  
  /**
   * Place a tool in a space (triggers space activation)
   * This is the key action that moves spaces from created → active
   */
  static async placeToolInSpace(
    spaceId: string,
    builderId: string,
    tool: Tool
  ): Promise<{ success: boolean; error?: string }> {
    
    try {
      // Verify builder has permission for this space
      const hasPermission = await this.verifyBuilderPermission(builderId, spaceId);
      if (!hasPermission) {
        return { success: false, error: 'You do not have builder permissions for this space' };
      }
      
      // Save tool
      const toolWithMetadata: Tool = {
        ...tool,
        id: generateId(),
        spaceId,
        createdBy: builderId,
        placedAt: new Date(),
        isActive: true,
        interactionCount: 0,
        surgeScore: 0
      };
      
      await this.saveTool(toolWithMetadata);
      
      // Update space with new tool
      await this.addToolToSpace(spaceId, toolWithMetadata.id);
      
      // CRITICAL: First tool placement activates space
      const space = await this.getSpaceById(spaceId);
      if (space && space.lifecycleState === 'created') {
        await this.updateSpaceLifecycle(spaceId, 'active');
        await this.updateSpaceLastActivity(spaceId, new Date());
      }
      
      return { success: true };
      
    } catch (error) {
      return { success: false, error: 'Failed to place tool in space' };
    }
  }
  
  /**
   * Track tool interaction (prevents dormancy)
   */
  static async recordToolInteraction(toolId: string, userId: string): Promise<void> {
    try {
      const tool = await this.getToolById(toolId);
      if (!tool) return;
      
      // Update tool interaction metrics
      await this.incrementToolInteractionCount(toolId);
      await this.updateToolLastInteraction(toolId, new Date());
      
      // Update space last activity (prevents 14-day dormancy)
      await this.updateSpaceLastActivity(tool.spaceId, new Date());
      
      // Calculate surge score (simplified for vBETA)
      const newSurgeScore = await this.calculateToolSurgeScore(toolId);
      await this.updateToolSurgeScore(toolId, newSurgeScore);
      
      // Check if tool hits surge threshold
      if (newSurgeScore >= SURGE_THRESHOLD) {
        await this.markSpaceAsSurging(tool.spaceId);
      }
      
    } catch (error) {
      console.error('Failed to record tool interaction:', error);
    }
  }
  
  // SPACE LIFECYCLE MANAGEMENT
  
  /**
   * Check for dormant spaces (no tool interactions for 14 days)
   * Should be run as a scheduled function
   */
  static async checkForDormantSpaces(): Promise<void> {
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
    
    const activeSpaces = await this.getSpacesByLifecycleState('active');
    
    for (const space of activeSpaces) {
      if (space.lastActivityAt && space.lastActivityAt < fourteenDaysAgo) {
        await this.updateSpaceLifecycle(space.id, 'dormant');
      }
    }
  }
  
  /**
   * Get admin dashboard data for manual management
   */
  static async getAdminDashboardData(): Promise<AdminDashboardData> {
    const [
      pendingRequests,
      flaggedRequests,
      spaceActivity,
      surgingTools,
      platformMetrics
    ] = await Promise.all([
      this.getPendingBuilderRequests(),
      this.getFlaggedBuilderRequests(),
      this.getSpaceActivitySummary(),
      this.getSurgingTools(),
      this.getPlatformMetrics()
    ]);
    
    return {
      pendingBuilderRequests: pendingRequests,
      flaggedRequests: flaggedRequests,
      spaceActivity: spaceActivity,
      surgingTools: surgingTools,
      platformMetrics: platformMetrics
    };
  }
  
  // PRIVATE HELPER METHODS
  
  private static async getSpaceById(spaceId: string): Promise<Space | null> {
    // Mock implementation - would query Firestore
    return null;
  }
  
  private static async getExistingBuilderRequest(userId: string, spaceId: string): Promise<BuilderRequest | null> {
    // Mock implementation
    return null;
  }
  
  private static async saveBuilderRequest(request: BuilderRequest): Promise<void> {
    // Mock implementation - would save to Firestore
  }
  
  private static async getBuilderRequestById(requestId: string): Promise<BuilderRequest | null> {
    // Mock implementation
    return null;
  }
  
  private static async updateBuilderRequest(request: BuilderRequest): Promise<void> {
    // Mock implementation
  }
  
  private static async addBuilderToSpace(spaceId: string, userId: string, requestId: string): Promise<void> {
    // Mock implementation
  }
  
  private static async updateSpaceLifecycle(spaceId: string, newState: SpaceLifecycleState): Promise<void> {
    // Mock implementation
  }
  
  private static async verifyBuilderPermission(builderId: string, spaceId: string): Promise<boolean> {
    // Mock implementation
    return true;
  }
  
  private static async saveTool(tool: Tool): Promise<void> {
    // Mock implementation
  }
  
  private static async addToolToSpace(spaceId: string, toolId: string): Promise<void> {
    // Mock implementation
  }
  
  private static async updateSpaceLastActivity(spaceId: string, timestamp: Date): Promise<void> {
    // Mock implementation
  }
  
  private static async getToolById(toolId: string): Promise<Tool | null> {
    // Mock implementation
    return null;
  }
  
  private static async incrementToolInteractionCount(toolId: string): Promise<void> {
    // Mock implementation
  }
  
  private static async updateToolLastInteraction(toolId: string, timestamp: Date): Promise<void> {
    // Mock implementation
  }
  
  private static async calculateToolSurgeScore(toolId: string): Promise<number> {
    // Mock implementation - simplified surge calculation
    return 0;
  }
  
  private static async updateToolSurgeScore(toolId: string, score: number): Promise<void> {
    // Mock implementation
  }
  
  private static async markSpaceAsSurging(spaceId: string): Promise<void> {
    // Mock implementation
  }
  
  private static async getSpacesByLifecycleState(state: SpaceLifecycleState): Promise<Space[]> {
    // Mock implementation
    return [];
  }
  
  private static async notifyAdminsOfSpecialRequest(request: BuilderRequest): Promise<void> {
    // Mock implementation - would send notifications to admin dashboard
  }
  
  private static async notifyUserOfBuilderDecision(userId: string, decision: string, spaceId: string): Promise<void> {
    // Mock implementation - would send user notification
  }
  
  private static async getPendingBuilderRequests(): Promise<BuilderRequest[]> {
    // Mock implementation
    return [];
  }
  
  private static async getFlaggedBuilderRequests(): Promise<BuilderRequest[]> {
    // Mock implementation
    return [];
  }
  
  private static async getSpaceActivitySummary(): Promise<any[]> {
    // Mock implementation
    return [];
  }
  
  private static async getSurgingTools(): Promise<Tool[]> {
    // Mock implementation
    return [];
  }
  
  private static async getPlatformMetrics(): Promise<any> {
    // Mock implementation
    return {
      totalSpaces: 0,
      activeSpaces: 0,
      totalBuilders: 0,
      totalTools: 0,
      weeklyToolPlacements: 0
    };
  }
}

// Helper functions
function generateId(): string {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

// Constants
const SURGE_THRESHOLD = 100; // Simplified surge detection threshold

export default SpacesService; 