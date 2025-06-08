import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/error_handling_service.dart';
import '../../services/analytics_service.dart';

/// A widget that catches errors in its child widget tree
class ErrorBoundary extends ConsumerStatefulWidget {
  /// The child widget that might throw errors
  final Widget child;

  /// Optional fallback widget to show when an error occurs
  final Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder;

  /// Whether to rethrow the error after handling it
  final bool shouldRethrow;

  /// Constructor
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.shouldRethrow = false,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  void Function(FlutterErrorDetails)? _originalOnError;

  @override
  void initState() {
    super.initState();
    // Store the original error handler
    _originalOnError = FlutterError.onError;

    // Set custom error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Report to error handling service
      ref.read(errorHandlingServiceProvider).handleError(
            details.exception,
            stackTrace: details.stack,
          );

      // Track in analytics
      try {
        AnalyticsService().trackError(
          details.exception,
          details.stack,
          method: 'ui_error',
        );
      } catch (analyticsError) {
        // Don't let analytics errors cause more problems
        debugPrint('Error tracking analytics: $analyticsError');
      }

      // Update state to show error UI safely outside of build
      if (mounted) {
        // Use a post-frame callback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _error = details.exception;
              _stackTrace = details.stack;
            });
          }
        });
      }

      // Optionally rethrow
      if (widget.shouldRethrow) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _stackTrace != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(context, _error!, _stackTrace!);
      } else {
        return _DefaultErrorWidget(
          error: _error!,
          stackTrace: _stackTrace!,
          onRetry: () => setState(() {
            _error = null;
            _stackTrace = null;
          }),
        );
      }
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No longer setting FlutterError.onError here
  }

  @override
  void dispose() {
    // Reset to original error handler
    FlutterError.onError = _originalOnError;
    super.dispose();
  }
}

/// Default widget to show when an error occurs
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to add error boundary to any widget
extension ErrorBoundaryExtension on Widget {
  /// Wrap this widget with an error boundary
  Widget withErrorBoundary({
    Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder,
    bool shouldRethrow = false,
  }) {
    return ErrorBoundary(
      fallbackBuilder: fallbackBuilder,
      shouldRethrow: shouldRethrow,
      child: this,
    );
  }
}
