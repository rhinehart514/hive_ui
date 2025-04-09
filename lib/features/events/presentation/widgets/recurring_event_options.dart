import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget for recurring event options
class RecurringEventOptions extends StatefulWidget {
  /// Whether the event is recurring
  final bool isRecurring;
  
  /// The recurrence frequency (daily, weekly, monthly, yearly)
  final String frequency;
  
  /// The interval for recurrence (e.g., every 2 weeks)
  final int interval;
  
  /// Selected days of week for weekly recurrence (0-6, Sunday-Saturday)
  final List<String> daysOfWeek;
  
  /// End date for the recurrence
  final DateTime? endDate;
  
  /// Maximum number of occurrences
  final int? maxOccurrences;
  
  /// Day of month for monthly recurrence (1-31)
  final int dayOfMonth;
  
  /// Week of month for monthly recurrence (1-5, where 5 means last week)
  final int weekOfMonth;
  
  /// Month of year for yearly recurrence (1-12)
  final int monthOfYear;
  
  /// Whether monthly recurrence is by day of week rather than day of month
  final bool byDayOfWeek;
  
  /// Callback when recurrence is toggled
  final Function(bool) onRecurringToggled;
  
  /// Callback when frequency is changed
  final Function(String) onFrequencyChanged;
  
  /// Callback when interval is changed
  final Function(int) onIntervalChanged;
  
  /// Callback when days of week are changed
  final Function(List<String>) onDaysOfWeekChanged;
  
  /// Callback when end date is changed
  final Function(DateTime?) onEndDateChanged;
  
  /// Callback when max occurrences is changed
  final Function(int?) onMaxOccurrencesChanged;
  
  /// Callback when day of month is changed
  final Function(int) onDayOfMonthChanged;
  
  /// Callback when week of month is changed
  final Function(int) onWeekOfMonthChanged;
  
  /// Callback when month of year is changed
  final Function(int) onMonthOfYearChanged;
  
  /// Callback when by day of week is toggled
  final Function(bool) onByDayOfWeekChanged;

  /// Constructor
  const RecurringEventOptions({
    Key? key,
    required this.isRecurring,
    required this.frequency,
    required this.interval,
    required this.daysOfWeek,
    required this.endDate,
    required this.maxOccurrences,
    required this.dayOfMonth,
    required this.weekOfMonth,
    required this.monthOfYear,
    required this.byDayOfWeek,
    required this.onRecurringToggled,
    required this.onFrequencyChanged,
    required this.onIntervalChanged,
    required this.onDaysOfWeekChanged,
    required this.onEndDateChanged,
    required this.onMaxOccurrencesChanged,
    required this.onDayOfMonthChanged,
    required this.onWeekOfMonthChanged,
    required this.onMonthOfYearChanged,
    required this.onByDayOfWeekChanged,
  }) : super(key: key);

  @override
  State<RecurringEventOptions> createState() => _RecurringEventOptionsState();
}

class _RecurringEventOptionsState extends State<RecurringEventOptions> {
  final TextEditingController _maxOccurrencesController = TextEditingController();
  final List<String> _weekdayOptions = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _frequencyOptions = ['daily', 'weekly', 'monthly', 'yearly'];
  final List<String> _weekNumbers = ['First', 'Second', 'Third', 'Fourth', 'Last'];
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  String _endType = 'never'; // 'never', 'on_date', 'after_occurrences'
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the end type based on provided values
    if (widget.maxOccurrences != null) {
      _endType = 'after_occurrences';
      _maxOccurrencesController.text = widget.maxOccurrences.toString();
    } else if (widget.endDate != null) {
      _endType = 'on_date';
    } else {
      _endType = 'never';
    }
  }

  @override
  void dispose() {
    _maxOccurrencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recurring event toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recurring Event',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Switch(
              value: widget.isRecurring,
              onChanged: widget.onRecurringToggled,
              activeColor: AppColors.gold,
            ),
          ],
        ),
        
        if (widget.isRecurring) ...[
          const SizedBox(height: 16),
          
          // Recurrence frequency
          const Text(
            'Frequency',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
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
                value: widget.frequency,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
                isExpanded: true,
                items: _frequencyOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value.substring(0, 1).toUpperCase() + value.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    widget.onFrequencyChanged(newValue);
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Interval
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Repeat every',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.interval,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    items: List.generate(10, (index) => index + 1).map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        widget.onIntervalChanged(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.interval > 1 
                      ? '${widget.frequency.substring(0, 1).toUpperCase() + widget.frequency.substring(1, widget.frequency.length - 1)}s'
                      : widget.frequency.substring(0, 1).toUpperCase() + widget.frequency.substring(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Specific recurrence options based on frequency
          if (widget.frequency == 'weekly') ...[
            const Text(
              'On which days',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekdayOptions.map((day) {
                final isSelected = widget.daysOfWeek.contains(day);
                return GestureDetector(
                  onTap: () {
                    final updatedDays = List<String>.from(widget.daysOfWeek);
                    if (isSelected) {
                      updatedDays.remove(day);
                    } else {
                      updatedDays.add(day);
                    }
                    widget.onDaysOfWeekChanged(updatedDays);
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
                      day,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else if (widget.frequency == 'monthly') ...[
            const Text(
              'Monthly options',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: widget.byDayOfWeek,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onByDayOfWeekChanged(value);
                    }
                  },
                  activeColor: AppColors.gold,
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Day ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: widget.dayOfMonth,
                            dropdownColor: AppColors.cardBackground,
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white,
                            items: List.generate(31, (index) => index + 1).map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: widget.byDayOfWeek ? null : (newValue) {
                              if (newValue != null) {
                                widget.onDayOfMonthChanged(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      const Text(
                        ' of month',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: widget.byDayOfWeek,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onByDayOfWeekChanged(value);
                    }
                  },
                  activeColor: AppColors.gold,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: widget.weekOfMonth,
                            dropdownColor: AppColors.cardBackground,
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white,
                            items: List.generate(5, (index) => index).map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(_weekNumbers[value]),
                              );
                            }).toList(),
                            onChanged: !widget.byDayOfWeek ? null : (newValue) {
                              if (newValue != null) {
                                widget.onWeekOfMonthChanged(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.daysOfWeek.isNotEmpty ? widget.daysOfWeek.first : 'Mon',
                            dropdownColor: AppColors.cardBackground,
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white,
                            items: _weekdayOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: !widget.byDayOfWeek ? null : (newValue) {
                              if (newValue != null) {
                                final updatedDays = [newValue];
                                widget.onDaysOfWeekChanged(updatedDays);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (widget.frequency == 'yearly') ...[
            const Text(
              'Yearly options',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: widget.monthOfYear,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white,
                      items: List.generate(12, (index) => index + 1).map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(_monthNames[value - 1]),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          widget.onMonthOfYearChanged(newValue);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: widget.dayOfMonth,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white,
                      items: List.generate(31, (index) => index + 1).map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          widget.onDayOfMonthChanged(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // End options
          const Text(
            'Ends',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          // Never end option
          RadioListTile<String>(
            title: const Text(
              'Never',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            value: 'never',
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _endType = value;
                });
                widget.onEndDateChanged(null);
                widget.onMaxOccurrencesChanged(null);
              }
            },
            activeColor: AppColors.gold,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          
          // End on date option
          RadioListTile<String>(
            title: Row(
              children: [
                const Text(
                  'On date: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _endType == 'on_date' 
                        ? () async {
                            final initialDate = widget.endDate ?? DateTime.now().add(const Duration(days: 30));
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    primaryColor: AppColors.gold,
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
                              setState(() {
                                _endType = 'on_date';
                              });
                              widget.onEndDateChanged(pickedDate);
                              widget.onMaxOccurrencesChanged(null);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _endType == 'on_date' 
                            ? AppColors.inputBackground 
                            : AppColors.inputBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.endDate != null
                            ? DateFormat('MMM d, yyyy').format(widget.endDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _endType == 'on_date' 
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            value: 'on_date',
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _endType = value;
                });
                // If no end date is set yet, set it to 30 days from now
                widget.onEndDateChanged(widget.endDate ?? DateTime.now().add(const Duration(days: 30)));
                widget.onMaxOccurrencesChanged(null);
              }
            },
            activeColor: AppColors.gold,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          
          // End after occurrences option
          RadioListTile<String>(
            title: Row(
              children: [
                const Text(
                  'After ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _maxOccurrencesController,
                    enabled: _endType == 'after_occurrences',
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: _endType == 'after_occurrences' 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                    decoration: InputDecoration(
                      fillColor: _endType == 'after_occurrences' 
                          ? AppColors.inputBackground 
                          : AppColors.inputBackground.withOpacity(0.5),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (_endType == 'after_occurrences') {
                        final occurrences = int.tryParse(value);
                        if (occurrences != null && occurrences > 0) {
                          widget.onMaxOccurrencesChanged(occurrences);
                          widget.onEndDateChanged(null);
                        }
                      }
                    },
                  ),
                ),
                const Text(
                  ' occurrences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            value: 'after_occurrences',
            groupValue: _endType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _endType = value;
                });
                final occurrences = int.tryParse(_maxOccurrencesController.text);
                if (occurrences != null && occurrences > 0) {
                  widget.onMaxOccurrencesChanged(occurrences);
                } else {
                  widget.onMaxOccurrencesChanged(10); // Default to 10 occurrences
                  _maxOccurrencesController.text = '10';
                }
                widget.onEndDateChanged(null);
              }
            },
            activeColor: AppColors.gold,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }
} 