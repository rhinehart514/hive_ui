import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

/// AccountTierPage widget for selecting user account tier during onboarding
class AccountTierPage extends StatefulWidget {
  final AccountTier selectedTier;
  final List<AccountTier> availableTiers;
  final ValueChanged<AccountTier> onTierSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const AccountTierPage({
    super.key,
    required this.selectedTier,
    required this.availableTiers,
    required this.onTierSelected,
    required this.progressIndicator,
    this.onContinue,
  });

  @override
  State<AccountTierPage> createState() => _AccountTierPageState();
}

class _AccountTierPageState extends State<AccountTierPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: OnboardingLayout.standardDuration,
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: OnboardingLayout.entryCurve,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: OnboardingLayout.entryCurve,
      ),
    );
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OnboardingLayout.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Choose your account tier',
                style: OnboardingLayout.titleStyle,
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXS),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Select the tier that matches your status',
                style: OnboardingLayout.subtitleStyle,
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
          Expanded(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: _buildTierOptions(),
            ),
          ),
          widget.progressIndicator,
          SizedBox(height: OnboardingLayout.spacingMD),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SizedBox(
              width: double.infinity,
              height: OnboardingLayout.buttonHeight,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: OnboardingLayout.primaryButtonStyle(isEnabled: true),
                child: Text(
                  'Finish',
                  style: OnboardingLayout.buttonTextStyle,
                ),
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
        ],
      ),
    );
  }
  
  Widget _buildTierOptions() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.availableTiers.length,
      itemBuilder: (context, index) {
        final tier = widget.availableTiers[index];
        final isSelected = tier == widget.selectedTier;
        
        // Add staggered animation effect
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: OnboardingLayout.standardDuration,
          curve: Interval(
            0.1 * index,
            1.0,
            curve: OnboardingLayout.entryCurve,
          ),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _AccountTierOption(
            tier: tier,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTierSelected(tier);
            },
          ),
        );
      },
    );
  }
}

class _AccountTierOption extends StatelessWidget {
  final AccountTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTierOption({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: OnboardingLayout.spacingMD),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(OnboardingLayout.itemRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Add subtle haptic feedback
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: isSelected 
            ? Colors.black.withOpacity(0.1) 
            : Colors.white.withOpacity(0.1),
          highlightColor: isSelected 
            ? Colors.black.withOpacity(0.05) 
            : Colors.white.withOpacity(0.05),
          child: AnimatedContainer(
            duration: OnboardingLayout.standardDuration,
            curve: OnboardingLayout.standardCurve,
            padding: EdgeInsets.all(OnboardingLayout.spacingMD),
            decoration: isSelected 
              ? OnboardingLayout.selectedItemDecoration
              : OnboardingLayout.unselectedItemDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTierDisplayName(tier),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : OnboardingLayout.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: OnboardingLayout.spacingXS),
                Text(
                  _getTierDescription(tier),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isSelected 
                      ? Colors.black.withOpacity(0.7) 
                      : OnboardingLayout.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (!isSelected)
                  SizedBox(height: OnboardingLayout.spacingMD),
                if (!isSelected)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTierIcon(tier),
                      SizedBox(width: OnboardingLayout.spacingXS),
                      Text(
                        _getTierShortDescription(tier),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: OnboardingLayout.textTertiary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTierIcon(AccountTier tier) {
    IconData iconData;
    switch (tier) {
      case AccountTier.public:
        iconData = Icons.public;
        break;
      case AccountTier.verified:
        iconData = Icons.school;
        break;
      case AccountTier.verifiedPlus:
        iconData = Icons.workspace_premium;
        break;
      default:
        iconData = Icons.person;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: OnboardingLayout.textTertiary,
    );
  }
  
  String _getTierDisplayName(AccountTier tier) {
    switch (tier) {
      case AccountTier.public:
        return "Public";
      case AccountTier.verified:
        return "Verified Student";
      case AccountTier.verifiedPlus:
        return "Verified Plus";
      default:
        return tier.toString().split('.').last;
    }
  }
  
  String _getTierDescription(AccountTier tier) {
    switch (tier) {
      case AccountTier.public:
        return "Basic access with limited features";
      case AccountTier.verified:
        return "Verified student status with full access to campus features";
      case AccountTier.verifiedPlus:
        return "For student leaders and club officers with additional permissions";
      default:
        return "Standard account access";
    }
  }
  
  String _getTierShortDescription(AccountTier tier) {
    switch (tier) {
      case AccountTier.public:
        return "Basic access";
      case AccountTier.verified:
        return "Full access";
      case AccountTier.verifiedPlus:
        return "Extended privileges";
      default:
        return "Standard access";
    }
  }
} 