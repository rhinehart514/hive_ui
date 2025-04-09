# HIVE UI Optimized Firebase Schema

This document outlines the optimized Firebase data schema for the HIVE UI platform. The schema is designed for efficient querying, minimal data duplication, and adherence to Firebase best practices.

## Core Collections

### Users and Profiles

```
users/{userId}
│
├─ email: string
├─ displayName: string
├─ createdAt: timestamp
├─ lastSignInAt: timestamp
├─ role: string ("user" | "moderator" | "admin")
└─ isActive: boolean
```

```
user_profiles/{userId}
│
├─ displayName: string
├─ username: string
├─ bio: string
├─ profileImageUrl: string
├─ bannerImageUrl: string
├─ isPublicProfile: boolean
├─ interests: string[]
├─ university: string
├─ department: string
├─ followerCount: number
├─ followingCount: number
├─ influenceScore: number
├─ lastActive: timestamp
└─ createdAt: timestamp
```

### Social Connections

```
user_follows/{followId}
│
├─ followerId: string (reference to users collection)
├─ followedId: string (reference to users collection)
├─ createdAt: timestamp
└─ isMutual: boolean
```

```
friend_index/{userId1_userId2}
│
├─ user1Id: string
├─ user2Id: string
├─ createdAt: timestamp
└─ status: string ("pending" | "accepted")
```

```
mutual_connections/{userId1_userId2}
│
├─ user1Id: string
├─ user2Id: string
├─ mutualCount: number
├─ mutualIds: string[]
└─ updatedAt: timestamp
```

## Spaces and Events

```
spaces/{spaceId}
│
├─ name: string
├─ description: string
├─ imageUrl: string
├─ bannerUrl: string
├─ category: string
├─ tags: string[]
├─ creatorId: string
├─ admins: string[]
├─ moderators: string[]
├─ members: string[]
├─ memberCount: number
├─ isPublic: boolean
├─ createdAt: timestamp
├─ updatedAt: timestamp
│
└─ events/{eventId}
   │
   ├─ title: string
   ├─ description: string
   ├─ imageUrl: string
   ├─ startDate: timestamp
   ├─ endDate: timestamp
   ├─ location: {
   │  ├─ address: string
   │  ├─ city: string
   │  ├─ state: string
   │  ├─ country: string
   │  ├─ coordinates: {
   │  │  ├─ latitude: number
   │  │  └─ longitude: number
   │  │  }
   │  }
   ├─ category: string
   ├─ tags: string[]
   ├─ creatorId: string
   ├─ spaceId: string
   ├─ isPublic: boolean
   ├─ attendeeCount: number
   ├─ maxAttendees: number (optional)
   ├─ createdAt: timestamp
   └─ updatedAt: timestamp
```

## Optimization Indexes

```
space_leader_index/{userId_spaceId}
│
├─ userId: string
├─ spaceId: string
├─ role: string ("admin" | "moderator")
└─ joinedAt: timestamp
```

```
space_member_index/{userId_spaceId}
│
├─ userId: string
├─ spaceId: string
└─ joinedAt: timestamp
```

```
event_attendee_index/{userId_eventId}
│
├─ userId: string
├─ eventId: string
├─ status: string ("going" | "interested" | "not_going")
└─ updatedAt: timestamp
```

## Feed Optimization

```
feed_cache/{userId}
│
├─ events: [
│  ├─ {
│  │  ├─ id: string
│  │  ├─ title: string
│  │  ├─ imageUrl: string
│  │  ├─ startDate: timestamp
│  │  ├─ spaceId: string
│  │  ├─ spaceName: string
│  │  └─ attendeeCount: number
│  │  }
│  ]
├─ spaces: [
│  ├─ {
│  │  ├─ id: string
│  │  ├─ name: string
│  │  ├─ imageUrl: string
│  │  ├─ category: string
│  │  └─ memberCount: number
│  │  }
│  ]
├─ people: [
│  ├─ {
│  │  ├─ id: string
│  │  ├─ displayName: string
│  │  ├─ profileImageUrl: string
│  │  └─ mutualCount: number
│  │  }
│  ]
├─ lastUpdated: timestamp
└─ expiresAt: timestamp
```

```
public_events_index/{eventId}
│
├─ title: string
├─ imageUrl: string
├─ startDate: timestamp
├─ endDate: timestamp
├─ spaceId: string
├─ spaceName: string
├─ category: string
├─ tags: string[]
├─ attendeeCount: number
├─ isPublic: boolean
└─ location: {
   ├─ city: string
   └─ state: string
   }
```

## Analytics Optimization

```
user_activities/{activityId}
│
├─ userId: string
├─ action: string
├─ targetId: string
├─ targetType: string
├─ metadata: map
└─ timestamp: timestamp
```

```
user_engagement_metrics/{userId}
│
├─ userId: string
├─ totalActions: number
├─ sessionCount: number
├─ averageSessionDuration: number
├─ eventInteractions: number
├─ spaceInteractions: number
├─ postInteractions: number
├─ retentionScore: number
├─ currentStreak: number
├─ longestStreak: number
├─ lastActive: timestamp
└─ lastUpdated: timestamp
```

## Moderation Optimization

```
moderation_queue/{moderationId}
│
├─ contentId: string
├─ contentType: string
├─ contentText: string
├─ contentCreatorId: string
├─ initialReportId: string
├─ reportCount: number
├─ status: string ("pending" | "reviewed" | "actioned" | "dismissed")
├─ priority: number (1-5)
├─ toxicityScore: number (0-1)
├─ spamScore: number (0-1)
├─ moderationScore: number (0-1)
├─ reviewedBy: string (optional)
├─ reviewedAt: timestamp (optional)
├─ createdAt: timestamp
└─ updatedAt: timestamp
```

## Recommendation Optimization

```
user_recommendations/{userId}
│
├─ userId: string
├─ eventRecommendations: [
│  ├─ {
│  │  ├─ eventId: string
│  │  ├─ score: number
│  │  ├─ reason: string
│  │  └─ timestamp: timestamp
│  │  }
│  ]
├─ spaceRecommendations: [
│  ├─ {
│  │  ├─ spaceId: string
│  │  ├─ score: number
│  │  ├─ reason: string
│  │  └─ timestamp: timestamp
│  │  }
│  ]
├─ peopleRecommendations: [
│  ├─ {
│  │  ├─ userId: string
│  │  ├─ score: number
│  │  ├─ reason: string
│  │  └─ timestamp: timestamp
│  │  }
│  ]
├─ generatedAt: timestamp
└─ expiresAt: timestamp
```

## Social Graph Analytics

```
user_social_graphs/{userId}
│
├─ userId: string
├─ followerCount: number
├─ followingCount: number
├─ mutualConnectionsMap: map<userId, count>
├─ influenceScore: number
├─ strongConnections: string[]
├─ clusters: string[]
└─ lastUpdated: timestamp
```

## Query Optimizations

1. **Feed Queries**: The feed cache and public indexes reduce the number of reads for frequently accessed feed data

2. **Collection Group Queries**: Used for efficiently querying all events, spaces, and posts across the platform

3. **Denormalized Relationship Data**: Relationship data is stored in both directions for more efficient querying

4. **Counter Caching**: Member counts and follower counts are stored on documents to avoid expensive count queries

5. **Index Documents**: Special index documents (e.g., space_member_index) enable fast membership checks without complex queries

6. **TTL Fields**: Expiration timestamps on cache documents allow for automatic cleanup

7. **Composite Indexes**: Defined in firestore.indexes.json for common query patterns, such as:
   - Events by startDate and category
   - Spaces by category and memberCount
   - User activities by userId and timestamp
   - Trending content by score

## Size Optimization

1. **Minimal Public Indexes**: Public indexes contain only the minimum fields needed for display

2. **Feed Pagination**: Feed data is paginated to limit document size

3. **Batch Writes**: All multi-document updates use batched writes

4. **Selective Denormalization**: Only frequently accessed data is denormalized

5. **Cache TTL**: Cache documents have expiration times to avoid storing stale data 