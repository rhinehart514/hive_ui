# HIVE Platform Verification System

## Overview

The verification system in the HIVE platform provides three levels of user verification, each with its own set of permissions and access levels:

1. **Public** - Basic accounts with limited access
2. **Verified** - Standard accounts with full access (email verified)
3. **Verified+** - Enhanced verification for student leaders

## Features

### Verification Levels

- **Public Users**:
  - Can view content but cannot create content, spaces, or add friends
  - Limited platform access
  - No verification badge

- **Verified Users**:
  - Can create content, join communities, and participate in all activities
  - Requires email verification
  - Displayed with a standard verification badge

- **Verified+ Users (Student Leaders)**:
  - Enhanced status for student leaders connected to spaces
  - Gold verification badge with student leader indicator
  - Connected to a specific space they lead

### Verification Workflows

The system includes complete workflows for:

1. **Email Verification**:
   - Generate and send a verification code
   - Verify email addresses using the code
   - Upgrade status from Public to Verified

2. **Student Leader Verification**:
   - Request enhanced verification status
   - Connect student leaders to their spaces
   - Admin review and approval process

### User Interface Components

- **Verification Badge**: Displays the user's verification level with appropriate icons
- **Verification Status Badge**: Shows the current status of verification requests
- **Verification Button**: Smart button for initiating or checking verification
- **Verification Request Page**: Complete UI for submitting and tracking verification requests

## Implementation Details

### Core Entities

1. **VerificationLevel Enum**:
   - `public`: Basic unverified account
   - `verified`: Standard verified account
   - `verifiedPlus`: Enhanced student leader verification

2. **VerificationStatus Enum**:
   - `notVerified`: No verification submitted
   - `pending`: Verification in progress
   - `rejected`: Verification was rejected
   - `verified`: Successfully verified

3. **UserVerification Class**:
   - Tracks verification level and status
   - Stores verification metadata (submission dates, approvers, etc.)
   - Includes connected space ID for student leaders

### Providers

1. **userVerificationProvider**:
   - Streams the current user's verification status
   - Connects to Firestore for real-time updates

2. **emailVerificationProvider**:
   - Handles email verification code generation
   - Processes verification submissions
   - Manages verification state

3. **verifiedPlusRequestProvider**:
   - Handles enhanced verification requests
   - Connects student leaders to spaces
   - Manages the upgrade request workflow

4. **Permission Check Providers**:
   - `canCreateContentProvider`: Checks if users can create content
   - `canCreateSpacesProvider`: Checks if users can create spaces
   - `canApplyForVerificationProvider`: Determines verification eligibility

### User Interface

1. **VerificationBadge Widget**:
   - Visual indicator of verification level
   - Customizable size and appearance
   - Level-specific icons and colors

2. **VerificationStatusBadge Widget**:
   - Shows status of verification requests
   - Status-specific styling and icons

3. **VerificationButton Widget**:
   - Smart button with context-aware text and icons
   - Adapts based on current verification status

4. **VerificationRequestPage**:
   - Complete UI for verification workflows
   - Email verification code entry
   - Student leader status requests
   - Current status display

## Database Structure

- `user_verifications` collection: Stores verification status for each user
- `verification_codes` collection: Manages email verification codes
- `verification_requests` collection: Tracks enhanced verification requests

## Security Considerations

- Access control based on verification level
- Secure verification code generation and validation
- Admin approval workflow for enhanced verification

## Future Enhancements

Potential improvements for the verification system include:

1. Automated ID verification for higher security
2. Integration with university email systems for automatic verification
3. Tiered verification levels for different community roles
4. Enhanced analytics on verification status and conversion rates 