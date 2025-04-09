import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/glassmorphism.dart';
import 'package:hive_ui/tools/messaging_test_data.dart';

/// Advanced screen for generating and managing test messaging data
class GenerateTestMessagingDataScreen extends ConsumerStatefulWidget {
  const GenerateTestMessagingDataScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GenerateTestMessagingDataScreen> createState() => 
      _GenerateTestMessagingDataScreenState();
}

class _GenerateTestMessagingDataScreenState 
    extends ConsumerState<GenerateTestMessagingDataScreen> {
  bool _isLoading = false;
  int _userCount = 5;
  int _messagesPerConversation = 20;
  bool _includeMedia = false;
  bool _includeGroupChats = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Test Data'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildConfigurationSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.settings,
              color: AppColors.gold,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Advanced Messaging Test Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure and generate different types of test data for messaging features',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return GlassmorphicContainer(
      blur: 20,
      opacity: 0.1,
      borderRadius: 12,
      border: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Number of users slider
            Text(
              'Number of Users: $_userCount',
              style: const TextStyle(color: Colors.white),
            ),
            Slider(
              value: _userCount.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              activeColor: AppColors.gold,
              inactiveColor: Colors.grey[800],
              onChanged: (value) {
                setState(() {
                  _userCount = value.round();
                });
              },
            ),
            
            // Messages per conversation slider
            Text(
              'Messages per Conversation: $_messagesPerConversation',
              style: const TextStyle(color: Colors.white),
            ),
            Slider(
              value: _messagesPerConversation.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              activeColor: AppColors.gold,
              inactiveColor: Colors.grey[800],
              onChanged: (value) {
                setState(() {
                  _messagesPerConversation = value.round();
                });
              },
            ),
            
            // Include media toggle
            SwitchListTile(
              title: const Text(
                'Include Media Messages',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Add images and other media types',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              value: _includeMedia,
              activeColor: AppColors.gold,
              onChanged: (value) {
                setState(() {
                  _includeMedia = value;
                });
              },
            ),
            
            // Include group chats toggle
            SwitchListTile(
              title: const Text(
                'Include Group Chats',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Generate group conversations',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              value: _includeGroupChats,
              activeColor: AppColors.gold,
              onChanged: (value) {
                setState(() {
                  _includeGroupChats = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _generateAdvancedTestData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'Generate Advanced Test Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _clearAllTestData,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Clear All Test Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAdvancedTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await MessagingTestData.generateAdvancedSampleData(
        userCount: _userCount,
        messagesPerConversation: _messagesPerConversation,
        includeMedia: _includeMedia,
        includeGroupChats: _includeGroupChats,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced test data has been generated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await MessagingTestData.clearAllTestData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All test data has been cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 