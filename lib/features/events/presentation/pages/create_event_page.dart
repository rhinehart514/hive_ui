import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hive_ui/models/event_creation_request.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/events/presentation/providers/create_event_provider.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/huge_icons.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  late DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  late DateTime _endDate = DateTime.now().add(const Duration(hours: 3));
  String _category = 'Social';
  String _visibility = 'public';
  final List<String> _selectedTags = [];
  
  bool _showErrors = false;
  bool _isSubmitting = false;
  
  // Pre-defined event categories
  final List<String> _categories = [
    'Social',
    'Academic',
    'Sports',
    'Arts',
    'Career',
    'Service',
    'Cultural',
    'Greek Life',
    'Other',
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Date picker for start date
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.cardBackground,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: Colors.black,
                surface: AppColors.cardBackground,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: AppColors.cardBackground,
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          
          // If end date is now before start date, adjust it
          if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 2));
          }
        });
      }
    }
  }

  // Date picker for end date
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.cardBackground,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: Colors.black,
                surface: AppColors.cardBackground,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: AppColors.cardBackground,
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          
          // If end date is now before start date, adjust start date
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(hours: 2));
          }
        });
      }
    }
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

  // Create the event
  Future<void> _createEvent() async {
    try {
      // Validate form
      if (_formKey.currentState?.validate() != true) {
        setState(() => _showErrors = true);
        return;
      }

      if (_startDate.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start time must be in the future'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_startDate.isAfter(_endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start time must be before end time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be signed in to create an event');
      }

      // Log data for debugging
      debugPrint('Creating event for space: ${widget.selectedSpace.id} (${widget.selectedSpace.name})');
      debugPrint('Space type: ${widget.selectedSpace.spaceType}');
      
      // Create event request
      final eventRequest = EventCreationRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        organizerName: widget.selectedSpace.name,
        visibility: _visibility,
        tags: _selectedTags,
        isClubEvent: true,
        clubId: widget.selectedSpace.id,
      );

      // Validate request
      final validationError = eventRequest.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Create the event
      final event = Event.createClubEvent(
        title: eventRequest.title,
        description: eventRequest.description,
        location: eventRequest.location,
        startDate: eventRequest.startDate,
        endDate: eventRequest.endDate,
        clubId: widget.selectedSpace.id,
        clubName: widget.selectedSpace.name,
        creatorId: currentUser.uid,
        category: eventRequest.category,
        organizerEmail: currentUser.email ?? '',
        visibility: eventRequest.visibility,
        tags: eventRequest.tags,
        imageUrl: widget.selectedSpace.imageUrl ?? '',
      );

      // Get the space type for Firestore path
      final spaceType = widget.selectedSpace.spaceType.toString().split('.').last.toLowerCase();
      debugPrint('Using space type for Firestore path: $spaceType');
      
      // Validate space type - fallback to a default if there's an issue
      final validSpaceType = _isValidSpaceType(spaceType) ? spaceType : 'student_organizations';
      if (validSpaceType != spaceType) {
        debugPrint('WARNING: Invalid space type "$spaceType", using fallback: $validSpaceType');
      }
      
      try {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(validSpaceType)
            .collection('spaces')
            .doc(widget.selectedSpace.id)
            .collection('events')
            .doc(event.id)
            .set({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'location': event.location,
          'startDate': event.startDate.toIso8601String(),
          'endDate': event.endDate.toIso8601String(),
          'organizerEmail': event.organizerEmail,
          'organizerName': event.organizerName,
          'category': event.category,
          'status': event.status,
          'link': event.link,
          'imageUrl': event.imageUrl,
          'tags': event.tags,
          'source': 'club',
          'createdBy': event.createdBy,
          'lastModified': FieldValue.serverTimestamp(),
          'visibility': event.visibility,
          'attendees': event.attendees,
        });
        
        debugPrint('Event document created successfully');

        // Update space with event count
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(validSpaceType)
            .collection('spaces')
            .doc(widget.selectedSpace.id)
            .update({
          'eventCount': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Space document updated with event count');
      } catch (firestoreError) {
        debugPrint('Firestore error: $firestoreError');
        
        // Fallback to collection group query to find the space
        try {
          debugPrint('Attempting fallback with collection group query...');
          
          // Find the space using collection group query
          final spaceQuery = await FirebaseFirestore.instance
              .collectionGroup('spaces')
              .where('id', isEqualTo: widget.selectedSpace.id)
              .limit(1)
              .get();
              
          if (spaceQuery.docs.isEmpty) {
            throw Exception('Space not found after collection group query');
          }
          
          final spaceRef = spaceQuery.docs.first.reference;
          debugPrint('Found space at path: ${spaceRef.path}');
          
          // Create event in the space's events collection
          await spaceRef.collection('events').doc(event.id).set({
            'id': event.id,
            'title': event.title,
            'description': event.description,
            'location': event.location,
            'startDate': event.startDate.toIso8601String(),
            'endDate': event.endDate.toIso8601String(),
            'organizerEmail': event.organizerEmail,
            'organizerName': event.organizerName,
            'category': event.category,
            'status': event.status,
            'link': event.link,
            'imageUrl': event.imageUrl,
            'tags': event.tags,
            'source': 'club',
            'createdBy': event.createdBy,
            'lastModified': FieldValue.serverTimestamp(),
            'visibility': event.visibility,
            'attendees': event.attendees,
          });
          
          // Update event count
          await spaceRef.update({
            'eventCount': FieldValue.increment(1),
            'lastActivity': FieldValue.serverTimestamp(),
          });
          
          debugPrint('Successfully created event using fallback method');
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
          throw Exception('Error saving event (fallback also failed): $fallbackError');
        }
      }

      // Log analytics
      AnalyticsService.logEvent(
        'event_created',
        parameters: {
          'event_title': event.title,
          'space_id': widget.selectedSpace.id,
          'space_name': widget.selectedSpace.name,
          'event_category': event.category,
          'event_visibility': event.visibility,
        },
      );

      // Show success message and navigate back
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
                          // Space icon or image
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.black,
                              border: Border.all(
                                color: AppColors.gold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: widget.selectedSpace.imageUrl != null && 
                                   widget.selectedSpace.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.selectedSpace.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.groups,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
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
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
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
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
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
                        errorStyle: const TextStyle(
                          color: Colors.redAccent,
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date & Time',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectStartDate(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.inputBackground,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM d, yyyy h:mm a').format(_startDate),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date & Time',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectEndDate(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.inputBackground,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM d, yyyy h:mm a').format(_endDate),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Event category
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _category,
                          dropdownColor: AppColors.cardBackground,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _category = newValue;
                              });
                            }
                          },
                          items: _categories.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
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
                    Column(
                      children: _visibilityOptions.entries.map((entry) {
                        return RadioListTile<String>(
                          title: Text(
                            entry.value.split(' - ')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            entry.value.split(' - ')[1],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          value: entry.key,
                          groupValue: _visibility,
                          activeColor: AppColors.gold,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    
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
                    const SizedBox(height: 4),
                    Text(
                      'Select tags that describe your event',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: AppColors.gold.withOpacity(0.3),
                        ),
                        child: Text(
                          _isSubmitting ? 'Creating...' : 'Create Event',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
} 