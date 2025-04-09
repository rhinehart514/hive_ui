# Identity Tiers & Role Governance Integration Plan

## Overview

This document outlines the specific implementation steps needed to connect the Identity Tiers & Role Governance domain logic to the UI layer. This integration is a **Critical Launch Item** with ~80% domain layer completion but 0% UI integration currently.

## Key Integration Points

1. Role-Based Feature Access
2. Verified+ Privileges
3. Role Upgrading Visualization
4. Role Verification Status

## Current Architecture Status

### Domain Layer (~80% Complete)
- Role entities and models defined
- Authentication repository implemented
- Verification status models created
- Role upgrade workflows defined (backend)
- Permission rules established in business logic

### UI Layer (0% Complete)
- Basic UI components exist but not connected to role system
- Permission checks not implemented in UI
- Role visualization not implemented
- Role upgrade flows not connected

## Implementation Plan

### Phase 1: Role State Provider & Consumer

**Objective**: Create a central role state provider that all UI components can access.

#### Steps:

1. **Create RoleStateProvider using Riverpod**
   ```dart
   final userRoleProvider = StateNotifierProvider<UserRoleNotifier, UserRoleState>((ref) {
     final authRepository = ref.watch(authRepositoryProvider);
     return UserRoleNotifier(authRepository);
   });
   
   class UserRoleState {
     final RoleType roleType; // Public, Verified, Verified+
     final VerificationStatus verificationStatus; // none, pending, approved
     final List<String> managedSpaceIds; // Spaces where user has Verified+ status
     
     // Constructor, copyWith, etc.
   }
   
   class UserRoleNotifier extends StateNotifier<UserRoleState> {
     final AuthRepository _authRepository;
     StreamSubscription? _roleSubscription;
     
     UserRoleNotifier(this._authRepository) : super(UserRoleState.initial()) {
       _initializeRoleState();
     }
     
     void _initializeRoleState() {
       _roleSubscription = _authRepository.userRoleStream.listen((roleData) {
         state = state.copyWith(
           roleType: roleData.roleType,
           verificationStatus: roleData.verificationStatus,
           managedSpaceIds: roleData.managedSpaceIds,
         );
       });
     }
     
     @override
     void dispose() {
       _roleSubscription?.cancel();
       super.dispose();
     }
   }
   ```

2. **Create Permission Utility**
   ```dart
   class PermissionUtil {
     static bool canCreateSpace(RoleType role) => 
         role == RoleType.verified || role == RoleType.verifiedPlus;
         
     static bool canManageSpace(RoleType role, String spaceId, List<String> managedSpaceIds) =>
         role == RoleType.verifiedPlus && managedSpaceIds.contains(spaceId);
         
     static bool canCreateEvent(RoleType role, String spaceId, List<String> managedSpaceIds) =>
         canManageSpace(role, spaceId, managedSpaceIds);
         
     static bool canUseBoost(RoleType role, String spaceId, List<String> managedSpaceIds) =>
         canManageSpace(role, spaceId, managedSpaceIds);
         
     static bool canUseHoneyMode(RoleType role, String spaceId, List<String> managedSpaceIds) =>
         canManageSpace(role, spaceId, managedSpaceIds);
   }
   ```

3. **Create UI Permission Guard Widget**
   ```dart
   class PermissionGuard extends ConsumerWidget {
     final Widget child;
     final Widget? fallbackWidget;
     final bool Function(RoleType role, List<String> managedSpaceIds) permissionCheck;
     
     const PermissionGuard({
       required this.child,
       this.fallbackWidget,
       required this.permissionCheck,
       Key? key,
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       
       if (permissionCheck(roleState.roleType, roleState.managedSpaceIds)) {
         return child;
       }
       
       return fallbackWidget ?? const SizedBox.shrink();
     }
   }
   ```

### Phase 2: Role-Based UI Components

**Objective**: Implement role-specific UI elements and visualizations.

#### Steps:

1. **Create Role Indicator Badge**
   ```dart
   class RoleBadge extends StatelessWidget {
     final RoleType roleType;
     
     const RoleBadge({required this.roleType, Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       final color = _getRoleColor();
       final label = _getRoleLabel();
       
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
           color: color.withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: color.withOpacity(0.3), width: 0.5),
         ),
         child: Text(
           label,
           style: AppTextStyles.bodyMedium.copyWith(
             color: color,
             fontSize: 12,
           ),
         ),
       );
     }
     
     Color _getRoleColor() {
       switch (roleType) {
         case RoleType.public:
           return Colors.grey;
         case RoleType.verified:
           return Colors.white;
         case RoleType.verifiedPlus:
           return AppColors.gold;
       }
     }
     
     String _getRoleLabel() {
       switch (roleType) {
         case RoleType.public:
           return 'Public';
         case RoleType.verified:
           return 'Verified';
         case RoleType.verifiedPlus:
           return 'Verified+';
       }
     }
   }
   ```

2. **Create Verification Status Indicator**
   ```dart
   class VerificationStatusIndicator extends StatelessWidget {
     final VerificationStatus status;
     
     const VerificationStatusIndicator({required this.status, Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       // Different visual treatments based on status
       switch (status) {
         case VerificationStatus.none:
           return const SizedBox.shrink();
         case VerificationStatus.pending:
           return Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.orange.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.hourglass_top, size: 14, color: Colors.orange),
                 const SizedBox(width: 4),
                 Text(
                   'Verification Pending',
                   style: AppTextStyles.bodyMedium.copyWith(
                     color: Colors.orange,
                     fontSize: 12,
                   ),
                 ),
               ],
             ),
           );
         case VerificationStatus.approved:
           return Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.green.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.check_circle, size: 14, color: Colors.green),
                 const SizedBox(width: 4),
                 Text(
                   'Verified',
                   style: AppTextStyles.bodyMedium.copyWith(
                     color: Colors.green,
                     fontSize: 12,
                   ),
                 ),
               ],
             ),
           );
       }
     }
   }
   ```

3. **Create Role Upgrade Card**
   ```dart
   class RoleUpgradeCard extends ConsumerWidget {
     const RoleUpgradeCard({Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       
       // Different upgrade paths depending on current role
       switch (roleState.roleType) {
         case RoleType.public:
           return _buildPublicToVerifiedCard(context, ref);
         case RoleType.verified:
           return _buildVerifiedToVerifiedPlusCard(context, ref);
         case RoleType.verifiedPlus:
           return const SizedBox.shrink(); // No upgrade path
       }
     }
     
     Widget _buildPublicToVerifiedCard(BuildContext context, WidgetRef ref) {
       return GlassmorphicContainer(
         borderRadius: 16,
         blur: 5,
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Verify Your Account', style: AppTextStyles.titleLarge),
             const SizedBox(height: 8),
             Text(
               'Get full access to join spaces, RSVP to events, and more.',
               style: AppTextStyles.bodyMedium,
             ),
             const SizedBox(height: 16),
             OutlinedButton(
               onPressed: () {
                 // Launch verification flow
                 ref.read(userRoleProvider.notifier).initiateVerification();
               },
               child: Text('Verify with Email'),
             ),
           ],
         ),
       );
     }
     
     Widget _buildVerifiedToVerifiedPlusCard(BuildContext context, WidgetRef ref) {
       return GlassmorphicContainer(
         borderRadius: 16,
         blur: 5,
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Become a Space Leader', style: AppTextStyles.titleLarge),
             const SizedBox(height: 8),
             Text(
               'Lead your organization, create events, and more.',
               style: AppTextStyles.bodyMedium,
             ),
             const SizedBox(height: 16),
             OutlinedButton(
               onPressed: () {
                 // Launch leadership claim flow
                 ref.read(userRoleProvider.notifier).initiateLeadershipClaim();
               },
               child: Text('Claim Leadership'),
             ),
           ],
         ),
       );
     }
   }
   ```

### Phase 3: Feature Access Integration

**Objective**: Connect permission system to UI features.

#### Steps:

1. **Update Feed Screen**
   ```dart
   class FeedScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       
       return Scaffold(
         body: Column(
           children: [
             // Feed content visible to all roles
             Expanded(
               child: FeedContent(),
             ),
             
             // FAB for creating events - only for Verified+
             PermissionGuard(
               permissionCheck: (role, _) => role == RoleType.verifiedPlus,
               child: FloatingActionButton(
                 onPressed: () => navigateToCreateEvent(context),
                 backgroundColor: AppColors.yellow,
                 child: Icon(Icons.add, color: AppColors.black),
               ),
             ),
           ],
         ),
       );
     }
   }
   ```

2. **Update Space Details Screen**
   ```dart
   class SpaceDetailsScreen extends ConsumerWidget {
     final String spaceId;
     
     const SpaceDetailsScreen({required this.spaceId, Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       final isSpaceManager = roleState.managedSpaceIds.contains(spaceId);
       
       return Scaffold(
         appBar: AppBar(
           title: Text('Space Details'),
           actions: [
             // Edit button only for Verified+ who manage this space
             PermissionGuard(
               permissionCheck: (role, managedSpaceIds) => 
                   role == RoleType.verifiedPlus && managedSpaceIds.contains(spaceId),
               child: IconButton(
                 icon: Icon(Icons.edit),
                 onPressed: () => navigateToEditSpace(context, spaceId),
               ),
             ),
           ],
         ),
         body: Column(
           children: [
             // Space details visible to all
             SpaceHeader(spaceId: spaceId),
             
             // Join button only for Verified users who aren't members
             PermissionGuard(
               permissionCheck: (role, _) => role == RoleType.verified || role == RoleType.verifiedPlus,
               child: JoinSpaceButton(spaceId: spaceId),
             ),
             
             // Space management options only for Verified+ who manage this space
             PermissionGuard(
               permissionCheck: (role, managedSpaceIds) => 
                   role == RoleType.verifiedPlus && managedSpaceIds.contains(spaceId),
               child: SpaceManagementOptions(spaceId: spaceId),
             ),
             
             // Create event button only for Verified+ who manage this space  
             PermissionGuard(
               permissionCheck: (role, managedSpaceIds) => 
                   role == RoleType.verifiedPlus && managedSpaceIds.contains(spaceId),
               child: CreateEventButton(spaceId: spaceId),
             ),
           ],
         ),
       );
     }
   }
   ```

3. **Update Event Card**
   ```dart
   class EventCard extends ConsumerWidget {
     final EventEntity event;
     
     const EventCard({required this.event, Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       
       return Card(
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
         ),
         child: Column(
           children: [
             // Event details visible to all
             EventHeader(event: event),
             EventDetails(event: event),
             
             // RSVP button only for Verified users
             PermissionGuard(
               permissionCheck: (role, _) => role != RoleType.public,
               fallbackWidget: _buildNeedsVerificationButton(context),
               child: RSVPButton(eventId: event.id),
             ),
             
             // Edit/manage options only for Verified+ who manage the space
             PermissionGuard(
               permissionCheck: (role, managedSpaceIds) => 
                   role == RoleType.verifiedPlus && managedSpaceIds.contains(event.spaceId),
               child: EventManagementOptions(event: event),
             ),
           ],
         ),
       );
     }
     
     Widget _buildNeedsVerificationButton(BuildContext context) {
       return OutlinedButton(
         onPressed: () {
           // Show verification prompt dialog
           showDialog(
             context: context,
             builder: (context) => VerificationPromptDialog(),
           );
         },
         style: OutlinedButton.styleFrom(
           foregroundColor: AppColors.secondaryText,
         ),
         child: Text('Verify to RSVP'),
       );
     }
   }
   ```

### Phase 4: Role Upgrade Flows

**Objective**: Implement the UI flows for role upgrades.

#### Steps:

1. **Create Email Verification Flow**
   ```dart
   class EmailVerificationScreen extends ConsumerStatefulWidget {
     @override
     _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
   }
   
   class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
     final _formKey = GlobalKey<FormState>();
     final _emailController = TextEditingController();
     bool _isSubmitting = false;
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('Verify Your Account')),
         body: Padding(
           padding: const EdgeInsets.all(16),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Enter your university email',
                   style: AppTextStyles.titleLarge,
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'We\'ll send you a verification link to confirm your status.',
                   style: AppTextStyles.bodyMedium,
                 ),
                 const SizedBox(height: 24),
                 TextFormField(
                   controller: _emailController,
                   decoration: InputDecoration(
                     labelText: 'University Email',
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                   validator: (value) {
                     if (value == null || value.isEmpty) {
                       return 'Please enter your email';
                     }
                     if (!value.endsWith('.edu')) {
                       return 'Please use a valid .edu email';
                     }
                     return null;
                   },
                 ),
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _isSubmitting ? null : _submitVerification,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.white,
                       foregroundColor: AppColors.black,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: _isSubmitting
                         ? CircularProgressIndicator()
                         : Text('Send Verification Email'),
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
     }
     
     Future<void> _submitVerification() async {
       if (!_formKey.currentState!.validate()) return;
       
       setState(() {
         _isSubmitting = true;
       });
       
       try {
         await ref.read(userRoleProvider.notifier).sendVerificationEmail(_emailController.text);
         
         // Show success dialog
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Text('Verification Email Sent'),
             content: Text('Please check your email and click the verification link.'),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.of(context).pop();
                   Navigator.of(context).pop();
                 },
                 child: Text('OK'),
               ),
             ],
           ),
         );
       } catch (e) {
         // Show error dialog
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Text('Verification Failed'),
             content: Text('There was a problem sending the verification email. Please try again.'),
             actions: [
               TextButton(
                 onPressed: () => Navigator.of(context).pop(),
                 child: Text('OK'),
               ),
             ],
           ),
         );
       } finally {
         setState(() {
           _isSubmitting = false;
         });
       }
     }
   }
   ```

2. **Create Leadership Claim Flow**
   ```dart
   class LeadershipClaimScreen extends ConsumerStatefulWidget {
     @override
     _LeadershipClaimScreenState createState() => _LeadershipClaimScreenState();
   }
   
   class _LeadershipClaimScreenState extends ConsumerState<LeadershipClaimScreen> {
     final _formKey = GlobalKey<FormState>();
     String? _selectedSpaceId;
     final _positionController = TextEditingController();
     bool _isSubmitting = false;
     
     @override
     Widget build(BuildContext context) {
       final availableSpaces = ref.watch(availableSpacesProvider);
       
       return Scaffold(
         appBar: AppBar(title: Text('Claim Leadership')),
         body: Padding(
           padding: const EdgeInsets.all(16),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Claim Space Leadership',
                   style: AppTextStyles.titleLarge,
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'Select the space you lead and provide your leadership position.',
                   style: AppTextStyles.bodyMedium,
                 ),
                 const SizedBox(height: 24),
                 availableSpaces.when(
                   loading: () => Center(child: CircularProgressIndicator()),
                   error: (_, __) => Text('Failed to load spaces'),
                   data: (spaces) => DropdownButtonFormField<String>(
                     value: _selectedSpaceId,
                     decoration: InputDecoration(
                       labelText: 'Select Space',
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     items: spaces.map((space) {
                       return DropdownMenuItem(
                         value: space.id,
                         child: Text(space.name),
                       );
                     }).toList(),
                     onChanged: (value) {
                       setState(() {
                         _selectedSpaceId = value;
                       });
                     },
                     validator: (value) {
                       if (value == null) {
                         return 'Please select a space';
                       }
                       return null;
                     },
                   ),
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _positionController,
                   decoration: InputDecoration(
                     labelText: 'Your Position',
                     hintText: 'e.g., President, Treasurer, etc.',
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                   validator: (value) {
                     if (value == null || value.isEmpty) {
                       return 'Please enter your position';
                     }
                     return null;
                   },
                 ),
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _isSubmitting ? null : _submitClaim,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.white,
                       foregroundColor: AppColors.black,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: _isSubmitting
                         ? CircularProgressIndicator()
                         : Text('Submit Claim'),
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
     }
     
     Future<void> _submitClaim() async {
       if (!_formKey.currentState!.validate()) return;
       
       setState(() {
         _isSubmitting = true;
       });
       
       try {
         await ref.read(userRoleProvider.notifier).submitLeadershipClaim(
           spaceId: _selectedSpaceId!,
           position: _positionController.text,
         );
         
         // Show success dialog
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Text('Claim Submitted'),
             content: Text('Your leadership claim has been submitted and is pending review.'),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.of(context).pop();
                   Navigator.of(context).pop();
                 },
                 child: Text('OK'),
               ),
             ],
           ),
         );
       } catch (e) {
         // Show error dialog
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Text('Submission Failed'),
             content: Text('There was a problem submitting your claim. Please try again.'),
             actions: [
               TextButton(
                 onPressed: () => Navigator.of(context).pop(),
                 child: Text('OK'),
               ),
             ],
           ),
         );
       } finally {
         setState(() {
           _isSubmitting = false;
         });
       }
     }
   }
   ```

3. **Create Profile Role Section**
   ```dart
   class ProfileRoleSection extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final roleState = ref.watch(userRoleProvider);
       
       return Card(
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
         ),
         child: Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text('Account Status', style: AppTextStyles.titleLarge),
               const SizedBox(height: 8),
               Row(
                 children: [
                   RoleBadge(roleType: roleState.roleType),
                   const SizedBox(width: 8),
                   if (roleState.verificationStatus == VerificationStatus.pending)
                     VerificationStatusIndicator(status: roleState.verificationStatus),
                 ],
               ),
               const SizedBox(height: 16),
               
               // Different UI based on role
               if (roleState.roleType == RoleType.public)
                 _buildPublicStatusContent(context, ref)
               else if (roleState.roleType == RoleType.verified)
                 _buildVerifiedStatusContent(context, ref, roleState)
               else
                 _buildVerifiedPlusStatusContent(context, ref, roleState),
             ],
           ),
         ),
       );
     }
     
     Widget _buildPublicStatusContent(BuildContext context, WidgetRef ref) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Verify your account to unlock all features including joining spaces and RSVPing to events.',
             style: AppTextStyles.bodyMedium,
           ),
           const SizedBox(height: 12),
           OutlinedButton(
             onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
               );
             },
             style: OutlinedButton.styleFrom(
               foregroundColor: AppColors.yellow,
             ),
             child: Text('Verify Now'),
           ),
         ],
       );
     }
     
     Widget _buildVerifiedStatusContent(BuildContext context, WidgetRef ref, UserRoleState roleState) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Your account is verified! You can join spaces and RSVP to events.',
             style: AppTextStyles.bodyMedium,
           ),
           const SizedBox(height: 12),
           if (roleState.verificationStatus != VerificationStatus.pending)
             OutlinedButton(
               onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => LeadershipClaimScreen()),
                 );
               },
               style: OutlinedButton.styleFrom(
                 foregroundColor: AppColors.yellow,
               ),
               child: Text('Become a Space Leader'),
             ),
           if (roleState.verificationStatus == VerificationStatus.pending)
             Text(
               'Your leadership claim is being reviewed. We\'ll notify you when it\'s approved.',
               style: AppTextStyles.bodyMedium.copyWith(color: Colors.orange),
             ),
         ],
       );
     }
     
     Widget _buildVerifiedPlusStatusContent(BuildContext context, WidgetRef ref, UserRoleState roleState) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'You\'re a verified space leader! You can create events and manage your spaces.',
             style: AppTextStyles.bodyMedium,
           ),
           const SizedBox(height: 12),
           Text(
             'Spaces you manage:',
             style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
           ),
           const SizedBox(height: 8),
           ManagedSpacesList(spaceIds: roleState.managedSpaceIds),
         ],
       );
     }
   }
   ```

### Phase 5: Integration Testing

**Objective**: Verify the role-based UI integration works correctly.

#### Tests:

1. **Role State Changes Test**
   - Verify the UI updates correctly when role changes
   - Test that permission-restricted UI elements appear/disappear appropriately
   - Verify role indicators show the correct status

2. **Permission Checks Test**
   - Test that Public users can't access restricted features
   - Verify Verified users can join spaces and RSVP
   - Test that only Verified+ users can access management features

3. **Upgrade Flows Test**
   - Test the email verification flow
   - Test the leadership claim flow
   - Verify status indicators update correctly during the process

## Implementation Timeline

| Phase | Tasks | Duration | Dependencies |
|-------|-------|----------|--------------|
| 1. Role State Provider & Consumer | Create providers, permission utilities | 2 days | None |
| 2. Role-Based UI Components | Create role-specific UI elements | 3 days | Phase 1 |
| 3. Feature Access Integration | Connect permissions to UI features | 4 days | Phase 1, 2 |
| 4. Role Upgrade Flows | Implement upgrade UI flows | 4 days | Phase 1, 2 |
| 5. Integration Testing | Test and verify role integration | 2 days | Phase 1-4 |

## Success Criteria

- [ ] Role-specific UI elements are visible only to appropriate roles
- [ ] Role changes propagate immediately to UI updates
- [ ] Permission checks correctly restrict access to features
- [ ] Role upgrade flows are fully functional
- [ ] Visual indicators maintain brand aesthetic guidelines
- [ ] Interactive elements follow touch target guidelines (48dp minimum)
- [ ] Yellow accent used appropriately for interactive elements 