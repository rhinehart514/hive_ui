import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/widgets/gold_grain_overlay.dart';
import 'package:hive_ui/core/ui/dialog_utils.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/widgets/hive_loading_indicator.dart';

// Provider to hold the currently selected loading style
final selectedLoadingStyleProvider = StateProvider<HiveLoadingStyle>(
  (ref) => HiveLoadingStyle.goldSpinner
);

class ComponentTestPage extends ConsumerWidget {
  const ComponentTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Example list of options for the choice dialog
    final List<String> dialogOptions = List.generate(10, (index) => 'Option ${index + 1}');
    final selectedStyle = ref.watch(selectedLoadingStyleProvider);
    final styleNotifier = ref.read(selectedLoadingStyleProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('HIVE Component Test'),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: Stack(
        children: [
          const GoldGrainOverlay(
            opacity: 0.03,
            includeGlowStreak: true,
            child: SizedBox.expand(),
          ),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Choice Dialog Example ---
              const SectionTitle(title: 'HiveDialog (Choice Example)'),
              const SizedBox(height: 16),
              Center(
                child: HivePrimaryButton(
                  text: 'Show Choice Dialog',
                  onPressed: () {
                    showHiveDialog<String>(
                      context: context,
                      title: const Text('Select an Option'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: dialogOptions.length,
                          itemBuilder: (context, index) {
                            final option = dialogOptions[index];
                            return ListTile(
                              title: Text(
                                option,
                                style: const TextStyle(color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                Navigator.of(context).pop(option);
                              },
                              splashColor: AppColors.gold.withOpacity(0.1),
                              hoverColor: AppColors.surfaceCard.withOpacity(0.5),
                            );
                          },
                        ),
                      ),
                      actions: [],
                    ).then((selectedValue) {
                      if (selectedValue != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: $selectedValue'),
                            backgroundColor: AppColors.surfaceCard,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              // --- Loading Indicator Example ---
              const SectionTitle(title: 'HiveLoadingIndicator'),
              const SizedBox(height: 16),
              ComponentCard(
                title: 'Select Style:',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<HiveLoadingStyle>(
                    value: selectedStyle,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceCard,
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: Container(
                      height: 1,
                      color: AppColors.gold.withOpacity(0.5),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
                    onChanged: (HiveLoadingStyle? newValue) {
                      if (newValue != null) {
                        styleNotifier.state = newValue;
                      }
                    },
                    items: HiveLoadingStyle.values
                        .map<DropdownMenuItem<HiveLoadingStyle>>((HiveLoadingStyle value) {
                      return DropdownMenuItem<HiveLoadingStyle>(
                        value: value,
                        child: Text(value.name), // Display enum name
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: HiveLoadingIndicator(
                  style: selectedStyle,
                  size: 60.0, // Adjust size as needed
                  loadingText: selectedStyle == HiveLoadingStyle.subtleGrainShift
                      ? 'Processing...' // Example text
                      : null,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ComponentCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ComponentCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textTertiary.withOpacity(0.2))
          ),
          child: child,
        )
      ],
    );
  }
} 