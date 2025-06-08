import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A location type enum with support for physical or virtual locations
enum LocationType {
  /// Physical location (address, building, etc.)
  physical,
  
  /// Virtual location (Zoom, Google Meet, etc.)
  virtual,
}

/// A location picker widget that handles both physical and virtual locations
class LocationPicker extends StatefulWidget {
  /// Initial location value
  final String initialLocation;
  
  /// Callback when the location changes
  final Function(String, LocationType) onLocationChanged;
  
  /// Whether the field is read-only
  final bool readOnly;
  
  /// Initial location type
  final LocationType initialLocationType;

  /// Creates a location picker
  const LocationPicker({
    Key? key,
    this.initialLocation = '',
    required this.onLocationChanged,
    this.readOnly = false,
    this.initialLocationType = LocationType.physical,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late TextEditingController _locationController;
  late LocationType _locationType;
  bool _isValidLocation = true;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
    _locationType = widget.initialLocationType;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  /// Validates the location input based on the location type
  bool _validateLocation(String value) {
    // No need to validate empty locations - that's handled by the form validator
    if (value.isEmpty) return true;
    
    if (_locationType == LocationType.virtual) {
      // Check if it appears to be a video conferencing link
      return value.contains('zoom.') || 
             value.contains('meet.google.') || 
             value.contains('teams.') ||
             value.contains('http') || 
             value.contains('webex.');
    } else {
      // For physical location, just make sure it's not too short
      return value.length >= 3;
    }
  }

  /// Handle location type change
  void _handleLocationTypeChange(LocationType? newType) {
    if (newType == null) return;
    
    HapticFeedback.selectionClick();
    
    // Only if the type actually changed
    if (_locationType != newType) {
      setState(() {
        _locationType = newType;
        // Revalidate current value with new type
        _isValidLocation = _validateLocation(_locationController.text);
      });
      
      // Notify parent
      widget.onLocationChanged(_locationController.text, _locationType);
    }
  }

  /// Handle location text change
  void _handleLocationChange(String value) {
    setState(() {
      _isValidLocation = _validateLocation(value);
    });
    
    // Notify parent
    widget.onLocationChanged(value, _locationType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Type Toggle
        if (!widget.readOnly) ...[
          Text(
            'Location Type',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<LocationType>(
            segments: const [
              ButtonSegment<LocationType>(
                value: LocationType.physical,
                label: Text('Physical'),
                icon: Icon(Icons.location_on_outlined),
              ),
              ButtonSegment<LocationType>(
                value: LocationType.virtual,
                label: Text('Virtual'),
                icon: Icon(Icons.videocam_outlined),
              ),
            ],
            selected: {_locationType},
            onSelectionChanged: (Set<LocationType> newSelection) {
              _handleLocationTypeChange(newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppColors.dark3;
                  }
                  return AppColors.dark;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppColors.gold;
                  }
                  return AppColors.textPrimary;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Location Input Field
        Text(
          _locationType == LocationType.physical ? 'Address' : 'Meeting Link',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          readOnly: widget.readOnly,
          onChanged: _handleLocationChange,
          decoration: InputDecoration(
            hintText: _locationType == LocationType.physical
                ? 'Enter address or building'
                : 'Enter Zoom, Google Meet, etc. link',
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.dark2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValidLocation ? AppColors.gold : AppColors.error,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              _locationType == LocationType.physical
                  ? Icons.location_on_outlined
                  : Icons.videocam_outlined,
              color: AppColors.grey,
            ),
            suffixIcon: _locationController.text.isNotEmpty && !widget.readOnly
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _locationController.clear();
                        _isValidLocation = true;
                      });
                      widget.onLocationChanged('', _locationType);
                    },
                    color: AppColors.grey,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            
            if (!_validateLocation(value)) {
              return _locationType == LocationType.virtual
                  ? 'Please enter a valid meeting link'
                  : 'Please enter a valid address';
            }
            
            return null;
          },
        ),
        // Format hint
        if (!widget.readOnly && _locationType == LocationType.virtual) ...[
          const SizedBox(height: 8),
          Text(
            'Include the full URL (e.g., https://zoom.us/j/...)',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        // Validation error
        if (!_isValidLocation && !widget.readOnly) ...[
          const SizedBox(height: 8),
          Text(
            _locationType == LocationType.virtual
                ? 'Please enter a valid meeting link'
                : 'Please enter a valid address',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
} 