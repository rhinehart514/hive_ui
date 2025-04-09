import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/features/profile/presentation/providers/verification_provider.dart';
import 'package:hive_ui/features/profile/presentation/widgets/verification_badge.dart';
import 'package:hive_ui/features/spaces/domain/entities/space.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

class VerificationRequestPage extends ConsumerStatefulWidget {
  const VerificationRequestPage({super.key});

  @override
  ConsumerState<VerificationRequestPage> createState() => _VerificationRequestPageState();
}

class _VerificationRequestPageState extends ConsumerState<VerificationRequestPage> {
  final _emailCodeController = TextEditingController();
  final _leaderRoleController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  Space? _selectedSpace;
  
  @override
  void dispose() {
    _emailCodeController.dispose();
    _leaderRoleController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final verificationAsyncValue = ref.watch(userVerificationProvider);
    final emailVerificationState = ref.watch(emailVerificationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: verificationAsyncValue.when(
        data: (verification) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStatusCard(verification),
                const SizedBox(height: 24),
                // Show either email verification or verified+ request based on user's status
                if (verification.level == VerificationLevel.public)
                  _buildEmailVerificationSection(emailVerificationState)
                else if (verification.level == VerificationLevel.verified && 
                        verification.status == VerificationStatus.verified)
                  _buildVerifiedPlusRequestSection(verification)
                else if (verification.status == VerificationStatus.pending)
                  _buildPendingRequestCard(verification)
                else
                  _buildNoActionsAvailableCard(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(UserVerification verification) {
    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Verification Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            VerificationDetailBadge(verification: verification),
            const SizedBox(height: 16),
            _buildVerificationExplanation(verification),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationExplanation(UserVerification verification) {
    String explainText;
    
    if (verification.level == VerificationLevel.public) {
      explainText = 'Public accounts have limited access. Verify your email to unlock full features including creating content and joining communities.';
    } else if (verification.level == VerificationLevel.verified) {
      explainText = 'Verified users can create content, join communities, and participate in all platform activities.';
    } else {
      explainText = 'Verified+ accounts are student leaders with enhanced verification status, connected to an official space.';
    }
    
    return Text(
      explainText,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white70,
      ),
    );
  }
  
  Widget _buildEmailVerificationSection(EmailVerificationState state) {
    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Verification',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your email address to gain full access to the platform.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            if (state.codeSentAt != null) ...[
              // Show verification code box
              TextField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter the code sent to your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              if (state.verificationCode != null)
                Text(
                  'DEBUG - Code: ${state.verificationCode}', // In production, this would be removed
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(emailVerificationProvider.notifier).sendVerificationEmail(),
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                            .read(emailVerificationProvider.notifier)
                            .verifyEmail(_emailCodeController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Verify',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ] else ...[
              // Show send code button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => ref.read(emailVerificationProvider.notifier).sendVerificationEmail(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Send Verification Code',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
            if (state.isSuccess && !state.isLoading && state.codeSentAt == null) ...[
              const SizedBox(height: 16),
              Text(
                'Your email has been verified successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerifiedPlusRequestSection(UserVerification verification) {
    final userSpacesAsync = ref.watch(userSpacesProvider);
    final verifiedPlusRequest = ref.watch(verifiedPlusRequestProvider);
    
    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Student Leader Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apply for Verified+ status as a student leader connected to a space.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            userSpacesAsync.when(
              data: (spaces) {
                if (spaces.isEmpty) {
                  return Text(
                    'You need to be a member of at least one space to request Student Leader status.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Space',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Space>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      dropdownColor: Colors.grey.shade900,
                      value: _selectedSpace,
                      items: spaces.map((space) {
                        return DropdownMenuItem<Space>(
                          value: space,
                          child: Text(
                            space.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpace = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Role',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leaderRoleController,
                      decoration: InputDecoration(
                        labelText: 'Role in Organization',
                        hintText: 'e.g. President, Secretary, Founder',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Additional Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _additionalInfoController,
                      decoration: InputDecoration(
                        labelText: 'Additional Information',
                        hintText: 'Any other information to support your request',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (verifiedPlusRequest.isLoading || _selectedSpace == null || _leaderRoleController.text.trim().isEmpty)
                            ? null
                            : () {
                                ref.read(verifiedPlusRequestProvider.notifier).requestVerifiedPlusStatus(
                                      spaceId: _selectedSpace!.id,
                                      role: _leaderRoleController.text.trim(),
                                      additionalInfo: _additionalInfoController.text.trim(),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: verifiedPlusRequest.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Submit Request',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    verifiedPlusRequest.when(
                      loading: () => const SizedBox.shrink(),
                      data: (_) => const SizedBox.shrink(),
                      error: (error, stackTrace) => Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Error: $error',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                'Error: $error',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingRequestCard(UserVerification verification) {
    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Request Pending',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your verification request is currently being reviewed by our team. This process typically takes 1-3 business days.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            if (verification.submittedAt != null)
              Text(
                'Submitted on: ${_formatDate(verification.submittedAt!)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.orange.shade300,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoActionsAvailableCard() {
    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'No Actions Required',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your account is currently at the highest possible verification level. No further verification actions are available.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 