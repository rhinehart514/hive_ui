import 'package:flutter/foundation.dart';
import '../../../models/repost.dart';

enum RepostStatus {
  initial,
  loading,
  success,
  error,
}

@immutable
class RepostState {
  final RepostStatus status;
  final List<Repost> userReposts;
  final List<Repost> eventReposts;
  final List<Repost> feedReposts;
  final String? errorMessage;
  final bool isSubmitting;

  const RepostState({
    this.status = RepostStatus.initial,
    this.userReposts = const [],
    this.eventReposts = const [],
    this.feedReposts = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  RepostState copyWith({
    RepostStatus? status,
    List<Repost>? userReposts,
    List<Repost>? eventReposts,
    List<Repost>? feedReposts,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return RepostState(
      status: status ?? this.status,
      userReposts: userReposts ?? this.userReposts,
      eventReposts: eventReposts ?? this.eventReposts,
      feedReposts: feedReposts ?? this.feedReposts,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  RepostState clearError() {
    return copyWith(errorMessage: null);
  }

  RepostState setLoading() {
    return copyWith(status: RepostStatus.loading);
  }

  RepostState setSubmitting(bool isSubmitting) {
    return copyWith(isSubmitting: isSubmitting);
  }

  RepostState setError(String message) {
    return copyWith(
      status: RepostStatus.error,
      errorMessage: message,
      isSubmitting: false,
    );
  }

  RepostState setSuccess() {
    return copyWith(
      status: RepostStatus.success,
      errorMessage: null,
      isSubmitting: false,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isLoading => status == RepostStatus.loading;
  bool get isSuccess => status == RepostStatus.success;
} 