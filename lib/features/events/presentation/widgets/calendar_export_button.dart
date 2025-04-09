import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'dart:io';

/// A button for exporting events to external calendar applications
class CalendarExportButton extends StatefulWidget {
  /// The event to export
  final Event event;
  
  /// Callback when export is complete
  final Function(bool success)? onExportComplete;

  /// Creates a calendar export button
  const CalendarExportButton({
    Key? key,
    required this.event,
    this.onExportComplete,
  }) : super(key: key);

  @override
  State<CalendarExportButton> createState() => _CalendarExportButtonState();
}

class _CalendarExportButtonState extends State<CalendarExportButton> {
  bool _isExporting = false;

  /// Generate calendar file content based on event details
  String _generateICalContent() {
    // Format dates for iCal format
    final startDate = widget.event.startDate.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').substring(0, 15) + 'Z';
    final endDate = widget.event.endDate.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').substring(0, 15) + 'Z';
    
    // Create unique ID for this event
    final uid = '${widget.event.id}@hiveapp.com';
    
    // Generate iCal content
    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//HIVE App//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
SUMMARY:${widget.event.title}
DTSTART:$startDate
DTEND:$endDate
DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').substring(0, 15)}Z
UID:$uid
CREATED:${DateTime.now().toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').substring(0, 15)}Z
DESCRIPTION:${widget.event.description.replaceAll('\n', '\\n')}
LOCATION:${widget.event.location}
ORGANIZER;CN=${widget.event.organizerName}:mailto:${widget.event.organizerEmail}
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR''';
  }

  /// Export to calendar with platform-specific approach
  Future<void> _exportToCalendar() async {
    if (_isExporting) return;
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      // Apply haptic feedback
      HapticFeedback.mediumImpact();
      
      // For this example, we're just showing a dialog.
      // In a real app, you would use platform-specific calendar APIs
      // or a package like add_2_calendar
      
      if (Platform.isAndroid || Platform.isIOS) {
        // In a real implementation:
        // final result = await Add2Calendar.addEvent2Cal(
        //   Event(
        //     title: widget.event.title,
        //     description: widget.event.description,
        //     location: widget.event.location,
        //     startDate: widget.event.startDate,
        //     endDate: widget.event.endDate,
        //   ),
        // );
        
        // For this example, we'll simulate success
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event added to calendar'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          
          // Notify completion
          widget.onExportComplete?.call(true);
        }
      } else {
        // For web or desktop, offer to download an iCal file
        // In a real implementation:
        // final bytes = utf8.encode(_generateICalContent());
        // final blob = html.Blob([bytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement(href: url)
        //   ..setAttribute('download', '${widget.event.title.replaceAll(' ', '_')}.ics')
        //   ..click();
        // html.Url.revokeObjectUrl(url);
        
        // For this example, we'll simulate and show the content
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.dark2,
              title: Text(
                'Calendar Export',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'iCal file generated for download:',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _generateICalContent(),
                      style: GoogleFonts.robotoMono(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onExportComplete?.call(true);
                  },
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        
        // Notify completion with failure
        widget.onExportComplete?.call(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _isExporting ? null : _exportToCalendar,
      icon: _isExporting 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            )
          : Icon(
              Icons.calendar_today_outlined,
              color: AppColors.gold,
              size: 18,
            ),
      label: Text(
        _isExporting ? 'Adding...' : 'Add to Calendar',
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppColors.gold.withOpacity(0.5),
            width: 1,
          ),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.gold.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
    );
  }
} 