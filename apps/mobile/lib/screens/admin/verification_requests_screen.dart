import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/components/verification_request_card.dart';
import 'package:hive_ui/models/verification_request.dart';
import 'package:hive_ui/providers/verification_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Admin screen for managing verification requests
class VerificationRequestsScreen extends ConsumerStatefulWidget {
  const VerificationRequestsScreen({super.key});

  @override
  ConsumerState<VerificationRequestsScreen> createState() =>
      _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState
    extends ConsumerState<VerificationRequestsScreen> {
  // Filter options
  String _selectedStatusFilter = 'pending';
  String _selectedTypeFilter = 'all';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final verificationRequestsAsync =
        ref.watch(pendingVerificationRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Verification Requests',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshRequests,
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildContent(verificationRequestsAsync),
    );
  }

  /// Build the main content based on the async state
  Widget _buildContent(AsyncValue<List<VerificationRequest>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        // Apply filters
        final filteredRequests = _filterRequests(requests);

        if (filteredRequests.isEmpty) {
          return _buildEmptyState();
        }

        return _buildRequestsList(filteredRequests);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading verification requests',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the list of verification requests
  Widget _buildRequestsList(List<VerificationRequest> requests) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: Colors.black,
      onRefresh: () async {
        await _refreshRequests();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          // Header
          if (index == 0) {
            return _buildListHeader(requests.length);
          }

          // Actual request items (offset by 1 because of header)
          final request = requests[index - 1];
          return VerificationRequestCard(
            request: request,
            isAdminView: true,
            onStatusChanged: _refreshRequests,
          );
        },
      ),
    );
  }

  /// Build the header for the requests list
  Widget _buildListHeader(int count) {
    String statusText = 'all';
    switch (_selectedStatusFilter) {
      case 'pending':
        statusText = 'pending';
        break;
      case 'approved':
        statusText = 'approved';
        break;
      case 'rejected':
        statusText = 'rejected';
        break;
      case 'cancelled':
        statusText = 'cancelled';
        break;
    }

    String typeText =
        _selectedTypeFilter == 'all' ? 'all types' : '${_selectedTypeFilter}s';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count ${statusText.isNotEmpty ? '$statusText ' : ''}${count == 1 ? 'request' : 'requests'}',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_selectedStatusFilter != 'all' || _selectedTypeFilter != 'all')
            Row(
              children: [
                Text(
                  'Filtered by: ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                if (_selectedStatusFilter != 'all')
                  _buildFilterChip(_selectedStatusFilter, Colors.blue),
                if (_selectedStatusFilter != 'all' &&
                    _selectedTypeFilter != 'all')
                  const SizedBox(width: 8),
                if (_selectedTypeFilter != 'all')
                  _buildFilterChip(typeText, Colors.green),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear Filters',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build a chip for the active filter
  Widget _buildFilterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  /// Build empty state when no requests match the filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'No verification requests found',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _selectedStatusFilter != 'all' || _selectedTypeFilter != 'all'
                  ? 'Try changing your filters to see more requests'
                  : 'When spaces request verification, they will appear here',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedStatusFilter != 'all' || _selectedTypeFilter != 'all')
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  /// Show filter options dialog
  void _showFilterDialog() {
    // Local state for dialog
    String statusFilter = _selectedStatusFilter;
    String typeFilter = _selectedTypeFilter;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            'Filter Requests',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status filter section
              Text(
                'Status',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterOption(
                    label: 'All',
                    value: 'all',
                    groupValue: statusFilter,
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value!;
                      });
                    },
                  ),
                  _buildFilterOption(
                    label: 'Pending',
                    value: 'pending',
                    groupValue: statusFilter,
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value!;
                      });
                    },
                  ),
                  _buildFilterOption(
                    label: 'Approved',
                    value: 'approved',
                    groupValue: statusFilter,
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value!;
                      });
                    },
                  ),
                  _buildFilterOption(
                    label: 'Rejected',
                    value: 'rejected',
                    groupValue: statusFilter,
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value!;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Type filter section
              Text(
                'Type',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterOption(
                    label: 'All',
                    value: 'all',
                    groupValue: typeFilter,
                    onChanged: (value) {
                      setState(() {
                        typeFilter = value!;
                      });
                    },
                  ),
                  _buildFilterOption(
                    label: 'Space',
                    value: 'space',
                    groupValue: typeFilter,
                    onChanged: (value) {
                      setState(() {
                        typeFilter = value!;
                      });
                    },
                  ),
                  _buildFilterOption(
                    label: 'Organization',
                    value: 'organization',
                    groupValue: typeFilter,
                    onChanged: (value) {
                      setState(() {
                        typeFilter = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                // Apply the filters
                setState(() {
                  _selectedStatusFilter = statusFilter;
                  _selectedTypeFilter = typeFilter;
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Apply Filters',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a filter option for the dialog
  Widget _buildFilterOption({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? AppColors.gold : Colors.white,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Filter the requests based on the selected filters
  List<VerificationRequest> _filterRequests(
      List<VerificationRequest> requests) {
    return requests.where((request) {
      // Filter by status
      if (_selectedStatusFilter != 'all') {
        final requestStatus = request.status.name;
        if (requestStatus != _selectedStatusFilter) {
          return false;
        }
      }

      // Filter by type
      if (_selectedTypeFilter != 'all' &&
          request.objectType != _selectedTypeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Clear all active filters
  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = 'pending';
      _selectedTypeFilter = 'all';
    });
  }

  /// Refresh the list of verification requests
  Future<void> _refreshRequests() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref.refresh(pendingVerificationRequestsProvider.future);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}
