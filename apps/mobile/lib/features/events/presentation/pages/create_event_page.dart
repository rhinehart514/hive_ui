import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/event_creation_request.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/features/events/presentation/controllers/recurring_event_controller.dart';
import 'package:hive_ui/features/events/presentation/widgets/recurring_event_options.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  final Space selectedSpace;

  const CreateEventPage({
    super.key,
    required this.selectedSpace,
  });

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Submission state
  bool _isSubmitting = false;
  
  // Text editing controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  late DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  late DateTime _endDate = DateTime.now().add(const Duration(hours: 3));
  String _category = 'Social';
  String _visibility = 'public';
  final List<String> _selectedTags = [];
  
  // Recurring event fields
  bool _isRecurring = false;
  String _recurrenceFrequency = 'weekly';
  int _recurrenceInterval = 1;
  List<String> _daysOfWeek = [];
  DateTime? _recurrenceEndDate;
  int? _maxOccurrences;
  int _dayOfMonth = 1;
  int _weekOfMonth = 1;
  int _monthOfYear = 1;
  bool _byDayOfWeek = false;
  
  // Pre-defined event categories
  final List<String> _categories = [
    'Academic',
    'Arts',
    'Career',
    'Club',
    'Community Service',
    'Cultural',
    'Entertainment',
    'Fitness',
    'Greek Life',
    'Health',
    'Religious',
    'Social',
    'Sports',
    'Tech',
    'Workshop',
    'Other'
  ];
  
  // Pre-defined tags to select from
  final List<String> _tagOptions = [
    'Free Food',
    'Guest Speaker',
    'Workshop',
    'Social',
    'Sports',
    'Performance',
    'Competition',
    'Educational',
    'Fundraiser',
    'Party',
    'Networking',
    'Community Service',
    'Cultural',
    'Study Group',
    'Virtual',
    'Job Fair',
    'Meeting',
    'Outdoor',
    'Weekend',
    'Evening',
  ];
  
  // Visibility options
  final Map<String, String> _visibilityOptions = {
    'public': 'Public - Anyone can see this event',
    'space-only': 'Space Only - Only space members can see this event',
    'private': 'Private - Only invited members can see this event',
  };

  @override
  void initState() {
    super.initState();
    // Track screen view
    AnalyticsService.logScreenView('create_event_page');
    
    // Initialize days of week if using weekly recurrence
    // Default to the day of week of the start date
    _daysOfWeek = [_getDayOfWeekString(_startDate.weekday % 7)]; // Convert from 1-7 (Mon-Sun) to 0-6 (Sun-Sat)
    
    // Initialize day of month for monthly recurrence
    _dayOfMonth = _startDate.day;
    
    // Initialize week of month for monthly recurrence
    _weekOfMonth = ((_startDate.day - 1) ~/ 7) + 1;
    
    // Initialize month of year for yearly recurrence
    _monthOfYear = _startDate.month;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Select start date
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.grey.shade900,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: Colors.black,
                surface: Colors.grey.shade900,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.grey.shade900,
            ),
            child: child!,
          );
        },
      );
      
      if (!mounted) return;

      if (pickedTime != null) {
        setState(() {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
          }
        });
      }
    }
  }

  /// Select end date
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.grey.shade900,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: Colors.black,
                surface: Colors.grey.shade900,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.grey.shade900,
            ),
            child: child!,
          );
        },
      );
      
      if (!mounted) return;

      if (pickedTime != null) {
        setState(() {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Helper method to convert day of week index to string representation
  String _getDayOfWeekString(int dayIndex) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayIndex];
  }

  // Helper method to convert day of week strings to indices
  List<int> _getDaysOfWeekIndices(List<String> days) {
    final Map<String, int> dayMap = {
      'Sun': 0, 'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6
    };
    return days.map((day) => dayMap[day] ?? 0).toList();
  }

  // Helper method to validate space type
  bool _isValidSpaceType(String spaceType) {
    final validTypes = [
      'studentorg',
      'universityorg',
      'campusliving',
      'fraternityandsority',
      'other',
      // Include common variations and aliases
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'student',
      'university',
      'campus',
      'greek',
    ];
    return validTypes.contains(spaceType);
  }

  /// Create the event
  Future<void> _createEvent() async {
    try {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        return;
      }
      
      if (_titleController.text.isEmpty) {
        return;
      }
      
      // Set loading
      setState(() {
        _isSubmitting = true;
      });
      
      // Create a Firebase reference for the new event
      final CollectionReference eventsCollection = FirebaseFirestore.instance.collection('events');
      final DocumentReference newEventRef = eventsCollection.doc();
      
      // First check if the user is an admin of the space if it's a club/space event
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to create an event')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      
      // Verify admin status using the repository for accurate role check
      final isSpaceEvent = widget.selectedSpace.id.isNotEmpty;
      bool isSpaceAdmin = false; // Default to false
      if (isSpaceEvent) {
        final repository = ref.read(spaceRepositoryProvider);
        final spaceId = widget.selectedSpace.id;
        final userId = currentUser.uid;
        
        try {
            final member = await repository.getSpaceMember(spaceId, userId);
            isSpaceAdmin = member?.role == 'admin';
        } catch (e) {
            debugPrint('Error checking space admin status during event creation: $e');
            // Handle error case - prevent event creation if status check fails
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not verify space permissions. Please try again.')),
            );
            setState(() { _isSubmitting = false; });
            return;
        }

        if (!isSpaceAdmin) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be an admin of this space to create an event'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isSubmitting = false; });
          return;
        }
      }
      
      // Create event request
      final request = EventCreationRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        visibility: _visibility,
        tags: _selectedTags,
        organizerName: widget.selectedSpace.name,
        organizerEmail: currentUser.email ?? '',
        clubId: isSpaceEvent ? widget.selectedSpace.id : null,
        isClubEvent: isSpaceEvent,
        // Add recurring event parameters
        isRecurring: _isRecurring,
        recurrenceFrequency: _isRecurring ? _recurrenceFrequency : null,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        maxOccurrences: _isRecurring ? _maxOccurrences : null,
        daysOfWeek: _isRecurring && _recurrenceFrequency == 'weekly' ? _getDaysOfWeekIndices(_daysOfWeek) : null,
        dayOfMonth: _isRecurring && (_recurrenceFrequency == 'monthly' || _recurrenceFrequency == 'yearly') ? _dayOfMonth : null,
        weekOfMonth: _isRecurring && _recurrenceFrequency == 'monthly' && _byDayOfWeek ? _weekOfMonth : null,
        monthOfYear: _isRecurring && _recurrenceFrequency == 'yearly' ? _monthOfYear : null,
        byDayOfWeek: _isRecurring && _recurrenceFrequency == 'monthly' ? _byDayOfWeek : null,
      );

      // Validate request
      final validationError = request.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      if (_isRecurring) {
        // Use the RecurringEventController to create a recurring event
        final controller = ref.read(recurringEventControllerProvider.notifier);
        final recurringEvent = await controller.createRecurringEvent(request, currentUser.uid);
        
        if (recurringEvent == null) {
          throw Exception('Failed to create recurring event');
        }
      } else {
        // Create regular (non-recurring) event
        final event = Event.createClubEvent(
          title: request.title,
          description: request.description,
          location: request.location,
          startDate: request.startDate,
          endDate: request.endDate,
          clubId: widget.selectedSpace.id,
          clubName: widget.selectedSpace.name,
          creatorId: currentUser.uid,
          category: request.category,
          organizerEmail: currentUser.email ?? '',
          visibility: request.visibility,
          tags: request.tags,
          imageUrl: widget.selectedSpace.imageUrl ?? '',
        );

        // Get the space type for Firestore path
        final spaceType = widget.selectedSpace.spaceType.toString().split('.').last.toLowerCase();
        debugPrint('Using space type for Firestore path: $spaceType');
        
        // Validate space type - fallback to a default if there's an issue
        final validSpaceType = _isValidSpaceType(spaceType) ? spaceType : 'student_organizations';
        
        // Reference to the space
        final spaceRef = FirebaseFirestore.instance
            .collection('spaces')
            .doc(validSpaceType)
            .collection('spaces')
            .doc(widget.selectedSpace.id);
            
        // Reference to the event in the space's events subcollection
        final spaceEventRef = spaceRef.collection('events').doc(event.id);
        
        // Create a batch to update multiple locations atomically
        final batch = FirebaseFirestore.instance.batch();
        
        // Add event data to batch
        final eventData = event.toMap();
        
        // Add to global events collection
        batch.set(newEventRef, eventData);
        
        // Also add to space's events subcollection
        batch.set(spaceEventRef, eventData);
        
        // Update space document to include this event
        batch.update(spaceRef, {
          'eventIds': FieldValue.arrayUnion([event.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Commit all the writes
        await batch.commit();
        
        debugPrint('Event created successfully with ID: ${event.id}');
      }

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event created successfully!'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to space page
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error creating event: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Event',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createEvent,
            child: Text(
              'Create',
              style: GoogleFonts.outfit(
                color: _isSubmitting ? Colors.grey : AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                              image: widget.selectedSpace.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(widget.selectedSpace.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.selectedSpace.imageUrl == null
                                ? const Icon(Icons.group, color: Colors.white54)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Creating event for:',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.selectedSpace.name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).addGlassmorphism(
                      borderRadius: 12,
                      blur: GlassmorphismGuide.kCardBlur,
                      opacity: GlassmorphismGuide.kCardGlassOpacity,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Event title
                    Text(
                      'Event Title',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter event title',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Event description
                    Text(
                      'Description',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe your event',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Location
                    Text(
                      'Location',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter event location',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event location';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Date and time
                    Text(
                      'Date & Time',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectStartDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Starts',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy • h:mm a').format(_startDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectEndDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ends',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy • h:mm a').format(_endDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Recurring event options
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RecurringEventOptions(
                        isRecurring: _isRecurring,
                        frequency: _recurrenceFrequency,
                        interval: _recurrenceInterval,
                        daysOfWeek: _daysOfWeek,
                        endDate: _recurrenceEndDate,
                        maxOccurrences: _maxOccurrences,
                        dayOfMonth: _dayOfMonth,
                        weekOfMonth: _weekOfMonth,
                        monthOfYear: _monthOfYear,
                        byDayOfWeek: _byDayOfWeek,
                        onRecurringToggled: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        onFrequencyChanged: (value) {
                          setState(() {
                            _recurrenceFrequency = value;
                          });
                        },
                        onIntervalChanged: (value) {
                          setState(() {
                            _recurrenceInterval = value;
                          });
                        },
                        onDaysOfWeekChanged: (value) {
                          setState(() {
                            _daysOfWeek = value;
                          });
                        },
                        onEndDateChanged: (value) {
                          setState(() {
                            _recurrenceEndDate = value;
                          });
                        },
                        onMaxOccurrencesChanged: (value) {
                          setState(() {
                            _maxOccurrences = value;
                          });
                        },
                        onDayOfMonthChanged: (value) {
                          setState(() {
                            _dayOfMonth = value;
                          });
                        },
                        onWeekOfMonthChanged: (value) {
                          setState(() {
                            _weekOfMonth = value;
                          });
                        },
                        onMonthOfYearChanged: (value) {
                          setState(() {
                            _monthOfYear = value;
                          });
                        },
                        onByDayOfWeekChanged: (value) {
                          setState(() {
                            _byDayOfWeek = value;
                          });
                        },
                      ),
                    ).addGlassmorphism(
                      borderRadius: 12,
                      blur: GlassmorphismGuide.kCardBlur,
                      opacity: GlassmorphismGuide.kCardGlassOpacity,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Category
                    Text(
                      'Category',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          dropdownColor: AppColors.cardBackground,
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                          isExpanded: true,
                          items: _categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _category = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Visibility
                    Text(
                      'Visibility',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_visibilityOptions.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        value: entry.key,
                        groupValue: _visibility,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _visibility = value;
                            });
                          }
                        },
                        activeColor: AppColors.gold,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList()),
                    
                    const SizedBox(height: 20),
                    
                    // Tags
                    Text(
                      'Tags',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select tags to help people discover your event',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagOptions.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withOpacity(0.2)
                                  : AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? AppColors.gold : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
} 