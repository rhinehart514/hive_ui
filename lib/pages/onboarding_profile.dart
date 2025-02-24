import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/models/user_profile.dart';

class OnboardingProfilePage extends ConsumerStatefulWidget {
  const OnboardingProfilePage({super.key});

  @override
  ConsumerState<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends ConsumerState<OnboardingProfilePage> {
  final _pageController = PageController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedYear;
  String? _selectedField;
  String? _selectedResidence;

  final List<String> years = [
    'Freshman',
    'Sophomore',
    'Junior',
    'Senior',
    'Masters',
    'PhD',
    'Non-Degree Seeking',
  ];

  final List<String> residences = [
    'Ellicott',
    'Governors',
    'Greiner',
    'On Campus Apartments',
    'Commuter',
  ];

  final List<String> fields = [
    'Computer Science',
    'Engineering',
    'Business',
    'Arts & Sciences',
    'Health Sciences',
    'Education',
    'Architecture',
    'Law',
    'Other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() {
    final profile = UserProfile(
      id: DateTime.now().toString(), // This should come from auth
      username: '${_firstNameController.text} ${_lastNameController.text}',
      year: _selectedYear ?? '',
      major: _selectedField ?? '',
      residence: _selectedResidence ?? '',
      eventCount: 0,
      clubCount: 0,
      friendCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(profileProvider.notifier).updateProfile(profile);
    // TODO: Navigate to home page once implemented
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile setup complete!'),
        backgroundColor: AppColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNamePage(),
                _buildYearPage(),
                _buildFieldPage(),
                _buildResidencePage(),
              ],
            ),
            Positioned(
              top: 24,
              left: 24,
              child: _buildProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentPage = _pageController.hasClients 
      ? (_pageController.page ?? 0).round() 
      : 0;
    
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= currentPage;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
              ? const Color(0xFFFFD700)
              : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your name?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s get to know you',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            onSubmitted: (_) {
              if (_firstNameController.text.isNotEmpty && 
                  _lastNameController.text.isNotEmpty) {
                _nextPage();
              }
            },
          ),
          const Spacer(),
          _buildContinueButton(
            onPressed: () {
              if (_firstNameController.text.isNotEmpty && 
                  _lastNameController.text.isNotEmpty) {
                _nextPage();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What year are you in?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your current academic level',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                return _buildSelectionTile(
                  text: year,
                  isSelected: year == _selectedYear,
                  onTap: () {
                    setState(() => _selectedYear = year);
                    _nextPage();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your field?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your field of study',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.builder(
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return _buildSelectionTile(
                  text: field,
                  isSelected: field == _selectedField,
                  onTap: () {
                    setState(() => _selectedField = field);
                    _nextPage();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidencePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where do you live?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your residential area',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.builder(
              itemCount: residences.length,
              itemBuilder: (context, index) {
                final residence = residences[index];
                return _buildSelectionTile(
                  text: residence,
                  isSelected: residence == _selectedResidence,
                  onTap: () {
                    setState(() => _selectedResidence = residence);
                    _completeOnboarding();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        floatingLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.next,
      cursorColor: Colors.white,
    );
  }

  Widget _buildSelectionTile({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton({required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 1,
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 