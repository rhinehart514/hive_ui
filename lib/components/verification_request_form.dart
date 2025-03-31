import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/verification_request.dart';
import 'package:hive_ui/providers/verification_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A form for requesting verification for a space or organization
class VerificationRequestForm extends ConsumerStatefulWidget {
  /// ID of the object to verify
  final String objectId;

  /// Type of object to verify (space or organization)
  final String objectType;

  /// Name of the object to verify
  final String objectName;

  /// Callback when the form is submitted or canceled
  final Function()? onComplete;

  const VerificationRequestForm({
    super.key,
    required this.objectId,
    required this.objectType,
    required this.objectName,
    this.onComplete,
  });

  @override
  ConsumerState<VerificationRequestForm> createState() =>
      _VerificationRequestFormState();
}

class _VerificationRequestFormState
    extends ConsumerState<VerificationRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Standard verification by default, not Verified+
  VerificationType _verificationType = VerificationType.standard;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the request state
    final requestState = ref.watch(verificationRequestNotifierProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Verification Request',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Request verification for "${widget.objectName}"',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message input
                  Text(
                    'Message (Optional)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Enter any additional information that might help with verification...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gold.withOpacity(0.5),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),

                  // Request type
                  Text(
                    'Verification Type',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Verification type selection
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Standard verification option
                        RadioListTile<VerificationType>(
                          title: Text(
                            'Standard Verification',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Verify this space as legitimate',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          value: VerificationType.standard,
                          groupValue: _verificationType,
                          onChanged: (value) {
                            setState(() {
                              _verificationType = value!;
                            });
                          },
                          activeColor: AppColors.gold,
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                                ? AppColors.gold
                                : Colors.white,
                          ),
                        ),

                        // Info text explaining manual verification
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Verification requests are reviewed manually by our team. '
                            'You will be notified when your request is processed.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.red[300],
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (widget.onComplete != null) {
                                  widget.onComplete!();
                                }
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              AppColors.gold.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Submit Request',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    // Clear previous error message
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Submit the request using the provider
      final success = await ref
          .read(verificationRequestNotifierProvider.notifier)
          .submitRequest(
            objectId: widget.objectId,
            objectType: widget.objectType,
            name: widget.objectName,
            message: _messageController.text.trim(),
            verificationType: _verificationType,
          );

      if (success) {
        // Success, close the dialog
        if (mounted) {
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Verification request submitted successfully',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green[700],
            ),
          );

          // Close the dialog and call onComplete if provided
          if (widget.onComplete != null) {
            widget.onComplete!();
          }
          Navigator.of(context).pop();
        }
      } else {
        // Handle unsuccessful submission
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'Failed to submit verification request. Please try again.';
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
}

/// Show a verification request form dialog
Future<void> showVerificationRequestForm(
  BuildContext context, {
  required String objectId,
  required String objectType,
  required String objectName,
  Function()? onComplete,
}) async {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: VerificationRequestForm(
        objectId: objectId,
        objectType: objectType,
        objectName: objectName,
        onComplete: onComplete,
      ),
    ),
  );
}
